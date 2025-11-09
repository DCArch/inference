#!/bin/bash
# Check if rclone is installed

if ! command -v rclone &> /dev/null; then
    echo ""
    echo "ERROR: rclone is not installed."
    echo ""
    echo "Please install rclone using one of the following commands:"
    echo ""
    echo "Official installer:"
    echo "  curl https://rclone.org/install.sh | sudo bash"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt install rclone"
    echo ""
    echo "CentOS/RHEL:"
    echo "  sudo dnf install rclone"
    echo ""
    exit 1
fi

exit 0
