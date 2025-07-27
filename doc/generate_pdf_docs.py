#!/usr/bin/env python3
"""
Generate professional PDF documentation for AXI4 VIP
Creates both comprehensive user guide and quick start guide
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak
from reportlab.platypus import Image, KeepTogether, ListFlowable, ListItem
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
from reportlab.pdfgen import canvas
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.platypus import Flowable
from datetime import datetime
import os

class PageNumCanvas(canvas.Canvas):
    """Canvas that adds page numbers and headers/footers"""
    
    def __init__(self, *args, **kwargs):
        canvas.Canvas.__init__(self, *args, **kwargs)
        self.pages = []
        self.width, self.height = letter
        
    def showPage(self):
        self.pages.append(dict(self.__dict__))
        self._startPage()
        
    def save(self):
        page_count = len(self.pages)
        for page in self.pages:
            self.__dict__.update(page)
            self.draw_page_number(page_count)
            self.draw_header_footer()
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)
        
    def draw_page_number(self, page_count):
        self.setFont("Helvetica", 9)
        self.drawRightString(
            self.width - inch,
            0.5 * inch,
            f"Page {self._pageNumber} of {page_count}"
        )
        
    def draw_header_footer(self):
        # Header
        self.setStrokeColor(colors.HexColor("#003366"))
        self.setLineWidth(2)
        self.line(inch, self.height - inch, self.width - inch, self.height - inch)
        
        # Header text
        self.setFont("Helvetica-Bold", 10)
        self.setFillColor(colors.HexColor("#003366"))
        self.drawString(inch, self.height - 0.75 * inch, "AXI4 Verification IP")
        self.drawRightString(self.width - inch, self.height - 0.75 * inch, "Version 2.0")
        
        # Footer
        self.setLineWidth(1)
        self.line(inch, 0.75 * inch, self.width - inch, 0.75 * inch)
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.grey)
        self.drawString(inch, 0.5 * inch, "© 2025 AXI4 VIP Development Team")
        
        # Reset colors
        self.setFillColor(colors.black)

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        canvas.Canvas.__init__(self, *args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        """add page numbers to all pages"""
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_number(self, page_count):
        self.setFont("Helvetica", 9)
        self.drawRightString(
            letter[0] - inch,
            0.5 * inch,
            f"Page {self._pageNumber} of {page_count}"
        )

def create_styles():
    """Create custom styles for the document"""
    styles = getSampleStyleSheet()
    
    # Title style
    styles.add(ParagraphStyle(
        name='CustomTitle',
        parent=styles['Title'],
        fontSize=28,
        textColor=colors.HexColor("#003366"),
        spaceAfter=30,
        alignment=TA_CENTER
    ))
    
    # Subtitle style
    styles.add(ParagraphStyle(
        name='Subtitle',
        parent=styles['Title'],
        fontSize=18,
        textColor=colors.HexColor("#666666"),
        spaceAfter=20,
        alignment=TA_CENTER
    ))
    
    # Chapter heading
    styles.add(ParagraphStyle(
        name='ChapterHeading',
        parent=styles['Heading1'],
        fontSize=20,
        textColor=colors.HexColor("#003366"),
        spaceAfter=20,
        spaceBefore=30,
        keepWithNext=True
    ))
    
    # Section heading
    styles.add(ParagraphStyle(
        name='SectionHeading',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=colors.HexColor("#004080"),
        spaceAfter=12,
        spaceBefore=20,
        keepWithNext=True
    ))
    
    # Code style
    styles.add(ParagraphStyle(
        name='Code',
        parent=styles['Code'],
        fontSize=9,
        fontName='Courier',
        backColor=colors.HexColor("#f5f5f5"),
        borderColor=colors.HexColor("#cccccc"),
        borderWidth=1,
        borderPadding=6,
        leftIndent=0,
        rightIndent=0,
        spaceAfter=10
    ))
    
    # Body text justified
    styles.add(ParagraphStyle(
        name='BodyJustified',
        parent=styles['BodyText'],
        fontSize=11,
        alignment=TA_JUSTIFY,
        spaceAfter=12
    ))
    
    return styles

def create_cover_page(styles):
    """Create a professional cover page"""
    elements = []
    
    # Add some space at the top
    elements.append(Spacer(1, 2*inch))
    
    # Main title
    elements.append(Paragraph("AXI4 Verification IP", styles['CustomTitle']))
    elements.append(Paragraph("User Guide", styles['Subtitle']))
    
    elements.append(Spacer(1, 0.5*inch))
    
    # Version info box
    version_data = [
        ['Version:', '2.0'],
        ['Date:', datetime.now().strftime('%B %Y')],
        ['Status:', 'Production Release']
    ]
    
    version_table = Table(version_data, colWidths=[2*inch, 3*inch])
    version_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 12),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.HexColor("#003366")),
        ('LINEBELOW', (0, 0), (-1, -1), 1, colors.HexColor("#cccccc")),
        ('TOPPADDING', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
    ]))
    
    elements.append(version_table)
    elements.append(Spacer(1, 1.5*inch))
    
    # Features box
    features = [
        "• Scalable bus matrix support (4x4 to 64x64 and beyond)",
        "• Comprehensive test suite with 113+ test cases",
        "• Full AXI4 protocol compliance (IHI0022D)",
        "• Advanced protocol violation detection",
        "• Performance monitoring and coverage collection",
        "• LSF support for distributed regression"
    ]
    
    for feature in features:
        elements.append(Paragraph(feature, styles['BodyText']))
    
    elements.append(PageBreak())
    
    return elements

def create_toc(styles):
    """Create table of contents"""
    elements = []
    
    elements.append(Paragraph("Table of Contents", styles['ChapterHeading']))
    elements.append(Spacer(1, 0.5*inch))
    
    # TOC entries
    toc_data = [
        ['1. Introduction', '4'],
        ['2. Getting Started', '6'],
        ['3. Architecture Overview', '9'],
        ['4. Configuration Guide', '12'],
        ['5. Running Tests', '18'],
        ['6. Test Development', '24'],
        ['7. Scalability Features', '30'],
        ['8. Troubleshooting', '36'],
        ['9. Best Practices', '40'],
        ['10. API Reference', '44']
    ]
    
    for entry in toc_data:
        # Create dots between title and page number
        dots = '.' * (80 - len(entry[0]) - len(entry[1]))
        toc_line = f"{entry[0]} {dots} {entry[1]}"
        elements.append(Paragraph(toc_line, styles['BodyText']))
    
    elements.append(PageBreak())
    
    return elements

def create_introduction_chapter(styles):
    """Create introduction chapter"""
    elements = []
    
    elements.append(Paragraph("1. Introduction", styles['ChapterHeading']))
    
    intro_text = """
    The AXI4 Verification IP (VIP) is a state-of-the-art verification solution designed to ensure 
    comprehensive testing of AXI4 protocol implementations. Built on the industry-standard Universal 
    Verification Methodology (UVM), this VIP provides a robust framework for verifying AXI4 interfaces 
    in modern System-on-Chip (SoC) designs.
    """
    elements.append(Paragraph(intro_text, styles['BodyJustified']))
    
    elements.append(Paragraph("1.1 Key Benefits", styles['SectionHeading']))
    
    benefits = [
        "<b>Scalability:</b> Supports bus matrices from 4x4 to 64x64 and beyond without code modifications",
        "<b>Comprehensive Coverage:</b> 113+ test cases covering all aspects of AXI4 protocol",
        "<b>Easy Integration:</b> Standard UVM architecture ensures compatibility with existing environments",
        "<b>Performance:</b> Optimized for fast simulation with parallel test execution support",
        "<b>Debugging:</b> Advanced error reporting and protocol violation detection"
    ]
    
    for benefit in benefits:
        elements.append(Paragraph(f"• {benefit}", styles['BodyText']))
        
    elements.append(Spacer(1, 0.3*inch))
    
    elements.append(Paragraph("1.2 Supported Features", styles['SectionHeading']))
    
    # Feature table
    feature_data = [
        ['Feature', 'Support'],
        ['AXI4 Protocol Version', 'IHI0022D'],
        ['Data Width', '8, 16, 32, 64, 128, 256, 512, 1024 bits'],
        ['Address Width', 'Up to 64 bits'],
        ['Burst Types', 'FIXED, INCR, WRAP'],
        ['Burst Length', '1-256 beats (AXI4), 1-16 beats (AXI3)'],
        ['Outstanding Transactions', 'Configurable per master'],
        ['Exclusive Access', 'Full support with monitor'],
        ['QoS', '4-bit priority support'],
        ['User Signals', 'Configurable width']
    ]
    
    feature_table = Table(feature_data, colWidths=[3*inch, 3*inch])
    feature_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#003366")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0f0f0")]),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    elements.append(feature_table)
    
    return elements

def create_getting_started_chapter(styles):
    """Create Getting Started chapter"""
    elements = []
    
    elements.append(PageBreak())
    elements.append(Paragraph("2. Getting Started", styles['ChapterHeading']))
    
    elements.append(Paragraph("2.1 System Requirements", styles['SectionHeading']))
    
    req_data = [
        ['Component', 'Requirement'],
        ['Operating System', 'Linux (RHEL 7+, Ubuntu 18.04+, CentOS 7+)'],
        ['Simulator', 'Synopsys VCS 2024.09 or later'],
        ['UVM Version', 'UVM 1.2'],
        ['Memory', 'Minimum 16GB RAM (32GB recommended)'],
        ['Disk Space', '10GB for installation + simulation data'],
        ['Python', 'Version 3.6 or later'],
        ['LSF (Optional)', 'For distributed regression runs']
    ]
    
    req_table = Table(req_data, colWidths=[2.5*inch, 3.5*inch])
    req_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#003366")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0f0f0")]),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    elements.append(req_table)
    elements.append(Spacer(1, 0.3*inch))
    
    elements.append(Paragraph("2.2 Quick Start Guide", styles['SectionHeading']))
    
    quick_steps = [
        "<b>Step 1: Clone the Repository</b>",
        "git clone https://github.com/your-org/axi4_vip.git<br/>cd axi4_vip",
        
        "<b>Step 2: Set Up Environment</b>",
        "source setup_env.sh<br/>cd sim/synopsys_sim",
        
        "<b>Step 3: Run Your First Test</b>",
        "make TEST=axi4_write_read_test",
        
        "<b>Step 4: View Results</b>",
        "Check the log file: axi4_write_read_test.log"
    ]
    
    for i in range(0, len(quick_steps), 2):
        elements.append(Paragraph(quick_steps[i], styles['BodyText']))
        elements.append(Paragraph(quick_steps[i+1], styles['Code']))
        elements.append(Spacer(1, 0.1*inch))
    
    elements.append(Paragraph("2.3 Directory Structure", styles['SectionHeading']))
    
    dir_structure = """
tim_axi4_vip/
├── doc/              # Documentation
├── env/              # Environment components
├── include/          # Configuration headers
├── master/           # Master agent
├── slave/            # Slave agent
├── seq/              # Test sequences
├── test/             # Test cases
├── sim/              # Simulation scripts
└── bm/               # Bus matrix model
    """
    
    elements.append(Paragraph(dir_structure, styles['Code']))
    
    return elements

def create_configuration_chapter(styles):
    """Create configuration chapter"""
    elements = []
    
    elements.append(PageBreak())
    elements.append(Paragraph("4. Configuration Guide", styles['ChapterHeading']))
    
    elements.append(Paragraph("4.1 Bus Matrix Configuration", styles['SectionHeading']))
    
    config_text = """
    The AXI4 VIP uses a centralized configuration file located at include/axi4_bus_config.svh. 
    This file controls the bus matrix size and ID mapping strategy. The configuration is applied 
    at compile time for optimal performance.
    """
    elements.append(Paragraph(config_text, styles['BodyJustified']))
    
    elements.append(Paragraph("Configuration Parameters:", styles['BodyText']))
    
    # Configuration code
    config_code = """
// Bus matrix size configuration
`define NUM_MASTERS 4      // Number of masters
`define NUM_SLAVES 4       // Number of slaves  
`define ID_MAP_BITS 4      // ID width for mapping

// Scalable ID mapping macros
`define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
`define GET_EFFECTIVE_ARID(master_id) ((master_id) % `ID_MAP_BITS)
    """
    
    elements.append(Paragraph(config_code, styles['Code']))
    
    elements.append(Paragraph("4.2 Supported Configurations", styles['SectionHeading']))
    
    config_data = [
        ['Configuration', 'Masters', 'Slaves', 'ID Bits', 'Use Case'],
        ['BASE_BUS_MATRIX', '4', '4', '4', 'Small SoCs, IoT devices'],
        ['ENHANCED_BUS_MATRIX', '10', '10', '16', 'Medium complexity SoCs'],
        ['LARGE_BUS_MATRIX', '64', '64', '64', 'Data centers, AI chips'],
        ['CUSTOM', 'N', 'M', 'Config', 'User-defined architectures']
    ]
    
    config_table = Table(config_data, colWidths=[2*inch, 0.8*inch, 0.8*inch, 0.8*inch, 2*inch])
    config_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#003366")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('ALIGN', (4, 1), (4, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0f0f0")]),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    
    elements.append(config_table)
    
    elements.append(Spacer(1, 0.3*inch))
    elements.append(Paragraph("4.3 ID Mapping Strategy", styles['SectionHeading']))
    
    mapping_text = """
    For bus matrices larger than 16x16, the VIP uses modulo mapping to ensure compatibility 
    with the 16 available AXI ID enums (AWID_0 through AWID_15). This approach provides:
    """
    elements.append(Paragraph(mapping_text, styles['BodyJustified']))
    
    benefits = [
        "• Automatic scaling for any bus size",
        "• No code changes required when switching configurations",
        "• Predictable ID distribution",
        "• Optimal performance through compile-time resolution"
    ]
    
    for benefit in benefits:
        elements.append(Paragraph(benefit, styles['BodyText']))
    
    return elements

def create_comprehensive_guide():
    """Create the comprehensive user guide PDF"""
    doc = SimpleDocTemplate(
        "AXI4_VIP_User_Guide.pdf",
        pagesize=letter,
        rightMargin=inch,
        leftMargin=inch,
        topMargin=1.25*inch,
        bottomMargin=inch
    )
    
    styles = create_styles()
    elements = []
    
    # Cover page
    elements.extend(create_cover_page(styles))
    
    # Table of contents
    elements.extend(create_toc(styles))
    
    # Chapters
    elements.extend(create_introduction_chapter(styles))
    elements.extend(create_getting_started_chapter(styles))
    elements.extend(create_configuration_chapter(styles))
    
    # Build PDF
    doc.build(elements, canvasmaker=PageNumCanvas)
    
    print("✅ Generated: AXI4_VIP_User_Guide.pdf")

def create_quick_start_guide():
    """Create a concise quick start guide"""
    doc = SimpleDocTemplate(
        "AXI4_VIP_Quick_Start_Guide.pdf",
        pagesize=letter,
        rightMargin=inch,
        leftMargin=inch,
        topMargin=1.25*inch,
        bottomMargin=inch
    )
    
    styles = create_styles()
    elements = []
    
    # Title
    elements.append(Paragraph("AXI4 VIP Quick Start Guide", styles['CustomTitle']))
    elements.append(Paragraph("Get up and running in 5 minutes", styles['Subtitle']))
    elements.append(Spacer(1, 0.5*inch))
    
    # Prerequisites box
    prereq_data = [
        ['Prerequisites', ''],
        ['✓ Linux system', '✓ Python 3.6+'],
        ['✓ Synopsys VCS 2024.09+', '✓ UVM 1.2'],
    ]
    
    prereq_table = Table(prereq_data, colWidths=[3*inch, 3*inch])
    prereq_table.setStyle(TableStyle([
        ('SPAN', (0, 0), (-1, 0)),
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#e6f2ff")),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 11),
        ('BOX', (0, 0), (-1, -1), 2, colors.HexColor("#003366")),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 12),
    ]))
    
    elements.append(prereq_table)
    elements.append(Spacer(1, 0.3*inch))
    
    # Quick steps
    elements.append(Paragraph("Quick Setup", styles['ChapterHeading']))
    
    steps = [
        ("1. Clone Repository", "git clone <repository_url>\ncd tim_axi4_vip"),
        ("2. Configure Bus Size (Optional)", "# Edit include/axi4_bus_config.svh\n`define NUM_MASTERS 10  # For 10x10 matrix"),
        ("3. Run Test", "cd sim/synopsys_sim\nmake TEST=axi4_write_read_test"),
        ("4. Run Regression", "python3 axi4_regression_makefile.py \\\n  --test-list axi4_transfers_regression.list --cov")
    ]
    
    for title, code in steps:
        elements.append(Paragraph(title, styles['SectionHeading']))
        elements.append(Paragraph(code, styles['Code']))
        elements.append(Spacer(1, 0.2*inch))
    
    # Common commands table
    elements.append(PageBreak())
    elements.append(Paragraph("Common Commands", styles['ChapterHeading']))
    
    cmd_data = [
        ['Task', 'Command'],
        ['Run single test', 'make TEST=<test_name>'],
        ['Run with waves', 'make TEST=<test_name> WAVES=1'],
        ['Clean build', 'make clean'],
        ['Run regression', 'python3 axi4_regression_makefile.py --test-list <list>'],
        ['Run with LSF', 'python3 axi4_regression_makefile.py --test-list <list> --lsf'],
        ['View coverage', 'dve -cov -dir regression_result_*/coverage_collect/merged_coverage.vdb']
    ]
    
    cmd_table = Table(cmd_data, colWidths=[2.5*inch, 3.5*inch])
    cmd_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#003366")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (1, 1), (1, -1), 'Courier'),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0f0f0")]),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    elements.append(cmd_table)
    
    elements.append(Spacer(1, 0.3*inch))
    
    # Tips box
    elements.append(Paragraph("Pro Tips", styles['ChapterHeading']))
    
    tips = [
        "💡 Always include `include \"axi4_bus_config.svh\"` in new sequences",
        "💡 Use scalable ID macros: `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id))`",
        "💡 Check logs in regression_result_*/logs/no_pass_logs/ for failures",
        "💡 Run make clean before switching bus matrix configurations",
        "💡 Use --parallel option for faster regression runs"
    ]
    
    for tip in tips:
        elements.append(Paragraph(tip, styles['BodyText']))
    
    # Support info
    elements.append(Spacer(1, 0.5*inch))
    support_text = """
    <b>Need Help?</b><br/>
    📧 Email: axi4_vip_support@company.com<br/>
    📚 Full Documentation: doc/AXI4_VIP_User_Guide.pdf<br/>
    🐛 Report Issues: https://github.com/your-org/axi4_vip/issues
    """
    elements.append(Paragraph(support_text, ParagraphStyle(
        'Support',
        parent=styles['BodyText'],
        fontSize=10,
        backColor=colors.HexColor("#fffacd"),
        borderColor=colors.HexColor("#ffd700"),
        borderWidth=1,
        borderPadding=10
    )))
    
    # Build PDF
    doc.build(elements, canvasmaker=PageNumCanvas)
    
    print("✅ Generated: AXI4_VIP_Quick_Start_Guide.pdf")

if __name__ == "__main__":
    # Generate both PDFs
    create_comprehensive_guide()
    create_quick_start_guide()
    
    print("\n📄 PDF generation complete!")
    print("   - AXI4_VIP_User_Guide.pdf (Comprehensive guide)")
    print("   - AXI4_VIP_Quick_Start_Guide.pdf (Quick reference)")