#!/bin/zsh

echo "Building and installing spm..."
swift run spm build

echo "Installing spm... [sudo privileges may be required]"
# Install the spm binary to /usr/local/bin
sudo cp -f .build/debug/spm /usr/local/bin/spm

# Check if the installation was successful
if [ $? -eq 0 ]; then
    echo "spm installed successfully to /usr/local/bin/spm"
else
    echo "Failed to install spm. Please check for errors."
fi