# SwiftJsonUI Tools

Unified command-line tools for SwiftJsonUI framework.

## Requirements

- Ruby 2.7.0 or later (Ruby 3.2+ recommended)
- Bundler
- Node.js and npm (for HotLoader functionality)
- Xcode (for iOS projects)

## Installation

```bash
# Install from GitHub
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash

# Or with specific version
curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/master/installer/bootstrap.sh | bash -s -- -v 7.0.0-alpha
```

## Ruby Version

This tool requires Ruby 2.7.0 or later. We recommend using Ruby 3.2.2 or later for best compatibility.

To check your Ruby version:
```bash
ruby -v
```

To upgrade Ruby, we recommend using a Ruby version manager:
- [rbenv](https://github.com/rbenv/rbenv)
- [rvm](https://rvm.io/)
- [asdf](https://asdf-vm.com/)

## Usage

```bash
# Initialize project
sjui init

# Setup project structure
sjui setup

# Generate views
sjui g view HomeView
sjui g partial header
sjui g collection ProductList/Item

# Start HotLoader
sjui hotload

# Watch for changes
sjui watch
```

## Troubleshooting

### Bundle Install Errors

If you encounter bundler version errors:
```bash
gem install bundler
cd sjui_tools && bundle install
```

### Xcode 16 Compatibility

This version includes patches for Xcode 16's new PBXFileSystemSynchronizedRootGroup format.

## License

See the main SwiftJsonUI repository for license information.