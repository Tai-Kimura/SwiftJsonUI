# HotLoader Configuration

## hotload.config

This configuration file allows you to customize the HotLoader behavior, especially for projects where the Info.plist file is not in the default location.

### Configuration Options

1. **PLIST_PATH**: Path to your Info.plist file
   - Default: `Info.plist` (relative to project directory)
   - Can be a relative path from the project directory or an absolute path
   - Examples:
     - `Info.plist` (default)
     - `Resources/Info.plist`
     - `MyApp/Supporting Files/Info.plist`
     - `/absolute/path/to/Info.plist`

2. **HOTLOADER_DIR**: Path to the hot_loader directory
   - Default: `hot_loader` (relative to project directory)
   - Can be a relative path from the project directory or an absolute path
   - Examples:
     - `hot_loader` (default)
     - `MyApp/hot_loader`
     - `/absolute/path/to/hot_loader`

### Usage

1. Edit `hotload.config` in this directory
2. Set your custom paths
3. The HotLoader commands will automatically use these settings

### Example Configuration

```bash
# For a project with Info.plist in a custom location
PLIST_PATH="MyApp/Resources/Info.plist"
HOTLOADER_DIR="MyApp/hot_loader"
```

### Notes

- If the config file is not found, the default values will be used
- Relative paths are resolved from the project root (where the .xcodeproj file is located)
- The configuration affects both `sjui hotload` commands and the IP monitor script