# AXI4 VIP Documentation

## Available Documents

### 1. **AXI4 VIP User Guide** (Comprehensive)
- **Format**: HTML, Markdown
- **Pages**: ~40 pages when printed
- **Content**: Complete reference guide covering all aspects of the VIP
- **Target Audience**: Engineers implementing and using the VIP

### 2. **AXI4 VIP Quick Start Guide**
- **Format**: HTML, Markdown  
- **Pages**: ~5 pages when printed
- **Content**: Condensed guide for getting started quickly
- **Target Audience**: New users, quick reference

## Document Formats

### HTML Files (Print-Ready)
- `AXI4_VIP_User_Guide.html` - Full user guide with professional styling
- `AXI4_VIP_Quick_Start_Guide.html` - Quick reference guide

**Features:**
- Professional typography and layout
- Color-coded sections
- Syntax-highlighted code blocks
- Print-optimized CSS styling
- Page breaks at logical sections

### Markdown Files
- `AXI4_VIP_User_Guide.md` - Full guide in markdown
- `AXI4_VIP_Quick_Start.md` - Quick guide in markdown

**Use Cases:**
- Version control friendly
- Easy to edit and maintain
- Can be converted to various formats

## Creating PDF Files

### Method 1: Browser Print (Recommended)

1. Open HTML file in Chrome or Firefox
2. Press `Ctrl+P` (Windows/Linux) or `Cmd+P` (Mac)
3. Configure settings:
   - **Destination**: Save as PDF
   - **Pages**: All
   - **Layout**: Portrait
   - **Margins**: Default
   - **Scale**: 90% (for better fit)
   - **Options**: 
     - ✓ Background graphics
     - ✓ Headers and footers

### Method 2: Command Line Tools

If you have access to conversion tools:

```bash
# Using wkhtmltopdf
wkhtmltopdf --enable-local-file-access \
  --margin-top 20mm --margin-bottom 20mm \
  --margin-left 20mm --margin-right 20mm \
  AXI4_VIP_User_Guide.html AXI4_VIP_User_Guide.pdf

# Using weasyprint
weasyprint AXI4_VIP_User_Guide.html AXI4_VIP_User_Guide.pdf

# Using pandoc (for markdown)
pandoc AXI4_VIP_User_Guide.md -o AXI4_VIP_User_Guide.pdf \
  --pdf-engine=xelatex --highlight-style=tango
```

### Method 3: Online Converters

- [ILovePDF HTML to PDF](https://www.ilovepdf.com/html-to-pdf)
- [PDFCrowd](https://pdfcrowd.com/)
- [Convertio](https://convertio.co/html-pdf/)

## Documentation Content

### User Guide Contents
1. **Introduction** - Overview and features
2. **Getting Started** - Installation and setup
3. **Architecture** - Component hierarchy
4. **Configuration** - Bus matrix setup
5. **Running Tests** - Execution commands
6. **Test Development** - Creating new tests
7. **Scalability** - Supporting large matrices
8. **Troubleshooting** - Common issues
9. **Best Practices** - Coding guidelines
10. **API Reference** - Detailed API docs

### Quick Start Contents
- Prerequisites
- Installation steps
- Basic commands
- Common operations
- Pro tips
- Quick reference tables

## Professional Features

### Design Elements
- **Corporate Colors**: Navy blue (#003366) headers
- **Typography**: Professional fonts (Helvetica, Georgia)
- **Code Highlighting**: Syntax-colored code blocks
- **Tables**: Alternating row colors for readability
- **Info Boxes**: Tips, warnings, and notes
- **Page Layout**: Proper margins and spacing

### Print Optimization
- Automatic page breaks before chapters
- Keep tables and code blocks together
- Header/footer with page numbers
- Optimized for letter-size paper

## Maintenance

### Updating Documentation

1. Edit the Python generator scripts:
   - `generate_pdf_simple.py` - Main generator
   - `generate_pdf_docs.py` - Advanced generator (requires reportlab)

2. Regenerate documents:
   ```bash
   python3 generate_pdf_simple.py
   ```

3. Review and test print output

### Version Control

All documentation source files are tracked in Git:
- Generator scripts
- Markdown sources
- HTML outputs
- CSS styling

## Support

For documentation questions or improvements:
- Email: axi4_vip_support@company.com
- Create GitHub issue with 'documentation' label

---
Last Updated: July 2025  
Version: 2.0