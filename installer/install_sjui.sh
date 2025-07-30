#!/usr/bin/env bash

# SwiftJsonUI Installer Script
# This script downloads and installs binding_builder and hot_loader

set -e

# Default values
GITHUB_REPO="Tai-Kimura/SwiftJsonUI"
DEFAULT_BRANCH="main"
INSTALL_DIR="."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version <version>    Specify version/branch/tag to download (default: main)"
    echo "  -d, --directory <dir>      Installation directory (default: current directory)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Install latest from main branch"
    echo "  $0 -v v1.0.0               # Install specific version"
    echo "  $0 -v feature-branch       # Install from specific branch"
    echo "  $0 -d ./my-project         # Install in specific directory"
    exit 0
}

# Parse command line arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -d|--directory)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Use default branch if no version specified
if [ -z "$VERSION" ]; then
    VERSION="$DEFAULT_BRANCH"
fi

# Validate installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    print_error "Installation directory does not exist: $INSTALL_DIR"
    exit 1
fi

# Change to installation directory
cd "$INSTALL_DIR"

print_info "Installing SwiftJsonUI tools..."
print_info "Version: $VERSION"
print_info "Directory: $(pwd)"

# Check if binding_builder already exists
if [ -d "binding_builder" ]; then
    print_warning "binding_builder directory already exists."
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping binding_builder installation."
        SKIP_BINDING_BUILDER=true
    else
        rm -rf binding_builder
    fi
fi

# Check if hot_loader already exists
if [ -d "hot_loader" ]; then
    print_warning "hot_loader directory already exists."
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping hot_loader installation."
        SKIP_HOT_LOADER=true
    else
        rm -rf hot_loader
    fi
fi

# Create temporary directory for download
TEMP_DIR=$(mktemp -d)
print_info "Created temporary directory: $TEMP_DIR"

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Download the archive
print_info "Downloading SwiftJsonUI $VERSION..."
DOWNLOAD_URL="https://github.com/$GITHUB_REPO/archive/$VERSION.tar.gz"

if ! curl -L -f -o "$TEMP_DIR/swiftjsonui.tar.gz" "$DOWNLOAD_URL"; then
    print_error "Failed to download from $DOWNLOAD_URL"
    print_error "Please check if the version/branch '$VERSION' exists."
    exit 1
fi

# Extract the archive
print_info "Extracting archive..."
tar -xzf "$TEMP_DIR/swiftjsonui.tar.gz" -C "$TEMP_DIR"

# Find the extracted directory (it will have a dynamic name based on version)
EXTRACT_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "SwiftJsonUI-*" | head -1)

if [ -z "$EXTRACT_DIR" ]; then
    print_error "Failed to find extracted directory"
    exit 1
fi

# Copy binding_builder if not skipped
if [ -z "$SKIP_BINDING_BUILDER" ]; then
    if [ -d "$EXTRACT_DIR/binding_builder" ]; then
        print_info "Installing binding_builder..."
        cp -r "$EXTRACT_DIR/binding_builder" .
        
        # Create VERSION file with the downloaded version
        echo "$VERSION" > binding_builder/VERSION
        print_info "Set binding_builder version to: $VERSION"
        
        # Make sjui executable
        if [ -f "binding_builder/sjui" ]; then
            chmod +x binding_builder/sjui
            print_info "Made binding_builder/sjui executable"
        fi
        
        # Make all .sh files executable
        find binding_builder -name "*.sh" -type f -exec chmod +x {} \;
        
        print_info "✅ binding_builder installed successfully"
    else
        print_warning "binding_builder not found in the downloaded version"
    fi
fi

# Copy hot_loader if not skipped
if [ -z "$SKIP_HOT_LOADER" ]; then
    if [ -d "$EXTRACT_DIR/hot_loader" ]; then
        print_info "Installing hot_loader..."
        cp -r "$EXTRACT_DIR/hot_loader" .
        print_info "✅ hot_loader installed successfully"
    else
        print_warning "hot_loader not found in the downloaded version"
    fi
fi

# Install Ruby dependencies if Gemfile exists
if [ -f "binding_builder/Gemfile" ]; then
    print_info "Installing Ruby dependencies..."
    cd binding_builder
    if command -v bundle &> /dev/null; then
        bundle install
        cd ..
        print_info "✅ Ruby dependencies installed"
    else
        cd ..
        print_warning "Bundler not found. Please install Ruby dependencies manually:"
        print_warning "  cd binding_builder && bundle install"
    fi
fi

# Create initial config.json
if [ ! -f "binding_builder/config.json" ]; then
    print_info "Creating initial configuration..."
    cd binding_builder
    ./sjui init
    cd ..
fi

print_info ""
print_info "🎉 Installation completed successfully!"
print_info ""
print_info "Next steps:"
print_info "1. Run 'cd binding_builder && ./sjui setup' to set up your project"
print_info "2. Run './sjui help' to see available commands"
print_info ""
print_info "For more information, visit: https://github.com/$GITHUB_REPO"