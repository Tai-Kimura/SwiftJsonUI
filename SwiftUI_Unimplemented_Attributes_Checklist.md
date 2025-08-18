# SwiftUI Mode - Unimplemented Attributes Checklist

This checklist tracks attributes documented in the SwiftJsonUI wiki that are not yet implemented in SwiftUI mode.

## Common Attributes (共通属性)

### Core Identification & Structure

### Implemented (実装済み)
- ✅ `style` - Style file name to apply
- ✅ `lines` - Number of lines for Label (0 = unlimited)
- ✅ `lineBreakMode` - Line break mode for Label
- ✅ `alignTopOfView` - Align below specified view ID
- ✅ `alignBottomOfView` - Align above specified view ID
- ✅ `alignLeftOfView` - Align to right of specified view ID
- ✅ `alignRightOfView` - Align to left of specified view ID
- ✅ `alignTopView` - Align top edge with specified view
- ✅ `alignBottomView` - Align bottom edge with specified view
- ✅ `alignLeftView` - Align left edge with specified view
- ✅ `alignRightView` - Align right edge with specified view
- ✅ `alignCenterVerticalView` - Center vertically with specified view
- ✅ `alignCenterHorizontalView` - Center horizontally with specified view
- ✅ `idealWidth` - Ideal width for flexible frame
- ✅ `idealHeight` - Ideal height for flexible frame
- ✅ `clipToBounds` - Clip content to bounds
- ✅ `indexBelow` - Place below specified view ID
- ✅ `indexAbove` - Place above specified view ID
- ✅ `direction` - Layout direction for View (topToBottom, bottomToTop, leftToRight, rightToLeft)
- ✅ `distribution` - Child distribution in stack (fillEqually, equalSpacing, equalCentering)
- ✅ `edgeInset` - Text padding for Label
- ✅ `tapBackground` - Background color when tapped (Button and View)
- ✅ `hilightColor` - Text color when highlighted (Button with StateAwareButton)
- ✅ `disabledFontColor` - Text color when disabled (Button with StateAwareButton)
- ✅ `disabledBackground` - Background when disabled (Button with StateAwareButton)

### Not Required (実装不要)
- ~~`propertyName`~~ - Alternative to id for data binding
- ~~`binding`~~ - Complex data binding configuration  
- ~~`tag`~~ - View tag for identification
- ~~`widthWeight`~~ - Width ratio for weighted layouts
- ~~`heightWeight`~~ - Height ratio for weighted layouts
- ~~`rect`~~ - Direct frame setting [x, y, width, height]
- ~~`frame`~~ - Frame configuration (except Button which is implemented)
- ~~`minLeftMargin`~~ - Minimum left margin (SwiftUI has no min/max padding concept)
- ~~`minRightMargin`~~ - Minimum right margin
- ~~`minTopMargin`~~ - Minimum top margin
- ~~`minBottomMargin`~~ - Minimum bottom margin
- ~~`maxLeftMargin`~~ - Maximum left margin
- ~~`maxRightMargin`~~ - Maximum right margin
- ~~`maxTopMargin`~~ - Maximum top margin
- ~~`maxBottomMargin`~~ - Maximum bottom margin
- ~~`layoutPriority`~~ - Layout priority for space allocation
- ~~`compressHorizontal`~~ - Horizontal compression resistance
- ~~`compressVertical`~~ - Vertical compression resistance
- ~~`hugHorizontal`~~ - Horizontal content hugging priority
- ~~`hugVertical`~~ - Vertical content hugging priority
- ~~`image`~~ - Background image for Button (not needed)
- ~~`config`~~ - UIButton.Configuration (iOS 15+, UIKit specific)

### Layout & Positioning

### Advanced Margins

### Relative Positioning

### Visual Appearance
- [ ] `tapBackground` - Background color when tapped

### Layout Priority

### Z-Order

## Component-Specific Attributes

### View / SafeAreaView
- ✅ `highlightBackground` - Background when highlighted (Dynamic mode)
- ✅ `highlighted` - Highlighted state (Dynamic mode)
- ✅ `canTap` - Enable tap capability
- ✅ `events` - Complex event handlers (Dynamic mode)
- [ ] `touchDisabledState` - Touch disable mode
- [ ] `touchEnabledViewIds` - Array of enabled views

### Button

### Label
- ✅ `edgeInset` - Text padding
- ✅ `underline` - Underline styling
- ✅ `strikethrough` - Strikethrough styling
- ✅ `lineHeightMultiple` - Line height multiplier
- ✅ `textShadow` - Text shadow
- ✅ `partialAttributes` - Partial text styling (Dynamic mode)
- ✅ `highlightAttributes` - Highlight text attributes (Dynamic mode)
- ✅ `highlightColor` - Text color when selected (Dynamic mode)
- ✅ `hintAttributes` - Hint text attributes (Dynamic mode)
- ✅ `hintColor` - Hint text color (Dynamic mode)
- ✅ `autoShrink` - Auto font size adjustment
- ✅ `minimumScaleFactor` - Minimum scale for auto shrink
- ✅ `linkable` - Make URLs clickable (Dynamic mode only)

### TextField
- ✅ `hintFont` - Placeholder font (Dynamic mode only)
- ✅ `hintFontSize` - Placeholder font size (Dynamic mode only)
- ✅ `fieldPadding` - Right inner padding (Dynamic mode only)
- ✅ `borderStyle` - Border style (RoundedRect, Line, Bezel)
- ✅ `input` - Keyboard type configuration
- ✅ `returnKeyType` - Return key type
- ✅ `onTextChange` - Text change event
- ✅ `secure` - Secure text entry
- ✅ `accessoryBackground` - Input accessory background (Dynamic mode)
- ✅ `accessoryTextColor` - Input accessory text color (Dynamic mode)
- ✅ `doneText` - Done button text (Dynamic mode)

### TextView
- ✅ `hintFont` - Placeholder font (Dynamic mode)
- ✅ `hideOnFocused` - Hide placeholder when focused (Dynamic mode)
- ✅ `flexible` - Auto-height adjustment (Dynamic mode)
- ✅ `containerInset` - Text container insets (Dynamic mode)
- [ ] `returnKeyType` - Return key type (not supported in SwiftUI TextEditor)

### Image
- ✅ `highlightSrc` - Image when highlighted (Dynamic mode)

### NetworkImage / CircleImage
- ✅ `defaultImage` - Default image
- ✅ `errorImage` - Error state image
- ✅ `loadingImage` - Loading state image

### ScrollView
- ✅ `showsHorizontalScrollIndicator` - Show horizontal indicator
- ✅ `showsVerticalScrollIndicator` - Show vertical indicator
- ✅ `maxZoom` - Maximum zoom scale
- ✅ `minZoom` - Minimum zoom scale
- ✅ `paging` - Enable paging (iOS 17+ in static mode)
- ✅ `bounces` - Enable bounce (comment only in static)
- ✅ `scrollEnabled` - Enable scrolling

### Collection
- ✅ `horizontalScroll` - Horizontal scroll direction
- ✅ `insets` - Section insets
- ✅ `insetHorizontal` - Horizontal insets
- ✅ `insetVertical` - Vertical insets
- ✅ `columnSpacing` - Inter-item spacing
- ✅ `lineSpacing` - Line spacing
- ✅ `contentInsets` - Content insets
- [ ] `itemWeight` - Item sizing weight
- [ ] `layout` - Layout type
- [ ] `cellClasses` - Cell class definitions
- [ ] `headerClasses` - Header class definitions
- [ ] `footerClasses` - Footer class definitions
- [ ] `setTargetAsDelegate` - Set delegate
- [ ] `setTargetAsDataSource` - Set data source

### Switch
- ✅ `tint` - On state color
- [ ] `onValueChange` - Value change event

### Slider
- ✅ `tintColor` - Slider tint color
- ✅ `minimum` - Minimum value
- ✅ `maximum` - Maximum value

### Progress
- ✅ `tintColor` - Progress tint color

### Indicator
- ✅ `color` - Indicator color
- ✅ `hidesWhenStopped` - Hide when stopped

### Check
- ✅ `label` - Associated label ID
- ✅ `onSrc` - Selected state image
- ✅ `checked` - Initial state

### Radio
- ✅ `icon` - Normal state icon
- ✅ `selected_icon` - Selected state icon
- ✅ `group` - Radio group name
- ✅ `checked` - Initial state

### Segment
- ✅ `items` - Segment items
- ✅ `enabled` - Enabled state
- ✅ `tintColor` - Tint color
- ✅ `normalColor` - Normal text color
- ✅ `selectedColor` - Selected text color
- ✅ `valueChange` - Value change event (onChange)

### SelectBox
- ✅ `caretAttributes` - Caret styling (Dynamic mode)
- ✅ `dividerAttributes` - Divider styling (Dynamic mode)
- ✅ `labelAttributes` - Label styling (Dynamic mode)
- ✅ `canBack` - Show back button (Dynamic mode)
- ✅ `prompt` - Picker prompt (Dynamic mode)
- ✅ `includePromptWhenDataBinding` - Include prompt in binding (Dynamic mode)
- ✅ `minuteInterval` - Minute intervals (Dynamic mode)

### IconLabel
- [ ] `textShadow` - Text shadow
- [ ] `selectedFontColor` - Selected text color
- [ ] `iconMargin` - Icon-text spacing

### GradientView
- [ ] `locations` - Color stop locations

### Web
- ✅ `html` - HTML content (Dynamic mode)
- ✅ `allowsBackForwardNavigationGestures` - Enable swipe navigation (Dynamic mode)
- ✅ `allowsLinkPreview` - Enable link preview (Dynamic mode)

## Implementation Notes

### Priority Levels
1. **High Priority** - Core functionality affecting most users
   - TextField attributes (secure, borderStyle, returnKeyType)
   - Label text styling (lines, lineBreakMode)
   - ScrollView indicators and behavior
   - Button states (disabled styling)

2. **Medium Priority** - Important but less frequently used
   - Relative positioning attributes
   - Layout priorities
   - Collection view attributes
   - Advanced text styling

3. **Low Priority** - Nice to have
   - Z-order control
   - Complex event handlers
   - Style file support
   - Min/max margin constraints

### Implementation Status
- ✅ Implemented
- ⚠️ Partially implemented
- ❌ Not implemented
- 🚧 In progress

### Notes
- Many of these attributes are fully implemented in UIKit mode but missing from SwiftUI converters
- Some attributes may not have direct SwiftUI equivalents and will require custom implementations
- Priority should be given to attributes that have UIKit implementations that can be referenced