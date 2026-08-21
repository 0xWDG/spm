#!/bin/zsh

set -euo pipefail

install_prefix="${SPM_INSTALL_PREFIX:-/usr/local}"
install_directory="${install_prefix%/}/bin"
destination="${install_directory}/spm"

echo "Building spm in release mode..."
swift build -c release --product spm

binary_directory="$(swift build -c release --show-bin-path)"

echo "Installing spm at ${destination}..."
if mkdir -p "${install_directory}" 2>/dev/null && [[ -w "${install_directory}" ]]; then
    install -m 755 "${binary_directory}/spm" "${destination}"
else
    echo "Administrator privileges are required to install under ${install_prefix}."
    sudo install -d "${install_directory}"
    sudo install -m 755 "${binary_directory}/spm" "${destination}"
fi

echo "spm installed successfully at ${destination}"
if [[ ":${PATH}:" != *":${install_directory}:"* ]]; then
    echo "Add ${install_directory} to PATH to run spm from any directory."
fi
