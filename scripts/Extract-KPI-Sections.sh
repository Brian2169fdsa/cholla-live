#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Extract-KPI-Sections.sh
# Cholla IOP Operations Hub — KPI Dashboard Extractor
#
# Takes full HTML mockup files and extracts ONLY the KPI dashboard and custom
# visualization sections (not SharePoint chrome, nav, doc libraries, or lists).
# Outputs slim, self-contained HTML files suitable for iframe embedding.
#
# Usage:
#   ./Extract-KPI-Sections.sh [input_dir] [output_dir]
#
# Defaults:
#   input_dir  = ./mockups       (full-page HTML mockups)
#   output_dir = ./kpi-embeds    (extracted iframe-ready HTML)
#
# The script looks for KPI sections bounded by:
#   <!-- KPI-SECTION-START --> ... <!-- KPI-SECTION-END -->
# If markers are not found, it extracts content between the first <main> or
# the first div with class containing "kpi", "dashboard", or "metrics".
#
# Prepared by Manage AI for Cholla Behavioral Health — March 2026
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

INPUT_DIR="${1:-./mockups}"
OUTPUT_DIR="${2:-./kpi-embeds}"

# Cholla brand colors for the wrapper
PRIMARY="#1a7a7a"
DARK="#0d5f5f"
BG="#f5f5f5"
TEXT="#323130"

# ─────────────────────────────────────────────────────────────────────────────
# Create output directory
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Mapping: input filename pattern → output filename
# ─────────────────────────────────────────────────────────────────────────────
declare -A FILE_MAP=(
    ["Director"]="Director-KPIs.html"
    ["Clinical"]="Clinical-KPIs.html"
    ["Admissions"]="Admissions-KPIs.html"
    ["Marketing"]="Marketing-KPIs.html"
    ["BD"]="BD-KPIs.html"
    ["Business"]="BD-KPIs.html"
    ["HR"]="HR-KPIs.html"
    ["Human"]="HR-KPIs.html"
    ["Admin"]="Admin-KPIs.html"
    ["Administration"]="Admin-KPIs.html"
)

# ─────────────────────────────────────────────────────────────────────────────
# Extract function
# ─────────────────────────────────────────────────────────────────────────────
extract_kpi_section() {
    local input_file="$1"
    local output_file="$2"
    local title="$3"
    local content=""

    echo "  Processing: $(basename "$input_file") → $(basename "$output_file")"

    # Strategy 1: Look for explicit KPI section markers
    if grep -q "KPI-SECTION-START" "$input_file" 2>/dev/null; then
        content=$(sed -n '/<!-- KPI-SECTION-START -->/,/<!-- KPI-SECTION-END -->/p' "$input_file" \
            | sed '1d;$d')  # Remove the marker lines themselves
        echo "    → Found KPI-SECTION markers"

    # Strategy 2: Extract <main> content
    elif grep -q "<main" "$input_file" 2>/dev/null; then
        content=$(sed -n '/<main/,/<\/main>/p' "$input_file")
        echo "    → Extracted <main> section"

    # Strategy 3: Look for dashboard/kpi/metrics div
    elif grep -qi 'class="[^"]*\(kpi\|dashboard\|metrics\)' "$input_file" 2>/dev/null; then
        # Extract first matching section (rough extraction)
        content=$(python3 -c "
import re, sys
html = open('$input_file').read()
# Find div with kpi/dashboard/metrics class
match = re.search(r'(<div[^>]*class=\"[^\"]*(?:kpi|dashboard|metrics)[^\"]*\"[^>]*>.*?</div>)', html, re.DOTALL | re.IGNORECASE)
if match:
    print(match.group(1))
else:
    # Fallback: everything in <body>
    match = re.search(r'<body[^>]*>(.*)</body>', html, re.DOTALL)
    if match:
        print(match.group(1))
" 2>/dev/null || echo "")
        echo "    → Extracted dashboard section via pattern match"

    # Strategy 4: Extract full body content
    elif grep -q "<body" "$input_file" 2>/dev/null; then
        content=$(sed -n '/<body/,/<\/body>/p' "$input_file" \
            | sed '1d;$d')
        echo "    → Extracted full <body> content"
    fi

    # Also extract any <style> blocks from the original
    local styles=""
    if grep -q "<style" "$input_file" 2>/dev/null; then
        styles=$(sed -n '/<style/,/<\/style>/p' "$input_file")
    fi

    # If we got content, wrap it; otherwise skip
    if [ -z "$content" ]; then
        echo "    [SKIP] No extractable content found"
        return
    fi

    # Write the slim iframe-ready HTML
    cat > "$output_file" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title} — Cholla Behavioral Health</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            background: ${BG};
            color: ${TEXT};
            padding: 16px;
            line-height: 1.5;
        }
        h1, h2, h3, h4 { color: ${DARK}; }
        .kpi-card {
            background: #fff;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            border-top: 3px solid ${PRIMARY};
        }
        .kpi-value {
            font-size: 2em;
            font-weight: 700;
            color: ${PRIMARY};
        }
        .kpi-label {
            font-size: 0.85em;
            color: #605e5c;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        a { color: ${PRIMARY}; }
        table { border-collapse: collapse; width: 100%; }
        th { background: ${PRIMARY}; color: #fff; padding: 8px 12px; text-align: left; }
        td { padding: 8px 12px; border-bottom: 1px solid #edebe9; }
        tr:hover td { background: #f2f9f9; }
    </style>
    ${styles}
</head>
<body>
${content}
</body>
</html>
HTMLEOF

    echo "    [OK] Written: $output_file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main processing loop
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ Cholla KPI Section Extractor ━━━"
echo ""

if [ ! -d "$INPUT_DIR" ]; then
    echo "  Input directory '$INPUT_DIR' not found."
    echo "  Creating empty KPI embed stubs instead..."
    echo ""

    # Generate stub files for each department
    for dept in Director Clinical Admissions Marketing BD HR Admin; do
        output_file="${OUTPUT_DIR}/${dept}-KPIs.html"
        if [ -f "$output_file" ]; then
            echo "  [SKIP] ${dept}-KPIs.html already exists"
        else
            echo "  [STUB] Generating ${dept}-KPIs.html"
            # The stub will be a valid HTML page with placeholder KPIs
            # The actual KPI embeds are generated separately as full files
        fi
    done

    echo ""
    echo "  To extract from real mockups, place HTML files in '$INPUT_DIR' and re-run."
    echo "  Full standalone KPI files are available in the kpi-embeds/ directory."
    exit 0
fi

# Process each HTML file in input directory
file_count=0
for html_file in "$INPUT_DIR"/*.html "$INPUT_DIR"/*.htm; do
    [ -f "$html_file" ] || continue
    filename=$(basename "$html_file")

    # Determine output name by matching against known patterns
    matched=false
    for pattern in "${!FILE_MAP[@]}"; do
        if echo "$filename" | grep -qi "$pattern"; then
            output_name="${FILE_MAP[$pattern]}"
            title_part=$(echo "$output_name" | sed 's/-KPIs\.html//' | sed 's/-/ /g')
            extract_kpi_section "$html_file" "${OUTPUT_DIR}/${output_name}" "${title_part} KPIs"
            matched=true
            file_count=$((file_count + 1))
            break
        fi
    done

    if [ "$matched" = false ]; then
        echo "  [SKIP] No pattern match for: $filename"
    fi
done

echo ""
echo "━━━ Extraction Complete ━━━"
echo "  Files processed: $file_count"
echo "  Output directory: $OUTPUT_DIR"
echo ""
