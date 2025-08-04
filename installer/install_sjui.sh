#!/usr/bin/env bash

# SwiftJsonUI Installer Script
# This script downloads and installs sjui_tools (unified tool for binding, hot_loader, and swiftui)

set -e

# Default values
GITHUB_REPO="Tai-Kimura/SwiftJsonUI"
DEFAULT_BRANCH="master"
INSTALL_DIR=".."

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
    echo "  -v, --version <version>    Specify version/branch/tag to download (default: master)"
    echo "  -d, --directory <dir>      Installation directory (default: parent directory)"
    echo "  -s, --skip-bundle          Skip bundle install for Ruby dependencies"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Install latest from master branch to parent directory"
    echo "  $0 -v v7.0.0               # Install specific version"
    echo "  $0 -v feature-branch       # Install from specific branch"
    echo "  $0 -d ./my-project         # Install in specific directory"
    echo "  $0 -s                      # Skip bundle install"
    exit 0
}

# Parse command line arguments
VERSION=""
SKIP_BUNDLE=false

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
        -s|--skip-bundle)
            SKIP_BUNDLE=true
            shift
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

# Check if sjui_tools already exists
if [ -d "sjui_tools" ]; then
    print_warning "sjui_tools directory already exists."
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    else
        rm -rf sjui_tools
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
# Check if VERSION looks like a version number (starts with digit or v)
if [[ "$VERSION" =~ ^[0-9] ]] || [[ "$VERSION" =~ ^v[0-9] ]]; then
    # For tags, use refs/tags/ prefix
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/archive/refs/tags/$VERSION.tar.gz"
else
    # For branches, use the direct format
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/archive/$VERSION.tar.gz"
fi

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

# Copy sjui_tools
if [ -d "$EXTRACT_DIR/sjui_tools" ]; then
    print_info "Installing sjui_tools..."
    cp -r "$EXTRACT_DIR/sjui_tools" .
    
    # Create VERSION file with the downloaded version
    echo "$VERSION" > sjui_tools/VERSION
    print_info "Set sjui_tools version to: $VERSION"
    
    # Make sjui executable
    if [ -f "sjui_tools/bin/sjui" ]; then
        chmod +x sjui_tools/bin/sjui
        print_info "Made sjui_tools/bin/sjui executable"
    fi
    
    # Make all .sh files executable
    find sjui_tools -name "*.sh" -type f -exec chmod +x {} \;
    
    print_info "✅ sjui_tools installed successfully"
else
    print_error "sjui_tools not found in the downloaded version"
    print_error "Please use version 7.0.0 or later"
    exit 1
fi

# Install Node.js dependencies for hot_loader
if [ -d "sjui_tools/lib/hotloader" ] && [ -f "sjui_tools/lib/hotloader/package.json" ]; then
    HOT_LOADER_DIR="sjui_tools/lib/hotloader"
    print_info "Installing hot_loader Node.js dependencies..."
    cd "$HOT_LOADER_DIR"
    if command -v npm &> /dev/null; then
        if npm install; then
            cd - > /dev/null
            print_info "✅ hot_loader Node.js dependencies installed"
        else
            cd - > /dev/null
            print_warning "Failed to install hot_loader Node.js dependencies"
            print_warning "You can install them manually later:"
            print_warning "  cd $HOT_LOADER_DIR && npm install"
        fi
    else
        cd - > /dev/null
        print_warning "npm not found. Please install Node.js and npm"
        print_warning "Then run: cd $HOT_LOADER_DIR && npm install"
    fi
fi

# Install Ruby dependencies
if [ -f "sjui_tools/Gemfile" ] && [ "$SKIP_BUNDLE" != true ]; then
    GEMFILE_DIR="sjui_tools"
    print_info "Installing Ruby dependencies..."
    
    # Check Ruby version
    if command -v ruby &> /dev/null; then
        RUBY_VERSION=$(ruby -v | cut -d' ' -f2)
        print_info "Ruby version: $RUBY_VERSION"
        
        # Check if Ruby version is at least 2.7.0
        if ruby -e "exit RUBY_VERSION >= '2.7.0' ? 0 : 1" 2>/dev/null; then
            print_info "Ruby version is compatible"
        else
            print_warning "Ruby version is older than 2.7.0"
            print_warning "Some features may not work properly"
            print_warning "Please consider upgrading Ruby to 2.7.0 or later"
        fi
    fi
    
    cd "$GEMFILE_DIR"
    
    if command -v bundle &> /dev/null; then
        if bundle install; then
            cd - > /dev/null
            print_info "✅ Ruby dependencies installed"
        else
            cd - > /dev/null
            print_warning "Failed to install Ruby dependencies"
            print_warning "You can install them manually later:"
            print_warning "  cd $GEMFILE_DIR && bundle install"
        fi
    else
        # Try to install bundler
        if command -v gem &> /dev/null; then
            print_info "Installing bundler..."
            if gem install bundler; then
                if bundle install; then
                    cd - > /dev/null
                    print_info "✅ Ruby dependencies installed"
                else
                    cd - > /dev/null
                    print_warning "Failed to install Ruby dependencies"
                fi
            else
                cd - > /dev/null
                print_warning "Failed to install bundler"
            fi
        else
            cd - > /dev/null
            print_warning "Ruby not found. Please install Ruby first"
        fi
    fi
elif [ "$SKIP_BUNDLE" = true ]; then
    print_info "Skipping bundle install as requested"
fi

# Create initial config.json
CONFIG_CREATED=false

if [ -f "sjui_tools/bin/sjui" ]; then
    SJUI_BIN="sjui_tools/bin/sjui"
    print_info "Checking for Xcode project..."
    # Search for .xcodeproj files in parent directories
    SEARCH_DIR="$(pwd)"
    FOUND_XCODEPROJ=""
    MAX_LEVELS=5
    CURRENT_LEVEL=0
    
    while [ $CURRENT_LEVEL -lt $MAX_LEVELS ] && [ -z "$FOUND_XCODEPROJ" ]; do
        if ls "$SEARCH_DIR"/*.xcodeproj 1> /dev/null 2>&1; then
            FOUND_XCODEPROJ="$(ls "$SEARCH_DIR"/*.xcodeproj | head -1)"
            print_info "Found Xcode project: $FOUND_XCODEPROJ"
            break
        fi
        SEARCH_DIR="$(dirname "$SEARCH_DIR")"
        CURRENT_LEVEL=$((CURRENT_LEVEL + 1))
    done
    
    if [ -n "$FOUND_XCODEPROJ" ]; then
        print_info "Creating initial configuration..."
        if $SJUI_BIN init 2>/dev/null; then
            CONFIG_CREATED=true
            print_info "✅ Initial configuration created"
        else
            print_warning "Failed to create initial configuration"
            print_warning "You can create it manually later with:"
            print_warning "  $SJUI_BIN init"
        fi
    else
        print_warning "No Xcode project found in parent directories"
        print_warning "After moving to your Xcode project directory, run:"
        print_warning "  $SJUI_BIN init"
    fi
fi

print_info ""
print_info "🎉 Installation completed successfully!"
print_info ""
print_info "Next steps:"

if [ -d "sjui_tools" ]; then
    print_info "1. Add sjui_tools/bin to your PATH or use the full path"
    print_info "2. Run 'sjui init' to create configuration (if not done)"
    print_info "3. Run 'sjui setup' to set up your project"
    print_info "4. Run 'sjui help' to see available commands"
fi

print_info ""
print_info "For more information, visit: https://github.com/$GITHUB_REPO"