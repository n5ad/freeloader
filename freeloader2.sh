#!/bin/bash
# ================================================
# Freeloader Installer for Supermon
# Pulls from https://github.com/n5ad/freeloader
# Created by N5AD - June 2026
# ================================================

set -e

echo "=================================================="
echo "🚀 Starting Freeloader Installer"
echo "=================================================="

# STEP 1-3: Update + Git + Clone
echo "Step 1: Updating package list..."
apt-get update -qq

echo "Step 2: Installing git if needed..."
apt-get install -y git

echo "Step 3: Getting latest files from n5ad/freeloader..."
if [ -d "/tmp/freeloader" ]; then
    cd /tmp/freeloader && git pull
else
    git clone https://github.com/n5ad/freeloader.git /tmp/freeloader
fi

# STEP 4: /my_uploads
echo "Step 4: Creating /my_uploads directory"
sudo mkdir -p /my_uploads
UPLOAD_USER="${SUDO_USER:-$(whoami)}"
if ! id -nG "$UPLOAD_USER" | grep -qw "www-data"; then
    sudo usermod -aG www-data "$UPLOAD_USER"
fi
sudo chown -R www-data:www-data /my_uploads
sudo chmod -R 2775 /my_uploads
echo "✅ /my_uploads ready"

# STEP 5-7: Folders and files
echo "Step 5: Creating freeloader subdirectory"
sudo mkdir -p /var/www/html/supermon/custom/freeloader
sudo chown -R www-data:www-data /var/www/html/supermon/custom/freeloader

echo "Step 6: Installing freeloader.inc"
sudo cp /tmp/freeloader/freeloader.inc /var/www/html/supermon/custom/
sudo chown www-data:www-data /var/www/html/supermon/custom/freeloader.inc
sudo chmod 644 /var/www/html/supermon/custom/freeloader.inc

echo "Step 7: Installing PHP backend files"
sudo cp /tmp/freeloader/freeloader_upload.php /var/www/html/supermon/custom/freeloader/
sudo cp /tmp/freeloader/freeloader_delete.php /var/www/html/supermon/custom/freeloader/
sudo chown www-data:www-data /var/www/html/supermon/custom/freeloader/*.php
sudo chmod 644 /var/www/html/supermon/custom/freeloader/*.php

# ====================== NEW STEP 8 ======================
FOOTER_FILE="/var/www/html/supermon/footer.inc"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$FOOTER_FILE" ]; then
    echo "ERROR: $FOOTER_FILE not found!"
    exit 1
fi

# Check if the include already exists
if grep -qF '<?php include_once "custom/freeloader.inc"; ?>' "$FOOTER_FILE"; then
    echo "freeloader.inc include already exists. Skipping."
else
    BACKUP_FILE="${FOOTER_FILE}${BACKUP_SUFFIX}"
    cp -v "$FOOTER_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"

    awk '
    /<br><br>[[:space:]]*$/ {
        print
        if (getline > 0) {
            if ($0 ~ /^[[:space:]]*<SCRIPT>/) {
                print "<?php include_once \"custom/freeloader.inc\"; ?>"
            }
            print
        }
        next
    }
    { print }
    ' "$BACKUP_FILE" > "$FOOTER_FILE"

    echo "Inserted freeloader.inc include into footer.inc"
fi

    chown www-data:www-data "$FOOTER_INC" 2>/dev/null || true
    chmod 644 "$FOOTER_INC" 2>/dev/null || true
fi

echo ""
echo "=================================================="
echo "✅ Freeloader installation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Hard refresh Supermon (Ctrl + Shift + R)"
echo "2. Confirm Freeloader appears before the JavaScript section"
echo "3. Test uploading a file"
echo ""
echo "Installer location: /etc/asterisk/local/freeloader.sh"
echo "=================================================="
