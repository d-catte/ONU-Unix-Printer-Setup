# ONU Unix Printer Setup Installation Script
This script automates the installation of the proper Postscript files for the ONU printers on Linux, FreeBSD, and macOS systems.
It configures CUPS to automatically send the print files to ONU's samba print servers.
Additionally, it unifies both the black-and-white and color prints into a single instance.

### Usage
Simply download the script and run `sudo ./install-onu-printers.sh`. Follow the prompts in the console to enter your ONU information

### Default Print Settings
- Page Size: Letter (8.5in x 11in)
- Print Style: Double-sided
- Color: Color
- Pages to Print: All Pages

### Accessing Print Settings (Linux)
1. Open the System Dialog for printing
<img width="355" height="631" alt="image" src="https://github.com/user-attachments/assets/5d1fada7-d78c-433c-8949-f054d7d032a9" />

2. Select `ONU_printing` from the list of printers
<img width="584" height="534" alt="image" src="https://github.com/user-attachments/assets/b5cf94e7-ca90-46f4-b7bc-a34fffef01b3" />

3. To change the paper size(blue), type(green), and to specify what pages to print(yellow), go to the `Page Setup` tab
<img width="584" height="534" alt="image" src="https://github.com/user-attachments/assets/0fd7e95d-935a-483c-b8b0-3ebf1757af61" />

4. To swap between single-sided and dual sided printing (blue), and swap between color and B&W (green), go to the `Advanced` tab
<img width="584" height="1225" alt="image" src="https://github.com/user-attachments/assets/34d059e8-db16-4224-bb97-2e9edee78e45" />

5. Finally, press `Print` on any page to print with the configured settings. These settings are not saved and must be configured for each print!
<img width="584" height="534" alt="image" src="https://github.com/user-attachments/assets/0c525fcd-5c76-44e6-b4d9-8ebdf6917cb6" />
