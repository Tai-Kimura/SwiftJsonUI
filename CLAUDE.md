# SwiftJsonUI Development Guide

## SwiftUI Support Testing Workflow

When implementing SwiftUI support features:

1. **Test Project Location**: `~/resource/swiftUITestApp/swiftUITestApp`
   - Modify: `swiftUITestApp/sjui_tools/` for testing
   - Test the changes in the SwiftUI test app

2. **After Testing Success**:
   - Apply the same modifications to main SwiftJsonUI repository
   - Location: `/Users/like-a-rolling_stone/resource/SwiftJsonUI`

3. **Deployment**:
   - Push changes to `7.0.0-beta` branch
   - Move/update the `7.0.0-beta` tag

### Example Commands:
```bash
# Testing in SwiftUI test app
cd ~/resource/swiftUITestApp/swiftUITestApp
# Make changes to sjui_tools/
./sjui_tools/bin/sjui build

# After testing, apply to main repo
cd /Users/like-a-rolling_stone/resource/SwiftJsonUI
# Apply same changes
git add -A
git commit -m "Your commit message"
git push origin refs/heads/7.0.0-beta:refs/heads/7.0.0-beta

# Update tag
git tag -f 7.0.0-beta
git push origin 7.0.0-beta --force
```

## Other Important Workflows

### Pango iOS Testing
- Test binding changes in: `/Users/like-a-rolling_stone/resource/pango_ios/pango`
- Pango has its own copy of sjui_tools that may need updates

### Binding Test App
- Location: `/Users/like-a-rolling_stone/resource/bindingTestApp/bindingTestApp`
- Used for testing binding generation and functionality