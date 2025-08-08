#!/usr/bin/env bash

# SwiftJsonUI Bootstrap Script
# This script downloads the installer and runs it with automatic Ruby setup
#
# Usage examples:
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -v 7.0.0
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -d ./my-project
#   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -v 7.0.0 -s

set -e

# Configuration
GITHUB_REPO="Tai-Kimura/SwiftJsonUI"
INSTALLER_PATH="installer/install_sjui.sh"
REQUIRED_RUBY_VERSION="3.2.2"
MINIMUM_RUBY_VERSION="2.7.0"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to compare version numbers
version_compare() {
    printf '%s\n%s' "$1" "$2" | sort -V | head -n1
}

# Check and setup Ruby environment
setup_ruby_environment() {
    print_info "Checking Ruby environment..."
    
    # Check if rbenv is installed and set up
    if command -v rbenv &> /dev/null; then
        print_info "Found rbenv"
        eval "$(rbenv init -)" 2>/dev/null || true
        
        # Check current Ruby version
        if command -v ruby &> /dev/null; then
            CURRENT_RUBY=$(ruby -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            if [ "$(version_compare "$CURRENT_RUBY" "$MINIMUM_RUBY_VERSION")" = "$MINIMUM_RUBY_VERSION" ]; then
                print_info "Ruby $CURRENT_RUBY is compatible"
                return 0
            fi
        fi
        
        # Install Ruby if needed
        print_info "Installing Ruby $REQUIRED_RUBY_VERSION with rbenv..."
        if rbenv install -s "$REQUIRED_RUBY_VERSION"; then
            rbenv global "$REQUIRED_RUBY_VERSION"
            eval "$(rbenv init -)"
            print_info "Ruby $REQUIRED_RUBY_VERSION installed and activated"
        fi
        
    # Check if rvm is installed
    elif [ -s "$HOME/.rvm/scripts/rvm" ] || command -v rvm &> /dev/null; then
        print_info "Found rvm"
        [ -s "$HOME/.rvm/scripts/rvm" ] && source "$HOME/.rvm/scripts/rvm"
        
        # Check current Ruby version
        if command -v ruby &> /dev/null; then
            CURRENT_RUBY=$(ruby -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            if [ "$(version_compare "$CURRENT_RUBY" "$MINIMUM_RUBY_VERSION")" = "$MINIMUM_RUBY_VERSION" ]; then
                print_info "Ruby $CURRENT_RUBY is compatible"
                return 0
            fi
        fi
        
        # Install Ruby if needed
        print_info "Installing Ruby $REQUIRED_RUBY_VERSION with rvm..."
        if rvm install "$REQUIRED_RUBY_VERSION"; then
            rvm use "$REQUIRED_RUBY_VERSION" --default
            print_info "Ruby $REQUIRED_RUBY_VERSION installed and activated"
        fi
        
    # Check system Ruby
    elif command -v ruby &> /dev/null; then
        CURRENT_RUBY=$(ruby -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ "$(version_compare "$CURRENT_RUBY" "$MINIMUM_RUBY_VERSION")" = "$MINIMUM_RUBY_VERSION" ]; then
            print_info "System Ruby $CURRENT_RUBY is compatible"
            return 0
        else
            print_warning "System Ruby $CURRENT_RUBY is too old (minimum: $MINIMUM_RUBY_VERSION)"
            print_info "Consider installing rbenv or rvm for better Ruby version management"
            print_info "  rbenv: brew install rbenv (macOS) or https://github.com/rbenv/rbenv"
            print_info "  rvm: https://rvm.io/"
        fi
    else
        print_error "Ruby not found!"
        print_info "Please install Ruby $MINIMUM_RUBY_VERSION or later"
        print_info "Recommended: Install rbenv or rvm first"
        return 1
    fi
}

# Parse arguments (pass them to the installer)
ARGS="$@"

# Default to master branch if no version specified
VERSION="master"
MODE=""

# Parse arguments to extract version and mode
# Use a separate array to avoid modifying the original arguments
set -- "$@"
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

print_info "SwiftJsonUI Bootstrap"
print_info "Version: $VERSION"
if [ -n "$MODE" ]; then
    print_info "Mode: $MODE"
fi

# Setup Ruby environment first
setup_ruby_environment

print_info "Downloading installer from branch/tag: $VERSION"

# Download the installer script
# Add cache busting parameter to avoid GitHub's CDN cache
INSTALLER_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$VERSION/$INSTALLER_PATH?$(date +%s)"
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