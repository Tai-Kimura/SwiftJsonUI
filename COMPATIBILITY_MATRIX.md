# SwiftJsonUI Compatibility Matrix

## View Types Support

| View Type | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| **Container Views** |
| View | ✅ | ✅ | Basic container |
| SafeAreaView | ✅ | ✅ | Container with safe area support |
| GradientView | ✅ | ✅ | View with gradient background |
| CircleView | ✅ | ❌ | Circular container (UIKit only) |
| **Scroll Views** |
| Scroll/ScrollView | ✅ | ✅ | Scrollable container |
| **Text Display** |
| Label | ✅ | ✅ | Text display (SwiftUI accepts as Text) |
| Text | ❌ | ✅ | SwiftUI text display |
| IconLabel | ✅ | ✅ | Label with icon |
| **Input Controls** |
| Button | ✅ | ✅ | Button control |
| TextField | ✅ | ✅ | Single-line text input |
| TextView | ✅ | ✅ | Multi-line text input |
| Switch | ✅ | ✅ | Toggle switch (SwiftUI accepts as Toggle) |
| Toggle | ❌ | ✅ | SwiftUI toggle |
| Check/Checkbox | ✅ | ✅ | Checkbox control |
| Radio | ✅ | ✅ | Radio button |
| Slider | ✅ | ✅ | Slider control |
| Segment | ✅ | ✅ | Segmented control |
| SelectBox | ✅ | ✅ | Dropdown/picker |
| **Media** |
| Image | ✅ | ✅ | Image view |
| CircleImage | ✅ | ✅ | Circular image |
| NetworkImage | ✅ | ✅ | Network-loaded image |
| Web/WebView | ✅ | ✅ | Web content view |
| **Progress Indicators** |
| Progress | ✅ | ✅ | Progress bar |
| Indicator | ✅ | ✅ | Activity indicator |
| **Collection Views** |
| Table | ✅ | ✅ | Table view |
| Collection | ✅ | ✅ | Collection/grid view |
| **Effects** |
| Blur/BlurView | ✅ | ✅ | Blur effect |
| **Navigation** |
| TabView | ❌ | ✅ | Tab navigation (SwiftUI only) |
| **Dynamic** |
| DynamicComponent | ❌ | ✅ | Dynamic component (SwiftUI only) |
| Include | ❌ | ✅ | Layout inclusion (SwiftUI only) |

## Attributes Support

### Layout & Positioning

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| **Size** |
| width | ✅ | ✅ | Width (matchParent, wrapContent, or value) |
| height | ✅ | ✅ | Height (matchParent, wrapContent, or value) |
| minWidth | ✅ | ✅ | Minimum width |
| maxWidth | ✅ | ✅ | Maximum width |
| minHeight | ✅ | ✅ | Minimum height |
| maxHeight | ✅ | ✅ | Maximum height |
| **Margins (External Spacing)** |
| margin | ❌ | ✅ | All margins (array or single value) |
| margins | ✅ | ✅ | Margin array format |
| topMargin | ✅ | ✅ | Top margin |
| rightMargin | ✅ | ✅ | Right margin |
| bottomMargin | ✅ | ✅ | Bottom margin |
| leftMargin | ✅ | ✅ | Left margin |
| marginHorizontal | ❌ | ✅ | Horizontal margins |
| marginVertical | ❌ | ✅ | Vertical margins |
| **Padding (Internal Spacing)** |
| padding | ❌ | ✅ | All padding (array or single value) |
| paddings | ✅ | ✅ | Padding array format |
| paddingTop | ✅ | ✅ | Top padding |
| paddingBottom | ✅ | ✅ | Bottom padding |
| paddingLeft | ✅ | ✅ | Left padding |
| paddingRight | ✅ | ✅ | Right padding |
| leftPadding | ✅ | ❌ | Alternative left padding |
| rightPadding | ✅ | ❌ | Alternative right padding |
| topPadding | ✅ | ❌ | Alternative top padding |
| bottomPadding | ✅ | ❌ | Alternative bottom padding |
| minLeftPadding | ✅ | ❌ | Minimum left padding |
| minRightPadding | ✅ | ❌ | Minimum right padding |
| minTopPadding | ✅ | ❌ | Minimum top padding |
| minBottomPadding | ✅ | ❌ | Minimum bottom padding |
| maxLeftPadding | ✅ | ❌ | Maximum left padding |
| maxRightPadding | ✅ | ❌ | Maximum right padding |
| maxTopPadding | ✅ | ❌ | Maximum top padding |
| maxBottomPadding | ✅ | ❌ | Maximum bottom padding |
| paddingHorizontal | ❌ | ✅ | Horizontal padding |
| paddingVertical | ❌ | ✅ | Vertical padding |
| **Weight System** |
| widthWeight | ✅ | ❌ | Width weight for weighted layouts |
| heightWeight | ✅ | ❌ | Height weight for weighted layouts |
| weight | ❌ | ✅ | SwiftUI weight system |
| **Content Priority** |
| compressHorizontal | ✅ | ❌ | Content compression resistance |
| compressVertical | ✅ | ❌ | Content compression resistance |
| hugHorizontal | ✅ | ❌ | Content hugging priority |
| hugVertical | ✅ | ❌ | Content hugging priority |

### Alignment

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| centerHorizontal | ✅ | ✅ | Center horizontally |
| centerVertical | ✅ | ✅ | Center vertically |
| centerInParent | ✅ | ❌ | Center in parent |
| alignTop | ✅ | ✅ | Align to parent top (UIKit) / Align to top (SwiftUI) |
| alignBottom | ✅ | ✅ | Align to parent bottom (UIKit) / Align to bottom (SwiftUI) |
| alignLeft | ✅ | ✅ | Align to parent left (UIKit) / Align to left (SwiftUI) |
| alignRight | ✅ | ✅ | Align to parent right (UIKit) / Align to right (SwiftUI) |
| alignParentTop | ❌ | ✅ | Align to parent top (same as alignTop in UIKit) |
| alignParentBottom | ❌ | ✅ | Align to parent bottom (same as alignBottom in UIKit) |
| alignParentLeft | ❌ | ✅ | Align to parent left (same as alignLeft in UIKit) |
| alignParentRight | ❌ | ✅ | Align to parent right (same as alignRight in UIKit) |

### Relative Positioning

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| above | ❌ | ✅ | Position above another view |
| below | ❌ | ✅ | Position below another view |
| toLeftOf | ❌ | ✅ | Position to left of another view |
| toRightOf | ❌ | ✅ | Position to right of another view |
| alignTopView | ✅ | ✅ | Align top with another view |
| alignBottomView | ✅ | ✅ | Align bottom with another view |
| alignLeftView | ✅ | ✅ | Align left with another view |
| alignRightView | ✅ | ✅ | Align right with another view |
| alignCenterVerticalView | ✅ | ✅ | Center vertically with another view |
| alignCenterHorizontalView | ✅ | ✅ | Center horizontally with another view |
| alignTopOfView | ✅ | ✅ | Position above another view (same as `above`) |
| alignBottomOfView | ✅ | ✅ | Position below another view (same as `below`) |
| alignLeftOfView | ✅ | ✅ | Position to left of another view (same as `toLeftOf`) |
| alignRightOfView | ✅ | ✅ | Position to right of another view (same as `toRightOf`) |
| alignBaseline | ❌ | ✅ | Align baseline with another view |

### Appearance

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| **Colors** |
| background | ✅ | ✅ | Background color |
| defaultBackground | ✅ | ❌ | Default background color |
| disabledBackground | ✅ | ✅ | Background when disabled |
| highlightBackground | ✅ | ❌ | Background when highlighted |
| tapBackground | ✅ | ✅ | Background when tapped |
| **Border & Corner** |
| cornerRadius | ✅ | ✅ | Corner radius |
| borderColor | ✅ | ✅ | Border color |
| borderWidth | ✅ | ✅ | Border width |
| **Transparency** |
| alpha | ✅ | ✅ | Transparency (SwiftUI also accepts opacity) |
| opacity | ❌ | ✅ | Transparency (SwiftUI preferred) |
| **Shadow** |
| shadow | ✅ | ✅ | Shadow effect |
| textShadow | ✅ | ❌ | Text shadow |
| **Other** |
| clipToBounds | ✅ | ✅ | Clip content to bounds |
| zIndex | ❌ | ✅ | Z-order index |
| rotationAngle | ❌ | ✅ | Rotation angle |
| scaleX | ❌ | ✅ | X-axis scale |
| scaleY | ❌ | ✅ | Y-axis scale |

### Text Attributes

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| **Basic Text** |
| text | ✅ | ✅ | Text content |
| font | ✅ | ✅ | Font name |
| fontSize | ✅ | ✅ | Font size |
| fontColor | ✅ | ✅ | Text color |
| fontWeight | ❌ | ✅ | Font weight |
| **Text Style** |
| italic | ❌ | ✅ | Italic style |
| underline | ✅ | ✅ | Underline style |
| strikethrough | ✅ | ✅ | Strikethrough style |
| **Text Layout** |
| textAlign | ✅ | ✅ | Text alignment |
| lines | ✅ | ✅ | Number of lines (SwiftUI: lineLimit) |
| lineBreakMode | ✅ | ✅ | Line break mode |
| lineHeightMultiple | ✅ | ✅ | Line height multiplier |
| lineSpacing | ❌ | ✅ | Line spacing |
| multilineTextAlignment | ❌ | ✅ | Multiline text alignment |
| **Text Features** |
| autoShrink | ✅ | ✅ | Auto shrink text |
| minimumScaleFactor | ✅ | ✅ | Minimum scale factor |
| linkable | ✅ | ✅ | Make URLs/phones clickable |
| partialAttributes | ✅ | ✅ | Partial text styling |
| edgeInset | ✅ | ✅ | Text edge insets |
| **Highlight/Hint** |
| highlightColor | ✅ | ✅ | Highlight text color |
| highlightAttributes | ✅ | ❌ | Highlight text attributes |
| hint | ✅ | ✅ | Placeholder text |
| hintColor | ✅ | ✅ | Placeholder color |
| hintAttributes | ✅ | ❌ | Placeholder attributes |
| hintFont | ✅ | ❌ | Placeholder font |
| hintFontSize | ✅ | ❌ | Placeholder font size |
| hintLineHeightMultiple | ✅ | ❌ | Placeholder line height |

### Button Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| text | ✅ | ✅ | Button text |
| onclick | ✅ | ✅ | Click handler |
| onLongPress | ✅ | ❌ | Long press handler |
| image | ✅ | ✅ | Button image |
| enabled | ✅ | ✅ | Enabled state |
| disabledFontColor | ✅ | ✅ | Text color when disabled |
| config | ✅ | ❌ | Button configuration (iOS 15+) |
| buttonStyle | ❌ | ✅ | SwiftUI button style |
| role | ❌ | ✅ | Button role (destructive, cancel) |

### TextField/TextView Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| text | ✅ | ✅ | Input text |
| hint | ✅ | ✅ | Placeholder (SwiftUI also accepts placeholder) |
| secure | ✅ | ✅ | Secure text entry |
| input | ✅ | ✅ | Input type (number, email, etc.) |
| contentType | ✅ | ✅ | Content type for autofill |
| returnKeyType | ✅ | ❌ | Return key type |
| borderStyle | ✅ | ✅ | Border style |
| textPaddingLeft | ✅ | ✅ | Left padding |
| textPaddingRight | ✅ | ❌ | Right padding |
| fieldPadding | ✅ | ❌ | Field padding |
| textVerticalAlign | ✅ | ❌ | Vertical alignment |
| onTextChange | ✅ | ✅ | Text change handler |
| onEditingChanged | ❌ | ✅ | Editing state change handler |
| onCommit | ❌ | ✅ | Commit handler |
| keyboardType | ❌ | ✅ | Keyboard type |
| textFieldStyle | ❌ | ✅ | Text field style |
| accessoryBackground | ✅ | ❌ | Accessory view background |
| accessoryTextColor | ✅ | ❌ | Accessory text color |
| doneText | ✅ | ❌ | Done button text |

### Image Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| src | ✅ | ✅ | Image source |
| highlightSrc | ✅ | ❌ | Highlight image source |
| url | ✅ | ✅ | Network image URL |
| contentMode | ✅ | ✅ | Content mode |
| renderingMode | ✅ | ✅ | Rendering mode |
| resizable | ❌ | ✅ | Make image resizable |

### Toggle/Switch Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| on | ✅ | ❌ | Switch state (UIKit) |
| isOn | ❌ | ✅ | Toggle state (SwiftUI) |
| onValueChange | ✅ | ✅ | Value change handler |
| tint | ✅ | ❌ | Tint color |

### ScrollView Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| showsHorizontalScrollIndicator | ✅ | ✅ | Show horizontal indicator |
| showsVerticalScrollIndicator | ✅ | ✅ | Show vertical indicator |
| contentInsetAdjustmentBehavior | ✅ | ❌ | Content inset adjustment |
| maxZoom | ✅ | ❌ | Maximum zoom scale |
| minZoom | ✅ | ❌ | Minimum zoom scale |
| paging | ✅ | ❌ | Enable paging |
| bounces | ✅ | ❌ | Enable bounce |
| scrollEnabled | ✅ | ❌ | Enable scrolling |
| keyboardAvoidance | ✅ | ✅ | Keyboard avoidance |
| axis | ❌ | ✅ | Scroll axis |

### Progress/Slider Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| progress | ✅ | ✅ | Progress value |
| value | ✅ | ✅ | Slider value |
| minValue | ✅ | ✅ | Minimum value |
| maxValue | ✅ | ✅ | Maximum value |
| step | ❌ | ✅ | Step value |
| tintColor | ✅ | ❌ | Tint color |
| progressViewStyle | ❌ | ✅ | Progress view style |

### SelectBox Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| items | ✅ | ✅ | Items array |
| selectedIndex | ✅ | ✅ | Selected index |
| selectedDate | ✅ | ❌ | Selected date |
| selectedItem | ✅ | ❌ | Selected item |
| prompt | ✅ | ❌ | Prompt text |
| selectItemType | ✅ | ❌ | Item type |
| datePickerMode | ✅ | ❌ | Date picker mode |
| datePickerStyle | ✅ | ❌ | Picker style |
| dateStringFormat | ✅ | ❌ | Date format string |
| dateFormat | ✅ | ❌ | Display date format |
| maximumDate | ✅ | ❌ | Maximum selectable date |
| minimumDate | ✅ | ❌ | Minimum selectable date |
| minuteInterval | ✅ | ❌ | Minute interval |
| canBack | ✅ | ❌ | Can go back |
| includePromptWhenDataBinding | ✅ | ❌ | Include prompt in binding |
| inView | ✅ | ❌ | Container view ID |
| referenceView | ✅ | ❌ | Reference view ID |
| caretAttributes | ✅ | ❌ | Caret customization |
| dividerAttributes | ✅ | ❌ | Divider customization |
| labelAttributes | ✅ | ❌ | Label customization |

### Table/Collection Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| items | ✅ | ✅ | Data source |
| cellHeight | ✅ | ✅ | Cell height |
| cellWidth | ✅ | ✅ | Cell width |
| columns | ✅ | ✅ | Number of columns |
| spacing | ✅ | ✅ | Cell spacing |
| onItemClick | ✅ | ✅ | Item click handler |
| onRefresh | ✅ | ✅ | Pull to refresh handler |

### Segment Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| items | ✅ | ✅ | Segment items |
| selectedIndex | ✅ | ✅ | Selected segment |
| tintColor | ✅ | ❌ | Tint color |
| onValueChanged | ✅ | ✅ | Selection change handler |

### Container Specific

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| orientation | ✅ | ✅ | Layout orientation (vertical/horizontal) |
| direction | ✅ | ❌ | Stack direction |
| distribution | ❌ | ✅ | Stack distribution |
| spacing | ❌ | ✅ | Spacing between children |
| child | ✅ | ✅ | Child views array |
| safeAreaInsetPositions | ✅ | ❌ | Safe area positions |
| ignoresSafeArea | ❌ | ✅ | Ignore safe area |
| gradient | ✅ | ❌ | Gradient colors (GradientView) |
| gradientDirection | ✅ | ❌ | Gradient direction |
| locations | ✅ | ❌ | Gradient stop locations |

### Visibility & State

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| visibility | ✅ | ✅ | Visibility control |
| visibleIf | ❌ | ✅ | Conditional visibility |
| hidden | ❌ | ✅ | Hidden state |
| enabled | ✅ | ✅ | Enabled state |
| selected | ✅ | ❌ | Selected state |
| highlighted | ✅ | ❌ | Highlighted state |
| userInteractionEnabled | ✅ | ❌ | User interaction enabled |
| canTap | ✅ | ❌ | Tap enabled |
| touchDisabledState | ✅ | ❌ | Touch disabled state |
| touchEnabledViewIds | ✅ | ❌ | Enabled view IDs |

### Events

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| onclick | ✅ | ✅ | Click/tap handler |
| onLongPress | ✅ | ❌ | Long press handler |
| onPan | ✅ | ❌ | Pan gesture handler |
| onPinch | ✅ | ❌ | Pinch gesture handler |
| events | ✅ | ❌ | Event handlers array |

### Other

| Attribute | UIKit | SwiftUI | Notes |
|-----------|:-----:|:-------:|-------|
| id | ✅ | ✅ | View identifier |
| tag | ❌ | ✅ | View tag |
| style | ✅ | ✅ | Apply predefined style |
| include | ✅ | ✅ | Include another layout |
| shared_data | ❌ | ✅ | Shared data for includes |
| data | ❌ | ✅ | Local data for includes |
| variables | ❌ | ✅ | Template variables |
| bindingScript | ✅ | ❌ | Custom binding script |

## Legend

- ✅ : Supported
- ❌ : Not supported
- UIKit : Static mode (UIKit-based)
- SwiftUI : Dynamic mode (SwiftUI-based)

## Notes

1. **SwiftUI Compatibility Mode**: SwiftUI mode often accepts UIKit naming conventions for easier migration (e.g., accepts both `Label` and `Text`, `hint` and `placeholder`)

2. **Layout System Differences**: 
   - UIKit uses constraint-based layout with weights and compression/hugging priorities
   - SwiftUI uses declarative layout with frame modifiers and spacers

3. **Binding System**:
   - Both modes support `@{propertyName}` syntax for data binding
   - UIKit handles bindings through manual handlers
   - SwiftUI integrates with native `@State`, `@Binding`, and `@ObservedObject`

4. **Style System**: Both modes support JSON-based style definitions that can be reused across views

5. **Platform-Specific Features**:
   - Some UIKit features require iOS 15+ (e.g., button configuration)
   - SwiftUI features generally require iOS 14+ or 15+