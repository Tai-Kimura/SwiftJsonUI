# SwiftJsonUI - Supported View Types and Attributes

## UIKit Mode

### Supported View Types
Based on `/Users/like-a-rolling_stone/resource/SwiftJsonUI/Sources/SwiftJsonUI/Classes/UIKit/UI/SJUIViewCreator.swift`:

1. **View** / **SafeAreaView** - Basic container view
2. **GradientView** - View with gradient background
3. **Blur** - Blur effect view (UIVisualEffectView)
4. **CircleView** - Circular view
5. **Scroll** - Scrollable view (UIScrollView)
6. **Table** - Table view (UITableView)
7. **Collection** - Collection view (UICollectionView)
8. **Segment** - Segmented control
9. **Label** - Text label
10. **IconLabel** - Label with icon
11. **Button** - Button control
12. **Image** - Image view
13. **NetworkImage** - Network loaded image
14. **CircleImage** - Circular image view
15. **Web** - Web view (WKWebView)
16. **TextField** - Single line text input
17. **TextView** - Multi-line text input
18. **Switch** - Toggle switch
19. **Radio** - Radio button
20. **Check** - Checkbox
21. **Progress** - Progress bar
22. **Slider** - Slider control
23. **SelectBox** - Dropdown/picker selection
24. **Indicator** - Activity indicator

### UIKit Attributes

#### Common Attributes (All Views)
- `id` - View identifier
- `type` - View type
- `width` - Width (matchParent, wrapContent, or numeric value)
- `height` - Height (matchParent, wrapContent, or numeric value)
- `visibility` - Control view visibility
- `canTap` - Enable/disable tap interactions
- `background` - Background color
- `defaultBackground` - Default background color
- `disabledBackground` - Background color when disabled
- `highlightBackground` - Background color when highlighted
- `cornerRadius` - Corner radius
- `borderColor` - Border color
- `borderWidth` - Border width
- `clipToBounds` - Clip content to bounds
- `alpha` - Transparency (0.0-1.0)
- `userInteractionEnabled` - Enable user interaction
- `onclick` - Click event handler
- `onLongPress` - Long press event handler
- `events` - Event handlers array
- `bindingScript` - Custom binding script

**Layout Constraints:**
- `topMargin`, `rightMargin`, `bottomMargin`, `leftMargin` - Margins
- `widthWeight`, `heightWeight` - Weight for weighted layouts
- `compressHorizontal`, `compressVertical` - Content compression resistance
- `hugHorizontal`, `hugVertical` - Content hugging priority

#### View/SafeAreaView Specific
- `orientation` - Layout orientation (vertical, horizontal)
- `direction` - Stack direction (topToBottom, leftToRight, etc.)
- `safeAreaInsetPositions` - Safe area positions array
- `highlighted` - Highlighted state
- `touchDisabledState` - Touch disabled state
- `touchEnabledViewIds` - Enabled view IDs when touch disabled
- `gradient` - Gradient colors array (GradientView)
- `gradientDirection` - Gradient direction (GradientView)
- `locations` - Gradient stop locations (GradientView)

#### Label Specific
- `text` - Label text
- `font` - Font name
- `fontSize` - Font size (default: 14.0)
- `fontColor` - Text color
- `highlightColor` - Highlight text color
- `highlightAttributes` - Highlight text attributes
- `hintColor` - Hint text color
- `hint` - Hint text
- `hintAttributes` - Hint text attributes
- `textAlign` - Text alignment (left, center, right)
- `lines` - Number of lines (0 for unlimited)
- `lineBreakMode` - Line break mode
- `lineHeightMultiple` - Line height multiplier
- `underline` - Underline style
- `strikethrough` - Strikethrough style
- `autoShrink` - Auto shrink text
- `minimumScaleFactor` - Minimum scale factor for auto shrink
- `textShadow` - Text shadow
- `partialAttributes` - Partial text attributes with ranges
- `edgeInset` - Edge insets
- `linkable` - Make URLs/phone numbers clickable
- `selected` - Selected state

#### Button Specific
- `text` - Button text
- `font` - Font name
- `fontSize` - Font size (default: 17.0)
- `fontColor` - Text color
- `hilightColor` - Highlight text color
- `disabledFontColor` - Text color when disabled
- `enabled` - Enabled state
- `image` - Button image
- `config` - Button configuration (iOS 15+)

#### TextField Specific
- `text` - Input text
- `hint` - Placeholder text
- `hintColor` - Placeholder color
- `hintFont` - Placeholder font
- `hintFontSize` - Placeholder font size
- `hintLineHeightMultiple` - Placeholder line height
- `font` - Font name
- `fontSize` - Font size
- `fontColor` - Text color
- `textAlign` - Text alignment
- `textVerticalAlign` - Vertical alignment
- `borderStyle` - Border style
- `borderColor` - Border color
- `borderWidth` - Border width
- `cornerRadius` - Corner radius
- `textPaddingLeft` - Left padding
- `textPaddingRight` - Right padding
- `fieldPadding` - Field padding
- `tintColor` - Tint color
- `secure` - Secure text entry
- `contentType` - Content type for autofill
- `input` - Input type (number, email, etc.)
- `returnKeyType` - Return key type
- `enabled` - Enabled state
- `onTextChange` - Text change handler
- `accessoryBackground` - Accessory view background
- `accessoryTextColor` - Accessory text color
- `doneText` - Done button text

#### TextView Specific
- Similar to TextField plus:
- Multi-line text input support
- All TextField attributes apply

#### Image/CircleImage Specific
- `src` - Image source
- `highlightSrc` - Highlight image source
- `contentMode` - Content mode (fit, fill, center, etc.)

#### NetworkImage Specific
- `url` - Image URL
- `contentMode` - Content mode
- All Image attributes apply

#### ScrollView Specific
- `showsHorizontalScrollIndicator` - Show horizontal indicator
- `showsVerticalScrollIndicator` - Show vertical indicator
- `contentInsetAdjustmentBehavior` - Content inset adjustment
- `maxZoom` - Maximum zoom scale
- `minZoom` - Minimum zoom scale
- `paging` - Enable paging
- `bounces` - Enable bounce
- `scrollEnabled` - Enable scrolling
- `keyboardAvoidance` - Enable keyboard avoidance

#### Switch Specific
- `onValueChange` - Value change handler
- `tint` - Tint color
- `on` - Switch state (for binding)

#### Radio Specific
- `check` - Checked state
- Similar to Check/Checkbox

#### Check (Checkbox) Specific
- `check` - Checked state
- `onclick` - Click handler

#### SelectBox Specific
- `selectItemType` - Item type (normal, date, etc.)
- `datePickerMode` - Date picker mode
- `datePickerStyle` - Picker style
- `minuteInterval` - Minute interval for time picker
- `selectedIndex` - Selected index
- `selectedDate` - Selected date
- `dateStringFormat` - Date format string
- `dateFormat` - Display date format
- `maximumDate` - Maximum selectable date
- `minimumDate` - Minimum selectable date
- `prompt` - Prompt text
- `canBack` - Can go back
- `includePromptWhenDataBinding` - Include prompt in binding
- `items` - Items array
- `inView` - Container view ID
- `referenceView` - Reference view ID
- `caretAttributes` - Caret customization
- `dividerAttributes` - Divider customization
- `labelAttributes` - Label customization

#### Segment Specific
- `items` - Segment items array
- `selectedIndex` - Selected segment index
- `tintColor` - Tint color

#### Progress Specific
- `tintColor` - Progress tint color
- `progress` - Progress value (0.0-1.0)

#### Slider Specific
- `tintColor` - Slider tint color
- `value` - Slider value
- `minimumValue` - Minimum value
- `maximumValue` - Maximum value

#### Indicator Specific
- `indicatorStyle` - Style (medium, large)
- `hidesWhenStopped` - Hide when stopped
- `startAnimating` - Start animating

#### Table/Collection Specific
- Complex attributes for table/collection views
- Cell configuration
- Data source binding
- Refresh handlers

---

## SwiftUI Mode

### Supported View Types
Based on `/Users/like-a-rolling_stone/resource/SwiftJsonUI/sjui_tools/lib/swiftui/converter_factory.rb`:

1. **Label** / **Text**
2. **IconLabel**
3. **Button**
4. **View** / **SafeAreaView**
5. **GradientView**
6. **Blur** / **BlurView**
7. **TextField**
8. **Image** / **CircleImage**
9. **NetworkImage**
10. **Scroll** / **ScrollView**
11. **TextView**
12. **Switch** / **Toggle**
13. **Check** / **Checkbox**
14. **Radio**
15. **Segment**
16. **Progress**
17. **Slider**
18. **Indicator**
19. **Table**
20. **Collection**
21. **SelectBox**
22. **Web** / **WebView**
23. **DynamicComponent**
24. **Include**
25. **TabView**

### SwiftUI Attributes

#### Common Attributes (All Views)
From `base_view_converter.rb`:

**Layout & Size:**
- `width` - Width (matchParent, wrapContent, or value)
- `height` - Height (matchParent, wrapContent, or value)
- `minWidth` - Minimum width
- `maxWidth` - Maximum width
- `minHeight` - Minimum height
- `maxHeight` - Maximum height

**Alignment:**
- `centerHorizontal` - Center horizontally
- `centerVertical` - Center vertically
- `alignTop` - Align to top
- `alignBottom` - Align to bottom
- `alignLeft` - Align to left
- `alignRight` - Align to right
- `alignParentTop` - Align to parent top
- `alignParentBottom` - Align to parent bottom
- `alignParentLeft` - Align to parent left
- `alignParentRight` - Align to parent right

**Spacing:**
- `padding` - Inner padding (array or single value)
- `paddingTop` - Top padding
- `paddingBottom` - Bottom padding
- `paddingLeft` - Left padding
- `paddingRight` - Right padding
- `paddingHorizontal` - Horizontal padding
- `paddingVertical` - Vertical padding
- `margin` - Outer margin (array or single value)
- `marginTop` - Top margin
- `marginBottom` - Bottom margin
- `marginLeft` - Left margin
- `marginRight` - Right margin
- `marginHorizontal` - Horizontal margin
- `marginVertical` - Vertical margin
- `insets` - Safe area insets
- `insetHorizontal` - Horizontal safe area insets

**Appearance:**
- `background` - Background color
- `disabledBackground` - Background color when disabled
- `cornerRadius` - Corner radius
- `borderWidth` - Border width
- `borderColor` - Border color
- `alpha` / `opacity` - Transparency (0.0-1.0)
- `shadow` - Shadow (boolean or object with radius, offsetX, offsetY, color)
- `clipToBounds` - Clip to bounds
- `enabled` - Enable/disable state

**Visibility:**
- `visibility` - Visibility control (visible, invisible, gone)
- `visibleIf` - Conditional visibility binding

**Relative Positioning:**
- `above` - Position above another view
- `below` - Position below another view  
- `toLeftOf` - Position to left of another view
- `toRightOf` - Position to right of another view
- `alignTop` - Align top with another view
- `alignBottom` - Align bottom with another view
- `alignBaseline` - Align baseline with another view

**Other:**
- `id` - View identifier
- `include` - Include another layout
- `shared_data` - Shared data for includes
- `data` - Local data for includes
- `variables` - Variables for template processing
- `style` - Apply predefined style
- `tag` - View tag
- `zIndex` - Z-order index
- `rotationAngle` - Rotation angle
- `scaleX` - X-axis scale
- `scaleY` - Y-axis scale

#### View/Container Specific
- `orientation` - Layout orientation (vertical, horizontal)
- `distribution` - Stack distribution
- `spacing` - Spacing between child views
- `child` - Child views array
- `ignoresSafeArea` - Ignore safe area

#### Text/Label Specific
- `text` - Text content
- `font` - Font name
- `fontSize` - Font size
- `fontColor` - Text color
- `fontWeight` - Font weight
- `italic` - Italic style
- `underline` - Underline style
- `strikethrough` - Strikethrough style
- `lineLimit` - Maximum lines
- `lineBreakMode` - Line break mode
- `textAlign` - Text alignment
- `multilineTextAlignment` - Multiline text alignment
- `lineHeightMultiple` - Line height multiplier
- `linkable` - Make text links clickable
- `partialAttributes` - Partial text styling

#### Button Specific
- `text` - Button text
- `onclick` - Click action
- `buttonStyle` - Button style
- `role` - Button role (destructive, cancel)

#### TextField Specific
- `text` - Input text binding
- `placeholder` - Placeholder text
- `onTextChanged` - Text change handler
- `onEditingChanged` - Editing state change handler
- `onCommit` - Commit handler
- `keyboardType` - Keyboard type
- `textFieldStyle` - Text field style
- `isSecure` - Secure text entry

#### Image Specific
- `src` - Image source
- `contentMode` - Content mode (fit, fill, etc.)
- `renderingMode` - Rendering mode
- `resizable` - Make image resizable

#### Toggle/Switch Specific
- `isOn` - Toggle state binding
- `onValueChanged` - Value change handler

#### Progress Specific
- `progress` - Progress value (0.0-1.0)
- `progressViewStyle` - Progress view style

#### Slider Specific
- `value` - Slider value binding
- `minValue` - Minimum value
- `maxValue` - Maximum value
- `step` - Step value
- `onEditingChanged` - Editing change handler

#### Segment Specific
- `items` - Segment items array
- `selectedIndex` - Selected index binding
- `onValueChanged` - Selection change handler

#### ScrollView Specific
- `axis` - Scroll axis (vertical, horizontal, both)
- `showsIndicators` - Show scroll indicators

#### Table/Collection Specific
- `items` - Data source binding
- `cellHeight` - Cell height
- `cellWidth` - Cell width (Collection)
- `columns` - Number of columns (Collection)
- `spacing` - Cell spacing
- `onItemClick` - Item click handler
- `onRefresh` - Pull to refresh handler

#### Web Specific
- `url` - Web URL
- `html` - HTML content

#### TabView Specific
- `tabs` - Tab items array
- `selectedTab` - Selected tab binding

## Binding Support

Both modes support data binding using the `@{propertyName}` syntax for dynamic values.

### UIKit Binding
- Handled through specific binding handlers for each view type
- Updates are managed through reset mechanisms for text and constraints

### SwiftUI Binding
- Integrated with SwiftUI's native binding system
- Uses `@State`, `@Binding`, and `@ObservedObject` properties
- Supports two-way binding for interactive components

## Style System

Both modes support a style system where common attribute sets can be defined and reused:
- Styles are defined in JSON files in the `Styles/` directory
- Applied using the `style` attribute
- Styles are merged with inline attributes (inline takes precedence)