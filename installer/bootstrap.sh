#!/usr/bin/env bash

# SwiftJsonUI Bootstrap Script
# This lightweight script downloads the installer and runs it

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

# Default to main branch if no version specified
VERSION="main"

# Parse arguments to extract version
for i in "$@"; do
    case $i in
        -v|--version)
            shift
            VERSION="$1"
            break
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