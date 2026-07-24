# SwiftJsonUI Test Coverage

## Current Status

**Coverage: 3.41%** (799/23,413 lines)

**Goal: 80%+**

## Quick Start

### Run Coverage

```bash
# Full report with HTML
./scripts/test-coverage.sh --show

# Quick check
./scripts/quick-coverage.sh

# Enforce minimum threshold
./scripts/test-coverage.sh --min-coverage 80
```

### View Reports

```bash
# HTML (recommended)
open coverage/coverage.html

# Text
cat coverage/coverage.txt

# Summary
cat coverage/summary.txt
```

## What's Available

### Scripts (in `scripts/`)

1. **test-coverage.sh** - Comprehensive coverage with reports
2. **quick-coverage.sh** - Fast summary-only check
3. **generate-coverage-html.sh** - HTML report generator

All scripts are executable and ready to use.

### Documentation (in `docs/testing/`)

- **COVERAGE.md** - Complete coverage guide
- **COVERAGE_SETUP.md** - Infrastructure setup details

### Generated Reports (in `coverage/`)

After running `./scripts/test-coverage.sh`:

- `coverage.txt` - Text report (6.5 MB, line-by-line details)
- `coverage.json` - JSON data (1.1 MB, machine-readable)
- `coverage.html` - HTML report (165 KB, visual)
- `summary.txt` - Quick summary

## Priority Areas for Testing

Based on current 3.41% coverage, focus on:

1. **Core Parsing** (0% coverage)
   - SwiftyJSON.swift (1,140 lines)
   - JSON layout parsing
   - Data type conversions

2. **SwiftUI Components** (low coverage)
   - DynamicComponent (partially tested)
   - Component builders
   - View converters

3. **UIKit Components** (0% coverage)
   - SJUIView and subclasses
   - Layout managers
   - Binding handlers

4. **Network Layer** (0% coverage)
   - Image loading
   - Network requests
   - Caching

5. **Utilities** (partially tested)
   - String extensions (tested)
   - Color extensions (tested)
   - Layout helpers (needs tests)

## Test Files

Existing tests in `Tests/SwiftJsonUITests/`:

- DynamicComponentTests.swift - JSON parsing
- JSONLayoutIntegrationTests.swift - Layout integration
- UIColorExtensionTests.swift - Color parsing
- StringExtensionTests.swift - String utilities
- AnyCodableTests.swift - Type conversion
- DynamicDecodingHelperTests.swift - Decoding helpers
- RTLAttributesTests.swift - RTL support

## Adding New Tests

1. **Create test file** in `Tests/SwiftJsonUITests/`
2. **Import XCTest** and `@testable import SwiftJsonUI`
3. **Write tests** for uncovered code
4. **Run coverage** to verify improvement

Example:

```swift
import XCTest
@testable import SwiftJsonUI

final class MyComponentTests: XCTestCase {
    func testComponentCreation() throws {
        let json: [String: Any] = ["type": "MyComponent"]
        let component = try ComponentFactory.create(from: json)
        XCTAssertNotNil(component)
    }
}
```

## CI/CD Integration

See `docs/testing/COVERAGE.md` for GitHub Actions examples.

## More Information

- [Full Coverage Documentation](docs/testing/COVERAGE.md)
- [Setup Details](docs/testing/COVERAGE_SETUP.md)
- [Scripts README](scripts/README.md)

---

**Next Step**: Run `./scripts/test-coverage.sh --show` to see current coverage and identify areas needing tests.
