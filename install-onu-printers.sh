#!/bin/bash
# Script to automate ONU printer setup on Linux

set -e

# Get the current user
USER_NAME=$(whoami)
echo "Detected user: $USER_NAME"

# Prompt for ONU credentials
read -p "Enter ONU username: " ONU_USERNAME
read -s -p "Enter ONU password: " ONU_PASSWORD
echo

# Step 1 & 2: Create the credentials file
CRED_FILE="/etc/cups/onu.creds"
echo "Creating credentials file at $CRED_FILE..."
sudo bash -c "cat > $CRED_FILE <<EOF
username=$ONU_USERNAME
password=$ONU_PASSWORD
domain=onu
EOF"

# Step 3: Set secure permissions
sudo chmod 600 $CRED_FILE
echo "Set permissions to 600 for $CRED_FILE"

# Step 4: Create the backend script
BACKEND_FILE="/usr/lib/cups/backend/onusmb"
echo "Creating CUPS backend at $BACKEND_FILE..."
sudo bash -c "cat > $BACKEND_FILE <<'EOF'
#!/bin/bash

SMBCLIENT=\"/usr/bin/smbclient\"
CREDS=\"/etc/cups/onu.creds\"
SHARE=\"//onuprinters.onu.edu/black-and-white\"
LOG=\"/tmp/onusmb_debug.log\"

if [ \$# -eq 0 ]; then
    echo \"network onusmb \\\"Unknown\\\" \\\"ONU SMB Printer\\\"\"
    exit 0
fi

JOB_ID=\"\$1\"
FILE=\"\$6\"

if [ -z \"\$FILE\" ]; then
    \$SMBCLIENT \"\$SHARE\" -A \"\$CREDS\" -c \"put - job-\$JOB_ID.ps\" >> \$LOG 2>&1
else
    \$SMBCLIENT \"\$SHARE\" -A \"\$CREDS\" -c \"print \\\"\$FILE\\\"\" >> \$LOG 2>&1
fi

exit \$?
EOF"

# Step 6 & 7: Set ownership and permissions
sudo chown root:root $BACKEND_FILE
sudo chmod 700 $BACKEND_FILE
echo "Set ownership to root and permissions to 700 for $BACKEND_FILE"

# Step 8: Download and extract driver
DRIVER_URL="https://cscsupportftp.mykonicaminolta.com/DownloadFile/Download.ashx?fileversionid=6500&productid=1610"
TEMP_DIR=$(mktemp -d)
ZIP_FILE="$TEMP_DIR/driver.zip"

echo "Downloading printer driver..."
wget -O "$ZIP_FILE" "$DRIVER_URL"

echo "Extracting driver..."
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# Find the PPD file
PPD_PATH=$(find "$TEMP_DIR" -type f -path "*/CUPS1.2/EN/KOC364UX.ppd" | head -n1)
if [ -z "$PPD_PATH" ]; then
    echo "Error: PPD file not found!"
    exit 1
fi
echo "Found PPD at $PPD_PATH"

# Step 9: Add the printer
sudo lpadmin -p ONU_Printer \
    -v onusmb:/ \
    -P "$PPD_PATH" \
    -o Finisher=FS-534 \
    -o printer-is-shared=false \
    -E
echo "Printer ONU_Printer added."

# Step 10: Restart CUPS
sudo systemctl restart cups
echo "CUPS restarted. Setup complete!"

# Cleanup
rm -rf "$TEMP_DIR"
