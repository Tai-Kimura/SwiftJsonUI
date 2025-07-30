# SwiftJsonUI Installer

This directory contains installation scripts for SwiftJsonUI tools.

## Quick Start

To install SwiftJsonUI tools in your project, run this command:

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/bootstrap.sh | bash
```

This will download and install:
- `binding_builder` - The code generation tool
- `hot_loader` - The hot reload server

## Installation Options

### Install specific version

```bash
# Install from a specific tag
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/bootstrap.sh | bash -s -- -v v1.0.0

# Install from a specific branch
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/bootstrap.sh | bash -s -- -v feature-branch
```

### Install in specific directory

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/bootstrap.sh | bash -s -- -d ./my-project
```

### Combined options

```bash
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/bootstrap.sh | bash -s -- -v v1.0.0 -d ./my-project
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
- `-v, --version <version>` - Specify version/branch/tag to download (default: main)
- `-d, --directory <dir>` - Installation directory (default: current directory)
- `-h, --help` - Show help message

## What Gets Installed

The installer will:
1. Download the specified version of SwiftJsonUI
2. Extract `binding_builder` and `hot_loader` directories to the parent directory (or specified directory)
3. Make all executable files runnable
4. Install Ruby dependencies (if bundler is available)
5. Create initial `config.json` file

By default, the tools are installed in the parent directory of where the installer is run. This means if you run the installer from `YourProject/installer/`, the tools will be installed in `YourProject/`.

## Requirements

- Bash shell
- curl
- tar
- Ruby and Bundler (for binding_builder dependencies)

## Troubleshooting

If you encounter issues:
1. Ensure you have all required tools installed
2. Check your internet connection
3. Verify the version/branch name exists
4. Check file permissions in your installation directory

For more help, visit: https://github.com/Tai-Kimura/SwiftJsonUI