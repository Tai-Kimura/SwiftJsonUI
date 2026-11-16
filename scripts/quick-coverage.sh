#!/bin/bash

# Quick coverage check - shows summary without generating full reports
# Useful for quick checks during development

set -e

SCHEME="SwiftJsonUI"
DESTINATION="platform=iOS Simulator,name=iPhone 14 Pro,OS=16.4"
DERIVED_DATA_PATH=".build/DerivedData"

echo "Running tests with coverage..."
echo ""

# Clean previous data
rm -rf "${DERIVED_DATA_PATH}"

# Run tests quietly
xcodebuild test \
    -scheme "${SCHEME}" \
    -destination "${DESTINATION}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -enableCodeCoverage YES \
    -quiet

# Check if tests passed
if [ $? -ne 0 ]; then
    echo "Tests failed!"
    exit 1
fi

# Find xcresult bundle
XCRESULT_BUNDLE=$(find "${DERIVED_DATA_PATH}/Logs/Test" -name "*.xcresult" | head -1)

if [ -z "$XCRESULT_BUNDLE" ]; then
    echo "Error: Could not find test results"
    exit 1
fi

echo ""
echo "=========================================="
echo "Coverage Summary"
echo "=========================================="
echo ""

# Show coverage
xcrun xccov view --report "${XCRESULT_BUNDLE}" | head -40

echo ""
echo "Tests passed! ✓"
echo ""
