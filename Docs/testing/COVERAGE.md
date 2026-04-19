# SwiftJsonUI Test Coverage Guide

This document explains how to measure and improve test coverage for the SwiftJsonUI library.

## Coverage Goal

**Target: 80% line coverage**

We aim to maintain at least 80% test coverage across the codebase to ensure reliability and catch regressions early.

## Quick Start

### Run Tests with Coverage

```bash
# Full coverage report with HTML output
./scripts/test-coverage.sh

# Quick coverage check (summary only)
./scripts/quick-coverage.sh

# Open coverage report in browser after generation
./scripts/test-coverage.sh --show

# Fail if coverage is below 80%
./scripts/test-coverage.sh --min-coverage 80
```

## Scripts Overview

### 1. test-coverage.sh

The main coverage script that runs tests and generates comprehensive reports.

**Features:**
- Runs tests on iOS Simulator with coverage enabled
- Generates text, JSON, and HTML reports
- Shows per-file coverage breakdown
- Supports minimum coverage threshold validation

**Usage:**
```bash
./scripts/test-coverage.sh [OPTIONS]

Options:
  --show              Open coverage report in browser after generation
  --verbose, -v       Show detailed test output
  --min-coverage NUM  Fail if coverage is below NUM percent (0-100)
  --help, -h          Show help message
```

**Examples:**
```bash
# Basic usage
./scripts/test-coverage.sh

# With minimum coverage check
./scripts/test-coverage.sh --min-coverage 80

# Verbose output and auto-open report
./scripts/test-coverage.sh --verbose --show
```

### 2. quick-coverage.sh

Fast coverage check for quick feedback during development.

**Usage:**
```bash
./scripts/quick-coverage.sh
```

This script runs tests and shows a summary without generating full reports. Useful for:
- Quick checks during development
- Pre-commit validation
- CI/CD pipelines where you only need pass/fail

### 3. generate-coverage-html.sh

Generates a beautiful HTML coverage report from JSON data.

**Usage:**
```bash
./scripts/generate-coverage-html.sh [coverage.json] [output.html]

# Default paths
./scripts/generate-coverage-html.sh coverage/coverage.json coverage/coverage.html
```

This script creates a standalone HTML file with:
- Overall coverage percentage
- Color-coded coverage bars
- Sortable file list
- Coverage by file

## Coverage Reports

After running `./scripts/test-coverage.sh`, you'll find reports in the `coverage/` directory:

```
coverage/
├── coverage.txt       # Text-based coverage report
├── coverage.json      # Machine-readable JSON format
├── coverage.html      # HTML coverage report
└── summary.txt        # Quick summary
```

### Reading Coverage Reports

#### Text Report (`coverage.txt`)

```
SwiftJsonUI.framework (75.2%)
├── DynamicComponent.swift (92.5%)
├── ComponentBuilder.swift (88.3%)
├── Extensions.swift (65.1%)
└── ...
```

Each line shows:
- File path
- Coverage percentage
- (Optional) Line-by-line details

#### HTML Report (`coverage.html`)

Open in browser for:
- Visual coverage bars
- Color-coded files (red <50%, yellow 50-79%, green 80%+)
- Sortable columns
- Overall statistics

#### JSON Report (`coverage.json`)

Machine-readable format for:
- CI/CD integration
- Custom analysis tools
- Historical tracking

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test Coverage

on: [push, pull_request]

jobs:
  coverage:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run tests with coverage
        run: ./scripts/test-coverage.sh --min-coverage 80

      - name: Upload coverage reports
        uses: actions/upload-artifact@v3
        with:
          name: coverage-reports
          path: coverage/
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running coverage check..."
./scripts/quick-coverage.sh

# Optionally enforce minimum coverage
# ./scripts/test-coverage.sh --min-coverage 80
```

## Understanding Coverage Metrics

### Line Coverage

Percentage of executable lines that are run during tests.

```swift
func example(value: Int) -> String {
    if value > 0 {              // ✅ Covered
        return "positive"       // ✅ Covered
    } else {
        return "non-positive"   // ❌ Not covered
    }
}
```

If the `else` branch is never tested, line coverage will be 75% (3/4 lines).

### What Good Coverage Means

- **80%+ coverage**: Good baseline, most code paths tested
- **90%+ coverage**: Excellent, comprehensive testing
- **100% coverage**: Perfect, but may not be practical

### Coverage Doesn't Guarantee Quality

Coverage measures **which** lines run, not **how well** they're tested. You still need:
- Meaningful assertions
- Edge case testing
- Integration tests
- Manual QA

## Improving Coverage

### 1. Identify Low-Coverage Files

```bash
./scripts/test-coverage.sh | grep -E "[0-9]+\.[0-9]+%" | sort -n
```

### 2. Focus on Critical Code First

Prioritize coverage for:
- Core parsing logic
- Public APIs
- Complex algorithms
- Bug-prone areas

### 3. Add Tests for Uncovered Lines

Use Xcode's coverage tools to see exactly which lines need tests:

1. Run tests in Xcode (`Cmd+U`)
2. Open Coverage tab (Show Report Navigator → Coverage)
3. Click a file to see line-by-line coverage
4. Add tests for red (uncovered) lines

### 4. Test Edge Cases

Don't just test happy paths. Cover:
- Empty inputs
- Nil values
- Boundary conditions
- Error cases
- Invalid data

## Best Practices

### DO:
- Run coverage regularly during development
- Add tests for new code before merging
- Review coverage reports in PR reviews
- Set minimum coverage thresholds
- Test both success and failure paths

### DON'T:
- Write tests just to increase coverage numbers
- Ignore untestable code (refactor it instead)
- Aim for 100% at the cost of test quality
- Skip edge cases
- Test implementation details (test behavior)

## Troubleshooting

### "No such module 'UIKit'" Error

This happens when running `swift test` on macOS. Use the provided scripts which run tests on iOS Simulator instead.

### Tests Pass but No Coverage Data

Ensure you're using `-enableCodeCoverage YES` flag with xcodebuild:

```bash
xcodebuild test -scheme SwiftJsonUI \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
    -enableCodeCoverage YES
```

### Coverage Report Shows 0%

Check that:
1. Tests actually ran
2. The scheme has code coverage enabled
3. You're measuring the right target

### HTML Report Not Generated

The HTML generator requires Python 3. Install it via Homebrew:

```bash
brew install python3
```

## Advanced Usage

### Measuring Specific Files

Filter the JSON report to focus on specific files:

```bash
cat coverage/coverage.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for target in data['targets']:
    for file in target['files']:
        if 'DynamicComponent' in file['name']:
            print(f\"{file['name']}: {file['lineCoverage']*100:.1f}%\")
"
```

### Historical Coverage Tracking

Save coverage data over time:

```bash
DATE=$(date +%Y-%m-%d)
./scripts/test-coverage.sh
cp coverage/coverage.json "coverage/history/coverage-${DATE}.json"
```

### Custom Thresholds by Module

Create a custom validation script:

```bash
#!/bin/bash
# check-module-coverage.sh

CORE_MIN=90
UIKIT_MIN=80
SWIFTUI_MIN=85

# Extract per-module coverage and validate
# ... implementation ...
```

## Getting Help

If you encounter issues:

1. Check this documentation
2. Review the script source code
3. Run with `--verbose` flag for debugging
4. Check Xcode's built-in coverage tools

## References

- [Apple Documentation: Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [xccov Documentation](https://keith.github.io/xcode-man-pages/xccov.1.html)
- [SwiftJsonUI Testing Guide](../TESTING.md)
