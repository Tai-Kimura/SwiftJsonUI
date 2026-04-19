# JsonUI Attribute Comparison: SJUI vs KJUI vs RJUI

This document compares attributes across SwiftJsonUI (SJUI), KotlinJsonUI (KJUI), and ReactJsonUI (RJUI).

Legend:
- **O** = Supported
- **-** = Not supported
- **B** = Supports data binding (`@{propertyName}` format)
- **2W** = Two-way binding (for input components)
- **uikit** = UIKit mode only (SJUI)
- **xml** = XML mode only (KJUI)
- **react** = React mode only (RJUI)

---

## Common Attributes

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| id | O | O | O | - | |
| type | O | O | O | - | Required |
| width | O | O | O | B | |
| height | O | O | O | B | |
| minWidth | O | O | O | B | |
| maxWidth | O | O | O | B | |
| minHeight | O | O | O | B | |
| maxHeight | O | O | O | B | |
| widthWeight | O | - | O | B (uikit) | KJUI uses `weight` only |
| heightWeight | O | - | O | B (uikit) | KJUI uses `weight` only |
| maxWidthWeight | uikit | - | - | - | |
| maxHeightWeight | uikit | - | - | - | |
| minWidthWeight | uikit | - | - | - | |
| minHeightWeight | uikit | - | - | - | |
| aspectWidth | uikit | xml | - | - | |
| aspectHeight | uikit | xml | - | - | |
| weight | O | O | O | - | |
| background | O | O | O | B | |
| tapBackground | O | - | O | - | |
| highlightBackground | O | - | O | - | |
| disabledBackground | O | - | O | B (uikit) | |
| defaultBackground | uikit | - | - | B | SJUI UIKit only |
| cornerRadius | O | O | O | B | |
| borderWidth | O | O | O | B | |
| borderColor | O | O | O | B | |
| alpha | O | O | O | B | |
| opacity | O | O | O | B | Alias for alpha |
| visibility | O | O | O | B | enum: visible, invisible, gone |
| hidden | O | O | O | B | |
| paddings | O | O | O | - | |
| padding | O | O | O | - | Alias for paddings |
| paddingTop | O | O | O | B | |
| paddingBottom | O | O | O | B | |
| paddingLeft | O | O | O | B | |
| paddingRight | O | O | O | B | |
| paddingStart | O | O | O | B | RTL aware |
| paddingEnd | O | O | O | B | RTL aware |
| paddingVertical | - | O | - | - | KJUI only |
| paddingHorizontal | - | O | - | - | KJUI only |
| minTopPadding | uikit | - | - | - | |
| minBottomPadding | uikit | - | - | - | |
| minLeftPadding | uikit | - | - | - | |
| minRightPadding | uikit | - | - | - | |
| maxTopPadding | uikit | - | - | - | |
| maxBottomPadding | uikit | - | - | - | |
| maxLeftPadding | uikit | - | - | - | |
| maxRightPadding | uikit | - | - | - | |
| margins | O | O | O | - | |
| topMargin | O | O | O | B | |
| bottomMargin | O | O | O | B | |
| leftMargin | O | O | O | B | |
| rightMargin | O | O | O | B | |
| startMargin | O | O | O | B | RTL aware |
| endMargin | O | O | O | B | RTL aware |
| minTopMargin | uikit | - | - | - | |
| minBottomMargin | uikit | - | - | - | |
| minLeftMargin | uikit | - | - | - | |
| minRightMargin | uikit | - | - | - | |
| maxTopMargin | uikit | - | - | - | |
| maxBottomMargin | uikit | - | - | - | |
| maxLeftMargin | uikit | - | - | - | |
| maxRightMargin | uikit | - | - | - | |
| centerInParent | O | - | O | - | |
| centerVertical | O | - | O | - | |
| centerHorizontal | O | - | O | - | |
| alignTop | O | - | O | - | |
| alignBottom | O | - | O | - | |
| alignLeft | O | - | O | - | |
| alignRight | O | - | O | - | |
| alignTopOfView | O | O | O | - | |
| alignBottomOfView | O | O | O | - | |
| alignLeftOfView | O | O | O | - | |
| alignRightOfView | O | O | O | - | |
| alignTopView | O | O | O | - | |
| alignBottomView | O | O | O | - | |
| alignLeftView | O | O | O | - | |
| alignRightView | O | O | O | - | |
| alignCenterVerticalView | O | O | O | - | |
| alignCenterHorizontalView | O | O | O | - | |
| toView | uikit | - | - | - | |
| shadow | O | O | O | - | KJUI: boolean/number, SJUI/RJUI: string/object |
| clipToBounds | O | - | O | B | |
| onclick | O | O | O | B | |
| onClick | O | O | O | B | camelCase version |
| onLongPress | O | - | O | B | RJUI: onContextMenu |
| onPan | O | - | - | B | |
| onPinch | O | - | - | B | |
| canTap | O | O | O | B | |
| tintColor | O | O | O | B | |
| binding | O | O | O | - | |
| bind | O | O | O | - | Alias |
| include | O | O | O | - | |
| variables | O | O | O | - | |
| shared_data | O | - | O | - | |
| style | uikit | - | react | - | SJUI: string, RJUI: object |
| compressHorizontal | uikit | - | - | - | |
| compressVertical | uikit | - | - | - | |
| hugHorizontal | uikit | - | - | - | |
| hugVertical | uikit | - | - | - | |
| propertyName | uikit | - | - | - | |
| binding_id | uikit | - | - | - | |
| binding_group | O | - | O | - | |
| wrapContent | uikit | - | - | - | |
| innerPadding | uikit | - | - | - | |
| keyBottomView | uikit | - | - | - | |
| keyTopView | uikit | - | - | - | |
| keyLeftView | uikit | - | - | - | |
| keyRightView | uikit | - | - | - | |
| scripts | uikit | - | - | - | |
| events | uikit | - | - | - | |
| effectStyle | uikit | - | - | - | |
| tag | uikit | - | - | - | |
| userInteractionEnabled | O | - | O | B | |
| enabled | O | O | O | B | |
| rect | uikit | - | - | - | |
| frame | O | - | - | - | |
| indexBelow | O | - | O | - | |
| indexAbove | O | - | O | - | |
| touchDisabledState | uikit | - | - | - | |
| touchEnabledViewIds | uikit | - | - | - | |
| data | O | - | O | - | |
| bindingScript | uikit | - | - | - | |
| className | - | - | react | - | CSS class |
| testId | - | - | react | - | data-testid |

---

## Label / Text

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| text | O | O | O | B | Supports interpolation |
| font | O | O | O | B (SJUI) | |
| fontSize | O | O | O | B (SJUI) | |
| fontColor | O | O | O | B | |
| fontWeight | - | O | O | - | |
| textAlign | O | O | O | - | |
| lines | O | O | O | - | |
| lineBreakMode | O | O | O | - | Different enum values |
| lineHeightMultiple | O | - | O | - | |
| lineHeight | - | O | O | - | |
| lineSpacing | O | - | O | - | |
| letterSpacing | - | O | - | - | KJUI only |
| edgeInset | O | O | O | - | |
| underline | O | O | O | - | SJUI/RJUI: boolean/object, KJUI: boolean |
| strikethrough | O | O | O | - | SJUI/RJUI: boolean/object, KJUI: boolean |
| autoShrink | O | - | O | - | |
| minimumScaleFactor | O | - | O | - | |
| linkable | O | O | O | - | |
| textShadow | O | - | O | - | |
| hint | O | - | O | - | |
| hintColor | O | - | O | B (uikit) | |
| highlightAttributes | O | - | O | - | |
| highlightColor | O | - | O | B (uikit) | |
| partialAttributes | O | O | O | B (uikit) | |
| hintAttributes | O | - | O | - | |
| selected | uikit | - | - | B | SJUI UIKit only |

---

## TextField

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| text | O | O | O | 2W | Two-way binding |
| hint | O | O | O | - | |
| placeholder | O | O | O | - | Alias for hint |
| hintColor | O | O | O | - | |
| hintFont | O | - | O | - | |
| hintFontSize | O | O | O | - | |
| font | O | O | O | - | |
| fontSize | O | O | O | - | |
| fontColor | O | O | O | - | |
| textAlign | O | O | O | - | |
| borderStyle | O | - | O | - | |
| input | O | O | O | - | |
| keyboardType | - | O | - | - | KJUI uses keyboardType, SJUI/RJUI use input |
| returnKeyType | O | O | O | - | |
| imeAction | - | O | - | - | KJUI only |
| contentType | O | - | O | B (uikit) | |
| secure | O | O | O | B | |
| fieldPadding | O | - | O | - | |
| textPaddingLeft | O | - | O | - | |
| textPaddingRight | O | - | O | - | uikit only in SJUI |
| hasContainer | uikit | - | - | - | |
| textVerticalAlign | uikit | - | - | - | |
| applyLiquidGlass | uikit | - | - | - | |
| accessoryCornerRadius | uikit | - | - | - | |
| glassEffectStyle | uikit | - | - | - | |
| accessoryBackground | O | - | - | - | |
| accessoryTextColor | O | - | - | - | |
| doneText | O | - | - | - | |
| onTextChange | O | O | O | - | Event handler |
| autocapitalizationType | O | - | O | - | |
| autocorrectionType | O | - | O | - | |
| spellCheckingType | O | - | - | - | |
| keyboardAppearance | O | - | - | - | |
| clearButtonMode | O | - | - | - | |
| leftView | uikit | - | - | - | |
| rightView | uikit | - | - | - | |
| leftViewMode | uikit | - | - | - | |
| rightViewMode | uikit | - | - | - | |
| maxLines | - | O | - | - | KJUI only |
| enabled | O | O | O | B | |
| disabled | - | O | - | - | KJUI only |
| outlined | - | O | - | - | KJUI only |
| bind | - | O | - | 2W | KJUI two-way binding |
| maxLength | - | - | react | - | RJUI only |
| pattern | - | - | react | - | RJUI only |
| required | - | - | react | - | RJUI only |

---

## TextView

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| text | O | O | O | 2W | Two-way binding |
| hint | O | O | O | - | |
| placeholder | O | O | O | - | |
| hintColor | O | O | O | - | |
| hintFont | O | - | O | - | |
| hintFontSize | O | O | O | - | |
| hintLineHeightMultiple | O | - | O | - | |
| hintAttributes | O | - | O | - | |
| hideOnFocused | O | - | - | - | |
| font | O | O | O | - | |
| fontSize | O | O | O | - | |
| fontColor | O | O | O | - | |
| textAlign | O | - | O | - | |
| containerInset | O | - | O | - | |
| flexible | O | - | O | - | |
| returnKeyType | O | - | O | - | |
| editable | O | - | O | - | |
| scrollEnabled | O | - | O | - | |
| lineBreakMode | O | - | O | - | |
| dataDetectorTypes | uikit | - | - | - | |
| allowsEditingTextAttributes | uikit | - | - | - | |
| keyboardType | O | - | O | - | |
| onTextChange | O | O | O | - | Event handler |
| maxLines | - | O | - | - | KJUI only |
| enabled | O | O | O | B | |
| disabled | - | O | - | - | KJUI only |
| outlined | - | O | - | - | KJUI only |
| bind | - | O | - | 2W | KJUI two-way binding |
| rows | - | - | react | - | RJUI only |
| cols | - | - | react | - | RJUI only |
| resize | - | - | react | - | RJUI only |

---

## Button

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| text | O | O | O | B | Supports interpolation |
| font | O | O | O | - | |
| fontSize | O | O | O | - | |
| fontColor | O | O | O | B (uikit) | |
| fontWeight | - | O | - | - | KJUI only |
| disabledFontColor | O | - | O | B (uikit) | |
| disabledTextColor | - | O | - | - | KJUI only |
| highlightColor | O | - | O | - | |
| hilightColor | O | - | O | - | Typo alias |
| tapBackground | O | - | O | - | |
| highlightBackground | O | - | O | - | |
| image | O | - | O | - | |
| config | uikit | - | - | - | iOS 15+ |
| enabled | - | O | - | B | KJUI only |
| disabled | - | O | - | - | KJUI only |
| async | - | O | - | - | KJUI only |
| isLoading | - | O | - | - | KJUI only |
| loadingText | - | O | - | - | KJUI only |
| disabledBackground | - | O | - | - | KJUI only |
| buttonType | - | - | react | - | HTML button type |

---

## Image

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| src | O | O | O | B | |
| srcName | O | - | O | B | Alias |
| highlightSrc | O | - | O | B (uikit) | |
| highlightSrcName | uikit | - | - | B | SJUI UIKit only |
| contentMode | O | O | O | B (uikit) | Different enum values |
| renderingMode | O | - | O | - | |
| contentDescription | - | O | - | - | KJUI only |
| size | - | O | - | - | KJUI only |
| tint | - | O | - | - | KJUI only |
| alt | - | - | react | - | RJUI only |
| loading | - | - | react | - | RJUI only |

---

## NetworkImage

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| src | O | O | O | B | |
| url | O | - | O | B | Alias |
| placeholder | O | O | O | - | |
| defaultImage | O | O | O | - | |
| errorImage | O | O | O | - | |
| loadingImage | O | - | O | - | |
| contentMode | O | O | O | B (uikit) | |
| cachePolicy | uikit | - | - | - | |
| timeout | uikit | - | - | - | |
| contentDescription | - | O | - | - | KJUI only |
| size | - | O | - | - | KJUI only |
| alt | - | - | react | - | RJUI only |
| loading | - | - | react | - | RJUI only |

---

## SelectBox

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| prompt | O | - | O | - | |
| hint | O | O | O | - | |
| placeholder | - | O | - | - | KJUI only |
| items | O | O | O | B | Template variable supported |
| options | - | O | - | B | KJUI alias |
| selectItemType | O | O | O | - | |
| selectedIndex | O | - | O | 2W | |
| selectedItem | uikit | O | - | 2W | SJUI UIKit / KJUI |
| selectedValue | - | - | O | B | RJUI only |
| selectedDate | O | - | O | 2W (uikit) | |
| datePickerMode | O | O | O | - | |
| datePickerStyle | O | O | - | - | |
| dateStringFormat | O | O | O | - | |
| dateFormat | - | O | - | - | KJUI alias |
| minimumDate | O | O | O | B (uikit) | |
| maximumDate | O | O | O | B (uikit) | |
| minuteInterval | O | O | - | - | |
| font | O | - | O | - | |
| fontSize | O | - | O | - | |
| fontColor | O | O | O | - | |
| hintColor | - | O | - | - | KJUI only |
| labelAttributes | O | - | O | - | |
| caretAttributes | uikit | - | - | - | |
| dividerAttributes | uikit | - | - | - | |
| canBack | uikit | - | - | - | |
| includePromptWhenDataBinding | uikit | - | - | - | |
| inView | uikit | - | - | - | |
| referenceView | uikit | - | - | - | |
| onValueChange | O | O | O | - | Event handler |
| bind | - | O | - | 2W | KJUI two-way binding |
| cancelButtonBackgroundColor | - | O | - | - | KJUI only |
| cancelButtonTextColor | - | O | - | - | KJUI only |
| multiple | - | - | react | - | RJUI only |
| size | - | - | react | - | RJUI only |

---

## Toggle / Switch

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| isOn | O | O | O | 2W | Two-way binding |
| value | O | - | O | 2W | Alias |
| checked | O | - | O | 2W | Alias |
| tint | O | - | O | - | |
| tintColor | O | - | O | - | Alias |
| onTintColor | - | O | - | - | KJUI only |
| thumbTintColor | O | O | O | - | |
| offTintColor | uikit | - | - | - | |
| onToggle | O | - | O | - | Event handler |
| onValueChange | O | O | O | - | Event handler |
| labelAttributes | O | - | O | - | |
| enabled | - | O | - | B | KJUI only |
| bind | - | O | - | 2W | KJUI two-way binding |

---

## Segment

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| items | O | O | O | - | Required |
| segments | - | O | - | - | KJUI alias |
| selectedIndex | O | O | O | 2W | Two-way binding |
| tintColor | O | - | O | - | |
| normalColor | O | - | O | - | |
| selectedColor | O | - | O | - | |
| valueChange | O | - | O | - | Event handler |
| onSelect | - | O | - | - | KJUI only |
| onValueChanged | - | - | O | - | RJUI only |
| bind | - | O | - | 2W | KJUI two-way binding |
| momentary | uikit | - | - | - | |
| apportionsSegmentWidthsByContent | uikit | - | - | - | |

---

## Slider

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| value | O | O | O | 2W | Two-way binding |
| minValue | O | - | O | - | |
| minimum | O | O | O | - | |
| minimumValue | - | O | - | - | KJUI alias |
| maxValue | O | - | O | - | |
| maximum | O | O | O | - | |
| maximumValue | - | O | - | - | KJUI alias |
| min | - | O | - | - | KJUI only |
| max | - | O | - | - | KJUI only |
| step | - | O | react | - | KJUI and RJUI |
| tintColor | O | - | O | - | |
| onValueChanged | O | - | O | - | Event handler |
| onValueChange | O | O | O | - | Event handler |
| bind | - | O | - | 2W | KJUI two-way binding |
| minimumValueImage | uikit | - | - | - | |
| maximumValueImage | uikit | - | - | - | |

---

## Progress

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| progress | O | O | O | B | |
| tintColor | O | O | O | - | |
| progressTintColor | O | - | O | - | |
| trackTintColor | O | - | O | - | |
| trackColor | - | O | - | - | KJUI only |
| progressViewStyle | uikit | - | - | - | |
| progressImage | uikit | - | - | - | |
| trackImage | uikit | - | - | - | |
| isCircular | - | O | - | - | KJUI only |

---

## View

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| orientation | O | O | O | - | |
| direction | O | O | O | - | Different enum values |
| child | O | O | O | - | |
| children | O | O | O | - | Alias |
| gravity | O | O | O | - | |
| alignment | O | - | O | - | |
| distribution | O | O | O | - | |
| spacing | O | O | O | - | |
| gradient | uikit | - | O | - | |
| gradientDirection | uikit | - | O | - | |
| locations | uikit | - | O | - | |
| safeAreaInsetPositions | O | - | - | - | |
| highlighted | O | - | O | - | |
| flexWrap | - | - | react | - | RJUI only |

---

## ScrollView

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| child | O | O | O | - | |
| children | O | O | O | - | |
| orientation | O | O | O | - | |
| showsHorizontalScrollIndicator | O | O | O | - | |
| showsVerticalScrollIndicator | O | O | O | - | |
| paging | O | - | O | - | |
| bounces | O | - | O | - | |
| scrollEnabled | O | O | O | B (uikit) | |
| contentInsetAdjustmentBehavior | O | - | - | - | |
| maxZoom | O | - | O | B (uikit) | |
| minZoom | O | - | O | B (uikit) | |
| contentSize | uikit | - | - | - | |
| contentOffset | uikit | - | - | - | |
| decelerationRate | uikit | - | - | - | |
| indicatorStyle | uikit | - | - | - | |
| keyboardDismissMode | O | - | - | - | |
| scrollsToTop | uikit | - | - | - | |
| horizontalScroll | - | O | - | - | KJUI only |
| scrollBehavior | - | - | react | - | RJUI only |

---

## Collection

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| cellClasses | O | O | O | - | |
| headerClasses | O | O | O | - | |
| footerClasses | O | O | O | - | |
| columns | O | O | O | - | |
| columnSpacing | O | - | O | - | |
| lineSpacing | O | - | O | - | |
| horizontalScroll | O | - | O | - | |
| layout | O | O | O | - | |
| insets | O | - | O | - | |
| insetHorizontal | O | - | O | - | |
| insetVertical | O | - | O | - | |
| contentInsets | O | - | O | - | |
| contentInsetAdjustmentBehavior | O | - | - | - | |
| contentPadding | - | O | - | - | KJUI only |
| itemWeight | O | - | O | - | |
| itemSpacing | - | O | - | - | KJUI only |
| showsHorizontalScrollIndicator | O | - | O | - | |
| showsVerticalScrollIndicator | O | - | O | - | |
| paging | O | - | O | - | |
| sections | O | O | O | - | |
| items | O | O | O | B | Required for dynamic data |
| keyboardAvoidance | uikit | - | - | - | |
| setTargetAsDelegate | O | - | - | - | |
| setTargetAsDataSource | O | - | - | - | |
| cellHeight | - | O | - | - | KJUI only |
| cellWidth | - | O | - | - | KJUI only |
| cell | - | O | - | - | KJUI only |
| spacing | - | O | - | - | KJUI only |

---

## Radio

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| label | O | O | O | B | |
| text | O | O | O | B | Alias |
| group | O | O | O | - | Required |
| options | - | O | - | B | KJUI only, can be dynamic |
| icon | O | - | O | - | |
| selectedIcon | O | - | O | - | |
| selected_icon | O | - | O | - | Underscore alias |
| checked | O | - | O | B | |
| value | O | - | O | - | |
| selectedValue | - | O | O | 2W | KJUI (2W) / RJUI (2W) |
| font | O | - | O | - | |
| fontSize | O | - | O | - | |
| fontColor | O | - | O | - | |
| spacing | O | - | O | - | |
| checkColor | - | O | - | - | KJUI only |
| onValueChange | - | O | O | - | Event handler |
| bind | - | O | - | 2W | KJUI two-way binding |

---

## CheckBox

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| label | O | O | O | B | |
| text | O | O | O | B | Alias |
| isOn | O | - | O | 2W | Two-way binding |
| isChecked | - | O | - | 2W | KJUI only |
| checked | O | - | O | 2W | Alias |
| icon | O | - | O | - | |
| src | O | - | O | - | Alias |
| selectedIcon | O | - | O | - | |
| onSrc | O | - | O | - | Alias |
| value | O | - | O | - | |
| checkColor | - | O | - | - | KJUI only |
| enabled | - | O | - | B | KJUI only |
| onValueChange | - | O | - | - | Event handler |
| bind | - | O | - | 2W | KJUI two-way binding |

---

## Indicator

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| indicatorStyle | O | - | O | - | enum: medium, large |
| color | O | O | O | - | |
| hidesWhenStopped | O | - | O | - | |
| isAnimating | - | O | - | B | KJUI only |
| animating | - | O | - | B | KJUI only (alias) |
| size | - | O | - | - | KJUI: small, medium, large |

---

## GradientView

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| gradient | O | - | O | - | |
| colors | - | O | - | - | KJUI uses colors |
| gradientDirection | O | - | O | - | |
| direction | - | O | - | - | KJUI uses direction |
| locations | O | - | O | - | |
| startPoint | - | O | - | - | KJUI only |
| endPoint | - | O | - | - | KJUI only |
| child | - | O | - | - | KJUI only |

---

## Blur

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| effectStyle | O | - | O | - | |

---

## IconLabel

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| text | O | - | O | B | |
| font | O | - | O | - | |
| fontSize | O | - | O | - | |
| fontColor | O | - | O | - | |
| textShadow | O | - | O | - | |
| selectedFontColor | O | - | O | - | |
| icon_on | O | - | O | - | |
| icon_off | O | - | O | - | |
| iconPosition | O | - | O | - | |
| iconMargin | O | - | O | - | |
| selected | uikit | - | O | B | SJUI UIKit (B) / RJUI (B) |

---

## Web

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| url | O | O | O | B | |
| html | O | O | O | B (RJUI) | RJUI supports binding |
| allowsBackForwardNavigationGestures | O | - | O | - | |
| allowsLinkPreview | O | - | O | - | |
| sandbox | - | - | react | - | RJUI only |
| allow | - | - | react | - | RJUI only |

---

## SafeAreaView

| Attribute | SJUI | KJUI | RJUI | Binding | Notes |
|-----------|------|------|------|---------|-------|
| safeAreaInsetPositions | O | - | O | - | |
| child | O | - | O | - | |
| children | O | - | O | - | Alias |

---

## Platform-Specific Components

### KJUI Only
- **CircleImage**: src (B), size, contentDescription
- **TabView**: tabs, selectedIndex (2W), onSelect
- **Table**: sections, cellClasses, headerClasses, items (B), itemSpacing

### SJUI Only (uikit mode features)
- Advanced constraint attributes (keyViews, etc.)
- Liquid glass effects
- Custom input accessories
- Advanced padding/margin constraints

### RJUI Only (react mode features)
- HTML form attributes (maxLength, pattern, required)
- CSS-specific (className, style object, testId)
- Accessibility (alt for images)
- Loading behavior (loading attribute)

---

## Binding Support Summary

### Two-Way Binding (2W)
These attributes support bidirectional data binding where changes in UI update the data model:

| Component | Attributes |
|-----------|-----------|
| TextField | text |
| TextView | text |
| Toggle/Switch | isOn, value, checked |
| Slider | value |
| Segment | selectedIndex |
| CheckBox | isOn, isChecked, checked |
| SelectBox | selectedIndex, selectedItem (SJUI uikit/KJUI), selectedDate (SJUI uikit) |
| Radio | selectedValue (KJUI) |
| TabView | selectedIndex (KJUI) |

### Read-Only Binding (B)
These attributes support data binding for display purposes:

| Category | Attributes |
|----------|-----------|
| Display | text, label, font, fontSize |
| Style | background, fontColor, visibility, hidden, alpha, opacity, cornerRadius, tintColor, borderWidth, borderColor, clipToBounds |
| Layout | width, height, minWidth, maxWidth, minHeight, maxHeight, paddingTop/Bottom/Left/Right/Start/End, topMargin/bottomMargin/leftMargin/rightMargin/startMargin/endMargin |
| State | enabled, progress, secure, selected, userInteractionEnabled, canTap |
| Data | items, src, srcName, url, contentMode |
| Events | onclick, onClick, onLongPress |

### UIKit-Only Binding (SJUI)
These attributes support binding only in SwiftJsonUI UIKit mode:

| Category | Attributes |
|----------|-----------|
| Layout | widthWeight, heightWeight |
| Style | disabledBackground, defaultBackground |
| State | scrollEnabled, maxZoom, minZoom |
| Text | highlightColor, hintColor, partialAttributes |
| Image | highlightSrc, highlightSrcName, contentMode |
| SelectBox | selectedItem, selectedDate, minimumDate, maximumDate |
| Button | fontColor, disabledFontColor |

### React-Only Binding (RJUI)
These attributes support binding only in ReactJsonUI:

| Category | Attributes |
|----------|-----------|
| Web | html |
| IconLabel | selected |

### Compose-Only Binding (KJUI)
These attributes support binding only in KotlinJsonUI Compose mode:

| Category | Attributes |
|----------|-----------|
| Indicator | isAnimating, animating |
| Radio | options |

---

## Enum Value Differences

### contentMode
| Value | SJUI | KJUI | RJUI |
|-------|------|------|------|
| fit/AspectFit | O | O (aspectFit) | O |
| fill/AspectFill | O | O (aspectFill) | O |
| center | O | O | O |
| ScaleToFill | O | O (fill) | - |
| inside | - | O | - |

### lineBreakMode
| Value | SJUI | KJUI | RJUI |
|-------|------|------|------|
| Char | O | - | O |
| Clip | O | O (clip) | O |
| Word | O | O (word) | O |
| Head | O | O (head) | O |
| Middle | O | O (middle) | O |
| Tail | O | O (tail) | O |

### returnKeyType / imeAction
| Value | SJUI | KJUI | RJUI |
|-------|------|------|------|
| Done | O | O (done) | O |
| Go | O | O (go) | O |
| Next | O | O (next) | O |
| Search | O | O (search) | O |
| Send | O | O (send) | O |
| Return | O | - | O |
| Continue | O | - | - |
| Join | O | - | - |
| Route | O | - | - |
| Yahoo | O | - | - |
| Google | O | - | - |
| previous | - | O | - |
| none | - | O | - |
