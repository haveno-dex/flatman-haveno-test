#!/bin/bash

# Set GNUPGHOME to the desired directory
export GNUPGHOME=./.gpg

# Create the GNUPGHOME directory if it doesn't exist
mkdir -p "$GNUPGHOME"

# Create the key generation configuration file
cat <<EOF > gen-key.conf
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: Your Name
Name-Email: your.email@example.com
Expire-Date: 0
Passphrase: 1234
EOF

# Generate the key
gpg --batch --gen-key gen-key.conf

# Print the key ID with color
KEY_ID=$(gpg --list-keys --with-colons | awk -F: '/^pub:/ {print $5}')
# Print a base64 --wrap=0 encoded version of the public key
KEY_BASE64=$(gpg --export $KEY_ID | base64 --wrap=0)
echo -e "Generated Key ID: \033[1;32m$KEY_ID\033[0m" # Green color for the key ID
echo -e "Generated Key Base64: \033[1;32m$KEY_BASE64\033[0m" # Green color for the key ID

# Clean up
rm gen-key.conf
