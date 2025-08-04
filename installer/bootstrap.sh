#!/usr/bin/env bash

# SwiftJsonUI Bootstrap Script
# This lightweight script downloads the installer and runs it
#
# Usage examples:
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -v 7.0.0-alpha
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -m swiftui
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -v 7.0.0-alpha -m swiftui

set -e

# Configuration
GITHUB_REPO="Tai-Kimura/SwiftJsonUI"
INSTALLER_PATH="installer/install_sjui.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments (pass them to the installer)
ARGS="$@"

# Default to master branch if no version specified
VERSION="master"

# Parse arguments to extract version
# Use a separate array to avoid modifying the original arguments
set -- "$@"
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

print_info "SwiftJsonUI Bootstrap"
print_info "Downloading installer from branch/tag: $VERSION"

# Download the installer script
INSTALLER_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$VERSION/$INSTALLER_PATH"
TEMP_INSTALLER=$(mktemp)

if ! curl -L -f -o "$TEMP_INSTALLER" "$INSTALLER_URL"; then
    print_error "Failed to download installer from $INSTALLER_URL"
    print_error "Please check if the version/branch '$VERSION' exists."
    rm -f "$TEMP_INSTALLER"
    exit 1
fi

# Make it executable
chmod +x "$TEMP_INSTALLER"

# Run the installer with all arguments
print_info "Running installer..."
"$TEMP_INSTALLER" $ARGS

# Cleanup
rm -f "$TEMP_INSTALLER"