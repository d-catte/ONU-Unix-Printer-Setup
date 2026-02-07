#!/bin/bash

# Ensure root privileges
if [ $UID != 0 ]; then
    echo "Please run this script as root." 1>&2
    exit 1
fi

# Make sure smbclient, lpadmin, and curl are installed
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found! Please install curl to continue." 1>&2
    exit 2
elif ! command -v smbclient >/dev/null 2>&1; then
    echo "smbclient not found! Please install smbclient to continue." 1>&2
    exit 2
elif ! command -v lpadmin >/dev/null 2>&1; then
    echo "lpadmin not found! Please install and enable CUPS to continue." 1>&2
    exit 2
fi

# Prompt for ONU credentials
read -p "Enter ONU username: " ONU_USERNAME
read -s -p "Enter ONU password: " ONU_PASSWORD
printf "\n\n"

# Create credentials file
CREDS_FILE="/etc/cups/onu.creds"
echo "Creating credentials file at $CREDS_FILE..."
cat > $CREDS_FILE <<EOF
username=$ONU_USERNAME
password=$ONU_PASSWORD
domain=onu
EOF
chmod 600 $CREDS_FILE

# Create CUPS backend
if [ -d "/usr/libexec/cups/backend" ]; then
    BACKEND_FILE="/usr/libexec/cups/backend/onusmb"
elif [ -d "/usr/lib/cups/backend" ]; then
    BACKEND_FILE="/usr/lib/cups/backend/onusmb"
elif [ -d "$1" ]; then
    BACKEND_FILE="$1/onusmb"
else
    if [ -n "$1" ]; then
        echo "$1 is not a valid directory."
    else
        echo "Unable to find CUPS backend directory. Make sure CUPS is installed, or you can optionally specify a custom directory as an argument to this script." 1>&2
    fi
    exit 3
fi
echo -e "Creating CUPS backend at $BACKEND_FILE...\n"
cat > "$BACKEND_FILE" <<'EOF'
#!/bin/bash

CREDS="/etc/cups/onu.creds"
SHARE="//onuprinters.onu.edu/black-and-white"
LOG="/tmp/onusmb_debug.log"

if [ $# -eq 0 ]; then
    echo "network onusmb \"Unknown\" \"ONU SMB Printer\""
    exit 0
fi

JOB_ID="$1"
FILE="$6"

if [ -z "$FILE" ]; then
    smbclient "$SHARE" -A "$CREDS" -c "put - job-$JOB_ID.ps" >> $LOG 2>&1
else
    smbclient "$SHARE" -A "$CREDS" -c "print \"$FILE\"" >> $LOG 2>&1
fi

exit $?
EOF
chmod 700 "$BACKEND_FILE"

# Download and extract Konica Minolta PPD driver
OS=$(uname -s)
if [ "$OS" == "Linux" ]; then
    curl -Ls -o /tmp/km.zip -e "https://onyxweb.mykonicaminolta.com/OneStopProductSupport?appMode=internal" "https://cscsupportftp.mykonicaminolta.com/DownloadFile/Download.ashx?fileversionid=6500&productid=1610"
elif [ "$OS" == "Darwin" ]; then
    curl -Ls -o /tmp/km.zip -e "https://onyxweb.mykonicaminolta.com/OneStopProductSupport?appMode=internal" "https://cscsupportftp.mykonicaminolta.com/DownloadFile/Download.ashx?fileversionid=32702&productid=1610"
fi
mkdir -p /tmp/km
unzip -q /tmp/km.zip -d /tmp/km
if [ "$OS" == "Linux" ]; then
    PPD_FILE="/tmp/km/Linux/CUPS1.2/EN/KOC364UX.ppd"
elif [ "$OS" == "Darwin" ]; then
    # Navigate the labyrinth that is the mscOS .pkg format
    xar -C /tmp/km/C554_C364_Series_v5.10.0A_Letter -xf /tmp/km/C554_C364_Series_v5.10.0A_Letter/bizhub_C554_C364_11.pkg
    mv /tmp/km/C554_C364_Series_v5.10.0A_Letter/pkg-contents.pkg/Payload /tmp/km/C554_C364_Series_v5.10.0A_Letter/pkg-contents.pkg/Payload.gz
    gzip -d /tmp/km/C554_C364_Series_v5.10.0A_Letter/pkg-contents.pkg/Payload
    (cd /tmp/km && cpio --quiet -id < /tmp/km/C554_C364_Series_v5.10.0A_Letter/pkg-contents.pkg/Payload "./Printers/PPDs/Contents/Resources/KONICAMINOLTAC364e.gz")
    gzip -d /tmp/km/Printers/PPDs/Contents/Resources/KONICAMINOLTAC364e
    PPD_FILE="/tmp/km/Printers/PPDs/Contents/Resources/KONICAMINOLTAC364e"
fi
if [ ! -f "$PPD_FILE" ]; then
    echo "Konica Minolta PPD driver not found!" 1>&2
    exit 4
fi

# Add printer
lpadmin -p ONU_printing \
  -v onusmb:/ \
  -P "$PPD_FILE" \
  -o Finisher=FS-534 \
  -o printer-is-shared=false \
  -E
echo "Printer ONU_printing added."

# Delete temp dir
rm -rf /tmp/km.zip /tmp/km

echo "ONU printing successfully enabled! Printing a test page..."
lp -d ONU_printing /usr/share/cups/data/testprint
echo "To confirm the status of the test print, please go to https://onuprinters.onu.edu:9192/user and view the \"Jobs Pending Release\" page. Then the print job can be deleted."
