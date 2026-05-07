#!/bin/bash

# Generate HTML coverage report from JSON
# This script creates a simple HTML report without external dependencies

set -e

COVERAGE_JSON="${1:-coverage/coverage.json}"
OUTPUT_HTML="${2:-coverage/coverage.html}"

if [ ! -f "$COVERAGE_JSON" ]; then
    echo "Error: Coverage JSON file not found: $COVERAGE_JSON"
    echo "Usage: $0 [coverage.json] [output.html]"
    exit 1
fi

# Extract data using python
python3 << 'EOF' - "$COVERAGE_JSON" "$OUTPUT_HTML"
import json
import sys
from datetime import datetime

coverage_file = sys.argv[1]
output_file = sys.argv[2]

with open(coverage_file, 'r') as f:
    data = json.load(f)

# Parse coverage data
targets = data.get('targets', [])
overall_coverage = 0
total_lines = 0
covered_lines = 0

files_data = []

for target in targets:
    if 'SwiftJsonUI' not in target.get('name', ''):
        continue

    for file_info in target.get('files', []):
        name = file_info.get('name', 'Unknown')
        coverage = file_info.get('lineCoverage', 0)
        executable_lines = file_info.get('executableLines', 0)
        covered = file_info.get('coveredLines', 0)

        total_lines += executable_lines
        covered_lines += covered

        files_data.append({
            'name': name,
            'coverage': coverage * 100,
            'executable': executable_lines,
            'covered': covered,
            'uncovered': executable_lines - covered
        })

if total_lines > 0:
    overall_coverage = (covered_lines / total_lines) * 100
else:
    overall_coverage = 0

# Sort by coverage (ascending)
files_data.sort(key=lambda x: x['coverage'])

# Generate HTML
html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SwiftJsonUI Coverage Report</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            overflow: hidden;
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
        }}
        .header h1 {{
            font-size: 28px;
            margin-bottom: 10px;
        }}
        .header p {{
            opacity: 0.9;
            font-size: 14px;
        }}
        .summary {{
            padding: 30px;
            border-bottom: 1px solid #e0e0e0;
        }}
        .summary-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }}
        .summary-card {{
            background: #f8f9fa;
            padding: 20px;
            border-radius: 6px;
            border-left: 4px solid #667eea;
        }}
        .summary-card h3 {{
            color: #666;
            font-size: 14px;
            text-transform: uppercase;
            margin-bottom: 10px;
        }}
        .summary-card .value {{
            font-size: 32px;
            font-weight: bold;
            color: #333;
        }}
        .coverage-badge {{
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: bold;
        }}
        .coverage-high {{ background: #d4edda; color: #155724; }}
        .coverage-medium {{ background: #fff3cd; color: #856404; }}
        .coverage-low {{ background: #f8d7da; color: #721c24; }}
        table {{
            width: 100%;
            border-collapse: collapse;
        }}
        thead {{
            background: #f8f9fa;
        }}
        th {{
            text-align: left;
            padding: 15px 20px;
            font-weight: 600;
            color: #666;
            font-size: 13px;
            text-transform: uppercase;
        }}
        td {{
            padding: 15px 20px;
            border-bottom: 1px solid #f0f0f0;
        }}
        tr:hover {{
            background: #f8f9fa;
        }}
        .filename {{
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 13px;
        }}
        .coverage-bar {{
            width: 100%;
            height: 8px;
            background: #e0e0e0;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }}
        .coverage-bar-fill {{
            height: 100%;
            border-radius: 4px;
            transition: width 0.3s ease;
        }}
        .footer {{
            padding: 20px 30px;
            background: #f8f9fa;
            text-align: center;
            color: #666;
            font-size: 13px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>SwiftJsonUI Coverage Report</h1>
            <p>Generated on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        </div>

        <div class="summary">
            <h2>Coverage Summary</h2>
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Overall Coverage</h3>
                    <div class="value">{overall_coverage:.1f}%</div>
                </div>
                <div class="summary-card">
                    <h3>Total Lines</h3>
                    <div class="value">{total_lines:,}</div>
                </div>
                <div class="summary-card">
                    <h3>Covered Lines</h3>
                    <div class="value">{covered_lines:,}</div>
                </div>
                <div class="summary-card">
                    <h3>Uncovered Lines</h3>
                    <div class="value">{total_lines - covered_lines:,}</div>
                </div>
            </div>
        </div>

        <table>
            <thead>
                <tr>
                    <th>File</th>
                    <th style="width: 150px;">Coverage</th>
                    <th style="width: 100px;">Lines</th>
                    <th style="width: 100px;">Covered</th>
                    <th style="width: 100px;">Uncovered</th>
                </tr>
            </thead>
            <tbody>
'''

for file_data in files_data:
    coverage_pct = file_data['coverage']
    if coverage_pct >= 80:
        badge_class = 'coverage-high'
        bar_color = '#28a745'
    elif coverage_pct >= 50:
        badge_class = 'coverage-medium'
        bar_color = '#ffc107'
    else:
        badge_class = 'coverage-low'
        bar_color = '#dc3545'

    html += f'''
                <tr>
                    <td class="filename">{file_data['name']}</td>
                    <td>
                        <div class="coverage-bar">
                            <div class="coverage-bar-fill" style="width: {coverage_pct}%; background: {bar_color};"></div>
                        </div>
                        <span class="coverage-badge {badge_class}" style="margin-top: 5px; display: inline-block;">
                            {coverage_pct:.1f}%
                        </span>
                    </td>
                    <td>{file_data['executable']}</td>
                    <td>{file_data['covered']}</td>
                    <td>{file_data['uncovered']}</td>
                </tr>
'''

html += f'''
            </tbody>
        </table>

        <div class="footer">
            <p>SwiftJsonUI Test Coverage Report</p>
            <p>Coverage threshold goal: 80%</p>
        </div>
    </div>
</body>
</html>
'''

with open(output_file, 'w') as f:
    f.write(html)

print(f"HTML coverage report generated: {output_file}")
print(f"Overall coverage: {overall_coverage:.1f}%")

EOF

echo "HTML report generated successfully!"
echo "Open: $OUTPUT_HTML"
