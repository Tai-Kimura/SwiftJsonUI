# SwiftJsonUI Testing Scripts

This directory contains scripts for running tests and measuring code coverage.

## Available Scripts

### test-coverage.sh

**Purpose:** Run comprehensive test coverage analysis

**Usage:**
```bash
./scripts/test-coverage.sh [OPTIONS]
```

**Options:**
- `--show`: Open coverage report in browser
- `--verbose, -v`: Show detailed test output
- `--min-coverage NUM`: Fail if coverage below NUM%
- `--help, -h`: Show help

**Examples:**
```bash
# Basic coverage run
./scripts/test-coverage.sh

# With 80% minimum threshold
./scripts/test-coverage.sh --min-coverage 80

# Verbose output, auto-open report
./scripts/test-coverage.sh --verbose --show
```

**Outputs:**
- `coverage/coverage.txt` - Text report
- `coverage/coverage.json` - JSON data
- `coverage/coverage.html` - HTML report
- `coverage/summary.txt` - Quick summary

---

### quick-coverage.sh

**Purpose:** Fast coverage check for development

**Usage:**
```bash
./scripts/quick-coverage.sh
```

**When to use:**
- Quick validation during development
- Pre-commit checks
- CI/CD where only pass/fail needed

**Output:** Console summary only (no files generated)

---

### generate-coverage-html.sh

**Purpose:** Generate HTML report from JSON data

**Usage:**
```bash
./scripts/generate-coverage-html.sh [input.json] [output.html]
```

**Defaults:**
- Input: `coverage/coverage.json`
- Output: `coverage/coverage.html`

**When to use:**
- Regenerate HTML after manual JSON edits
- Create custom reports from archived data

---

## Quick Reference

```bash
# Most common workflow
./scripts/test-coverage.sh --min-coverage 80 --show

# During development (faster)
./scripts/quick-coverage.sh

# CI/CD
./scripts/test-coverage.sh --min-coverage 80
```

## Coverage Goal

**Target: 80% line coverage**

All new code should maintain or improve coverage. See [COVERAGE.md](../docs/testing/COVERAGE.md) for details.

## Requirements

- Xcode 14.0+
- iOS Simulator
- Python 3 (for HTML generation)

## Troubleshooting

**Scripts not executable?**
```bash
chmod +x scripts/*.sh
```

**No iOS Simulator?**
```bash
xcodebuild -downloadPlatform iOS
```

**Coverage shows 0%?**
Check that tests are actually running and passing first.

## More Information

See [docs/testing/COVERAGE.md](../docs/testing/COVERAGE.md) for comprehensive coverage documentation.
