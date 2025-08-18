# SwiftUI Mode - Unimplemented Attributes Checklist

This checklist tracks attributes documented in the SwiftJsonUI wiki that are not yet implemented in SwiftUI mode.

## Common Attributes (共通属性)

### Core Identification & Structure

### Implemented (実装済み)
- ✅ `style` - Style file name to apply
- ✅ `lines` - Number of lines for Label (0 = unlimited)
- ✅ `lineBreakMode` - Line break mode for Label

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

### Layout & Positioning
- [ ] `idealWidth` - Ideal width for flexible frame (.frame(idealWidth:))
- [ ] `idealHeight` - Ideal height for flexible frame (.frame(idealHeight:))

### Advanced Margins

### Relative Positioning
- [ ] `alignTopOfView` - Align below specified view ID
- [ ] `alignBottomOfView` - Align above specified view ID
- [ ] `alignLeftOfView` - Align to right of specified view ID
- [ ] `alignRightOfView` - Align to left of specified view ID
- [ ] `alignTopView` - Align top edge with specified view
- [ ] `alignBottomView` - Align bottom edge with specified view
- [ ] `alignLeftView` - Align left edge with specified view
- [ ] `alignRightView` - Align right edge with specified view
- [ ] `alignCenterVerticalView` - Center vertically with specified view
- [ ] `alignCenterHorizontalView` - Center horizontally with specified view

### Visual Appearance
- [ ] `tapBackground` - Background color when tapped
- [ ] `clipToBounds` - Proper clip to bounds implementation

### Layout Priority

### Z-Order
- [ ] `indexBelow` - Place below specified view ID
- [ ] `indexAbove` - Place above specified view ID

## Component-Specific Attributes

### View / SafeAreaView
- [ ] `direction` - Layout direction (topToBottom, bottomToTop, etc.)
- [ ] `distribution` - Child distribution in stack
- [ ] `highlightBackground` - Background when highlighted
- [ ] `highlighted` - Highlighted state
- [ ] `canTap` - Enable tap capability
- [ ] `events` - Complex event handlers
- [ ] `touchDisabledState` - Touch disable mode
- [ ] `touchEnabledViewIds` - Array of enabled views

### Button
- [ ] `hilightColor` - Text color when highlighted
- [ ] `disabledFontColor` - Text color when disabled
- [ ] `disabledBackground` - Background when disabled
- [ ] `image` - Background image
- [ ] `config` - UIButton.Configuration (iOS 15+)

### Label
- [ ] `edgeInset` - Text padding
- [ ] `underline` - Underline styling
- [ ] `strikethrough` - Strikethrough styling
- [ ] `lineHeightMultiple` - Line height multiplier
- [ ] `textShadow` - Text shadow
- [ ] `partialAttributes` - Partial text styling
- [ ] `highlightAttributes` - Highlight text attributes
- [ ] `highlightColor` - Text color when selected
- [ ] `hintAttributes` - Hint text attributes
- [ ] `hintColor` - Hint text color
- [ ] `autoShrink` - Auto font size adjustment
- [ ] `minimumScaleFactor` - Minimum scale for auto shrink
- [ ] `linkable` - Make URLs clickable

### TextField
- [ ] `hintFont` - Placeholder font
- [ ] `hintFontSize` - Placeholder font size
- [ ] `fieldPadding` - Right inner padding
- [ ] `borderStyle` - Border style (RoundedRect, Line, Bezel)
- [ ] `input` - Keyboard type configuration
- [ ] `returnKeyType` - Return key type
- [ ] `onTextChange` - Text change event
- [ ] `secure` - Secure text entry
- [ ] `accessoryBackground` - Input accessory background
- [ ] `accessoryTextColor` - Input accessory text color
- [ ] `doneText` - Done button text

### TextView
- [ ] `hintFont` - Placeholder font
- [ ] `hideOnFocused` - Hide placeholder when focused
- [ ] `flexible` - Auto-height adjustment
- [ ] `containerInset` - Text container insets
- [ ] `returnKeyType` - Return key type

### Image
- [ ] `highlightSrc` - Image when highlighted

### NetworkImage / CircleImage
- [ ] `defaultImage` - Default image
- [ ] `errorImage` - Error state image
- [ ] `loadingImage` - Loading state image

### ScrollView
- [ ] `showsHorizontalScrollIndicator` - Show horizontal indicator
- [ ] `showsVerticalScrollIndicator` - Show vertical indicator
- [ ] `maxZoom` - Maximum zoom scale
- [ ] `minZoom` - Minimum zoom scale
- [ ] `paging` - Enable paging
- [ ] `bounces` - Enable bounce
- [ ] `scrollEnabled` - Enable scrolling

### Collection
- [ ] `horizontalScroll` - Horizontal scroll direction
- [ ] `insets` - Section insets
- [ ] `insetHorizontal` - Horizontal insets
- [ ] `insetVertical` - Vertical insets
- [ ] `columnSpacing` - Inter-item spacing
- [ ] `lineSpacing` - Line spacing
- [ ] `contentInsets` - Content insets
- [ ] `itemWeight` - Item sizing weight
- [ ] `layout` - Layout type
- [ ] `cellClasses` - Cell class definitions
- [ ] `headerClasses` - Header class definitions
- [ ] `footerClasses` - Footer class definitions
- [ ] `setTargetAsDelegate` - Set delegate
- [ ] `setTargetAsDataSource` - Set data source

### Switch
- [ ] `tint` - On state color
- [ ] `onValueChange` - Value change event

### Slider
- [ ] `tintColor` - Slider tint color
- [ ] `minimum` - Minimum value
- [ ] `maximum` - Maximum value

### Progress
- [ ] `tintColor` - Progress tint color

### Indicator
- [ ] `color` - Indicator color
- [ ] `hidesWhenStopped` - Hide when stopped

### Check
- [ ] `label` - Associated label ID
- [ ] `onSrc` - Selected state image
- [ ] `checked` - Initial state

### Radio
- [ ] `icon` - Normal state icon
- [ ] `selected_icon` - Selected state icon
- [ ] `group` - Radio group name
- [ ] `checked` - Initial state

### Segment
- [ ] `items` - Segment items
- [ ] `enabled` - Enabled state
- [ ] `tintColor` - Tint color
- [ ] `normalColor` - Normal text color
- [ ] `selectedColor` - Selected text color
- [ ] `valueChange` - Value change event

### SelectBox
- [ ] `caretAttributes` - Caret styling
- [ ] `dividerAttributes` - Divider styling
- [ ] `labelAttributes` - Label styling
- [ ] `canBack` - Show back button
- [ ] `prompt` - Picker prompt
- [ ] `includePromptWhenDataBinding` - Include prompt in binding
- [ ] `minuteInterval` - Minute intervals

### IconLabel
- [ ] `textShadow` - Text shadow
- [ ] `selectedFontColor` - Selected text color
- [ ] `iconMargin` - Icon-text spacing

### GradientView
- [ ] `locations` - Color stop locations

### Web
- [ ] `html` - HTML content
- [ ] `allowsBackForwardNavigationGestures` - Enable swipe navigation
- [ ] `allowsLinkPreview` - Enable link preview

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