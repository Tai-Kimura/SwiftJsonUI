#!/bin/bash

# SwiftJsonUI Test Coverage Script
# This script runs tests with code coverage enabled and generates HTML reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCHEME="SwiftJsonUI"
DESTINATION="platform=iOS Simulator,name=iPhone 14 Pro,OS=16.4"
DERIVED_DATA_PATH=".build/DerivedData"
COVERAGE_DIR="coverage"
XCRESULT_PATH="${DERIVED_DATA_PATH}/Logs/Test/Test-SwiftJsonUI.xcresult"

# Parse command line arguments
SHOW_REPORT=false
VERBOSE=false
MIN_COVERAGE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --show)
            SHOW_REPORT=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --min-coverage)
            MIN_COVERAGE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./scripts/test-coverage.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --show              Open coverage report in browser after generation"
            echo "  --verbose, -v       Show detailed test output"
            echo "  --min-coverage NUM  Fail if coverage is below NUM percent (0-100)"
            echo "  --help, -h          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SwiftJsonUI Test Coverage Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Clean previous coverage data
echo -e "${YELLOW}Cleaning previous coverage data...${NC}"
rm -rf "${DERIVED_DATA_PATH}"
rm -rf "${COVERAGE_DIR}"
mkdir -p "${COVERAGE_DIR}"

# Run tests with coverage
echo -e "${YELLOW}Running tests with coverage enabled...${NC}"
echo -e "${BLUE}Scheme: ${SCHEME}${NC}"
echo -e "${BLUE}Destination: ${DESTINATION}${NC}"
echo ""

if [ "$VERBOSE" = true ]; then
    xcodebuild test \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        -enableCodeCoverage YES
else
    if command -v xcpretty &> /dev/null; then
        xcodebuild test \
            -scheme "${SCHEME}" \
            -destination "${DESTINATION}" \
            -derivedDataPath "${DERIVED_DATA_PATH}" \
            -enableCodeCoverage YES \
            2>&1 | xcpretty --color
    else
        xcodebuild test \
            -scheme "${SCHEME}" \
            -destination "${DESTINATION}" \
            -derivedDataPath "${DERIVED_DATA_PATH}" \
            -enableCodeCoverage YES \
            -quiet
    fi
fi

# Check if tests passed
TEST_EXIT_CODE=${PIPESTATUS[0]}
if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Tests failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Tests passed!${NC}"
echo ""

# Generate coverage report
echo -e "${YELLOW}Generating coverage report...${NC}"

# Find the xcresult bundle
XCRESULT_BUNDLE=$(find "${DERIVED_DATA_PATH}/Logs/Test" -name "*.xcresult" | head -1)

if [ -z "$XCRESULT_BUNDLE" ]; then
    echo -e "${RED}Error: Could not find xcresult bundle${NC}"
    exit 1
fi

echo -e "${BLUE}Using xcresult bundle: ${XCRESULT_BUNDLE}${NC}"

# Export coverage data
xcrun xccov view --report "${XCRESULT_BUNDLE}" > "${COVERAGE_DIR}/coverage.txt"
xcrun xccov view --report --json "${XCRESULT_BUNDLE}" > "${COVERAGE_DIR}/coverage.json"

# Parse coverage percentage
COVERAGE_PERCENT=$(xcrun xccov view --report "${XCRESULT_BUNDLE}" | grep "SwiftJsonUI.framework" | awk '{print $4}' | sed 's/%//')

if [ -z "$COVERAGE_PERCENT" ]; then
    echo -e "${YELLOW}Warning: Could not parse coverage percentage from framework line${NC}"
    # Try alternate parsing
    COVERAGE_PERCENT=$(xcrun xccov view --report "${XCRESULT_BUNDLE}" | grep -E "^[0-9]+\.[0-9]+%" | head -1 | awk '{print $1}' | sed 's/%//')
fi

if [ -z "$COVERAGE_PERCENT" ]; then
    echo -e "${RED}Error: Could not determine coverage percentage${NC}"
    COVERAGE_PERCENT=0
fi

# Generate HTML report
echo -e "${YELLOW}Generating HTML report...${NC}"
./scripts/generate-coverage-html.sh "${COVERAGE_DIR}/coverage.json" "${COVERAGE_DIR}/coverage.html"

# Display summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Coverage Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Show per-file coverage (limit to 30 lines)
xcrun xccov view --report "${XCRESULT_BUNDLE}" | grep -E "(SwiftJsonUI|\.swift)" | head -30

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Overall Coverage: ${COVERAGE_PERCENT}%${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Save coverage summary
cat > "${COVERAGE_DIR}/summary.txt" << EOF
SwiftJsonUI Test Coverage Report
Generated: $(date)

Overall Coverage: ${COVERAGE_PERCENT}%

Reports:
- Text report: ${COVERAGE_DIR}/coverage.txt
- JSON report: ${COVERAGE_DIR}/coverage.json
- HTML report: ${COVERAGE_DIR}/coverage.html

To view detailed report:
  cat ${COVERAGE_DIR}/coverage.txt

To view HTML report:
  open ${COVERAGE_DIR}/coverage.html

To view in JSON:
  cat ${COVERAGE_DIR}/coverage.json
EOF

echo -e "${GREEN}Coverage reports saved to ${COVERAGE_DIR}/${NC}"
echo "  - Text: ${COVERAGE_DIR}/coverage.txt"
echo "  - JSON: ${COVERAGE_DIR}/coverage.json"
echo "  - HTML: ${COVERAGE_DIR}/coverage.html"
echo ""

# Check minimum coverage threshold
if [ "$MIN_COVERAGE" -gt 0 ]; then
    COVERAGE_INT=${COVERAGE_PERCENT%.*}
    if [ "$COVERAGE_INT" -lt "$MIN_COVERAGE" ]; then
        echo -e "${RED}Coverage ${COVERAGE_PERCENT}% is below minimum threshold of ${MIN_COVERAGE}%${NC}"
        exit 1
    else
        echo -e "${GREEN}Coverage ${COVERAGE_PERCENT}% meets minimum threshold of ${MIN_COVERAGE}%${NC}"
    fi
fi

# Open report if requested
if [ "$SHOW_REPORT" = true ]; then
    if [ -f "${COVERAGE_DIR}/coverage.html" ]; then
        echo -e "${YELLOW}Opening coverage report in browser...${NC}"
        open "${COVERAGE_DIR}/coverage.html"
    else
        echo -e "${YELLOW}Opening text report...${NC}"
        cat "${COVERAGE_DIR}/coverage.txt"
    fi
fi

echo -e "${GREEN}Done!${NC}"
