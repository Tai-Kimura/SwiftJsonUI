# SwiftJsonUI Installer

This directory contains installation scripts for SwiftJsonUI tools.

## Quick Start

To install SwiftJsonUI tools in your project, run this command:

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/tools/installer/bootstrap.sh | bash
```

This will download and install:
- `sjui_tools` - The unified tool containing binding_builder, hot_loader, and swiftui_builder functionality

## Installation Options

### Install specific version

```bash
# Install from a specific tag
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/tools/installer/bootstrap.sh | bash -s -- -v v7.0.0

# Install from a specific branch
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/tools/installer/bootstrap.sh | bash -s -- -v feature-branch
```

### Install in specific directory

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/tools/installer/bootstrap.sh | bash -s -- -d ./my-project
```

### Skip Ruby dependency installation

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/tools/installer/bootstrap.sh | bash -s -- -s
```

### Combined options

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/tools/installer/bootstrap.sh | bash -s -- -v v7.0.0 -d ./my-project -s
```

## Manual Installation

If you prefer to download and run the installer manually:

1. Download the installer script:
```bash
curl -O https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/install_sjui.sh
chmod +x install_sjui.sh
```

2. Run the installer:
```bash
./install_sjui.sh [OPTIONS]
```

Available options:
- `-v, --version <version>` - Specify version/branch/tag to download (default: master)
- `-d, --directory <dir>` - Installation directory (default: parent directory)
- `-s, --skip-bundle` - Skip bundle install for Ruby dependencies
- `-h, --help` - Show help message

## What Gets Installed

The installer will:
1. Download the specified version of SwiftJsonUI
2. Extract `sjui_tools` directory to the parent directory (or specified directory)
3. Make the `sjui` command executable
4. Install Ruby dependencies (if bundler is available and not skipped)
5. Install Node.js dependencies for hot_loader (if npm is available)
6. Create initial `config.json` file if an Xcode project is found

By default, the tools are installed in the parent directory of where the installer is run. This means if you run the installer from `YourProject/installer/`, the tools will be installed in `YourProject/`.

## Using the Unified Tool

After installation, you can use the unified `sjui` command:

```bash
# Initialize configuration
sjui_tools/bin/sjui init

# Set up your project (binding mode)
sjui_tools/bin/sjui setup

# Generate a view
sjui_tools/bin/sjui generate view MyView

# Build bindings
sjui_tools/bin/sjui build

# Convert JSON to SwiftUI
sjui_tools/bin/sjui convert swiftui input.json

# See all available commands
sjui_tools/bin/sjui help
```

## Requirements

- Bash shell
- curl
- tar
- Ruby and Bundler (for Ruby dependencies)
- Node.js and npm (for hot_loader functionality)

## Legacy Support

The installer automatically detects older versions of SwiftJsonUI and installs the legacy structure (separate binding_builder, hot_loader, and swiftui_builder directories) for backward compatibility.

## Troubleshooting

If you encounter issues:
1. Ensure you have all required tools installed
2. Check your internet connection
3. Verify the version/branch name exists
4. Check file permissions in your installation directory

For more help, visit: https://github.com/Tai-Kimura/SwiftJsonUI