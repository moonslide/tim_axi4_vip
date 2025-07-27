#!/bin/bash
# Convert HTML/Markdown files to PDF-ready format

echo "AXI4 VIP Documentation Conversion"
echo "================================="

# Check for pandoc
if command -v pandoc &> /dev/null; then
    echo "✅ Using pandoc for conversion..."
    
    # Convert markdown to PDF-ready format
    pandoc AXI4_VIP_User_Guide.md -s -o AXI4_VIP_User_Guide_print.html \
        --metadata title="AXI4 Verification IP User Guide" \
        --css=pdf_style.css
    
    pandoc AXI4_VIP_Quick_Start.md -s -o AXI4_VIP_Quick_Start_print.html \
        --metadata title="AXI4 VIP Quick Start Guide" \
        --css=pdf_style.css
        
    echo "✅ Generated print-ready HTML files"
else
    echo "⚠️  pandoc not found, HTML files are ready for browser printing"
fi

# Create a CSS file for better print formatting
cat > pdf_style.css << 'EOF'
@media print {
    body {
        font-family: Georgia, serif;
        font-size: 11pt;
        line-height: 1.5;
        margin: 0;
    }
    
    h1 {
        page-break-before: always;
        color: #003366;
        font-size: 24pt;
    }
    
    h1:first-child {
        page-break-before: avoid;
    }
    
    h2 {
        color: #004080;
        font-size: 18pt;
        margin-top: 20pt;
    }
    
    h3 {
        color: #0066cc;
        font-size: 14pt;
    }
    
    pre {
        background-color: #f5f5f5;
        border: 1px solid #ddd;
        padding: 10pt;
        font-size: 9pt;
        page-break-inside: avoid;
    }
    
    code {
        font-family: "Courier New", monospace;
        background-color: #f0f0f0;
        padding: 1pt 3pt;
    }
    
    table {
        border-collapse: collapse;
        width: 100%;
        page-break-inside: avoid;
    }
    
    th {
        background-color: #003366;
        color: white;
        padding: 8pt;
        text-align: left;
    }
    
    td {
        border: 1px solid #ddd;
        padding: 6pt;
    }
    
    tr:nth-child(even) {
        background-color: #f9f9f9;
    }
    
    @page {
        margin: 1in;
        size: letter;
    }
}
EOF

echo ""
echo "📄 Documentation files ready:"
echo "   - AXI4_VIP_User_Guide.html"
echo "   - AXI4_VIP_Quick_Start_Guide.html"
echo "   - AXI4_VIP_User_Guide.md"
echo "   - AXI4_VIP_Quick_Start.md"
echo ""
echo "🖨️  To create PDFs:"
echo "   1. Open HTML files in Chrome/Firefox"
echo "   2. Press Ctrl+P (or Cmd+P on Mac)"
echo "   3. Save as PDF"
echo "   4. Recommended settings:"
echo "      - Margins: Default"
echo "      - Scale: 90%"
echo "      - Background graphics: ON"
echo ""
echo "Alternative: Use online converters like:"
echo "   - https://www.ilovepdf.com/html-to-pdf"
echo "   - https://pdfcrowd.com/"