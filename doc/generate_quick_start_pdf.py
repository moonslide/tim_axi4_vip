#!/usr/bin/env python3
"""
Generate AXI4 VIP Quick Start Guide as a professional PDF-ready document
"""

import os
from datetime import datetime

def create_quick_start_pdf():
    """Create a professional quick start guide"""
    
    html_content = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>AXI4 VIP Quick Start Guide</title>
    <style>
        @page {
            size: letter;
            margin: 0.75in;
            @top-right {
                content: "AXI4 VIP v2.0";
                font-size: 10pt;
                color: #666;
            }
            @bottom-center {
                content: "Page " counter(page) " of " counter(pages);
                font-size: 10pt;
            }
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 8.5in;
            margin: 0 auto;
            padding: 0;
        }
        
        /* Cover page */
        .cover {
            page-break-after: always;
            text-align: center;
            padding-top: 2in;
        }
        
        .cover h1 {
            font-size: 48pt;
            color: #003366;
            margin-bottom: 0.5in;
            font-weight: 300;
            letter-spacing: -2px;
        }
        
        .cover .subtitle {
            font-size: 24pt;
            color: #666;
            margin-bottom: 1in;
            font-weight: 300;
        }
        
        .cover .version-box {
            display: inline-block;
            border: 3px solid #003366;
            border-radius: 10px;
            padding: 30px 60px;
            background: linear-gradient(135deg, #f0f8ff 0%, #e6f2ff 100%);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .cover .version-box h2 {
            color: #003366;
            margin: 0 0 10px 0;
            font-size: 18pt;
        }
        
        .cover .version-box p {
            margin: 5px 0;
            font-size: 14pt;
            color: #555;
        }
        
        /* Content styling */
        h1 {
            color: #003366;
            font-size: 28pt;
            margin-top: 0;
            padding-bottom: 10px;
            border-bottom: 3px solid #003366;
            page-break-before: always;
        }
        
        h1:first-of-type {
            page-break-before: avoid;
        }
        
        h2 {
            color: #004080;
            font-size: 20pt;
            margin-top: 30px;
            margin-bottom: 15px;
        }
        
        h3 {
            color: #0066cc;
            font-size: 16pt;
            margin-top: 20px;
            margin-bottom: 10px;
        }
        
        /* Quick reference cards */
        .card {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            page-break-inside: avoid;
        }
        
        .card h3 {
            margin-top: 0;
            color: #003366;
        }
        
        /* Code blocks */
        pre {
            background: #f5f5f5;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            font-family: 'Courier New', Consolas, monospace;
            font-size: 10pt;
            line-height: 1.4;
            overflow-x: auto;
            page-break-inside: avoid;
        }
        
        code {
            background: #f0f0f0;
            padding: 2px 5px;
            border-radius: 3px;
            font-family: 'Courier New', Consolas, monospace;
            font-size: 10pt;
        }
        
        /* Tables */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            page-break-inside: avoid;
        }
        
        th {
            background: #003366;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        
        td {
            border: 1px solid #ddd;
            padding: 10px;
        }
        
        tr:nth-child(even) {
            background: #f8f9fa;
        }
        
        /* Tips and warnings */
        .tip, .warning, .info {
            padding: 15px 20px;
            margin: 20px 0;
            border-radius: 5px;
            page-break-inside: avoid;
        }
        
        .tip {
            background: #f0f8e8;
            border-left: 5px solid #8bc34a;
        }
        
        .warning {
            background: #fff3cd;
            border-left: 5px solid #ffc107;
        }
        
        .info {
            background: #e3f2fd;
            border-left: 5px solid #2196f3;
        }
        
        .tip::before {
            content: "💡 TIP: ";
            font-weight: bold;
            color: #689f38;
        }
        
        .warning::before {
            content: "⚠️ WARNING: ";
            font-weight: bold;
            color: #f57c00;
        }
        
        .info::before {
            content: "ℹ️ INFO: ";
            font-weight: bold;
            color: #1976d2;
        }
        
        /* Lists */
        ul, ol {
            margin: 15px 0;
            padding-left: 30px;
        }
        
        li {
            margin: 8px 0;
        }
        
        /* Quick command reference */
        .cmd-ref {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 15px;
            background: #f8f9fa;
            border-left: 3px solid #003366;
            margin: 10px 0;
        }
        
        .cmd-ref .desc {
            font-weight: 500;
            color: #333;
        }
        
        .cmd-ref .cmd {
            font-family: 'Courier New', monospace;
            background: #fff;
            padding: 5px 10px;
            border: 1px solid #ddd;
            border-radius: 3px;
            font-size: 9pt;
        }
        
        /* Print optimization */
        @media print {
            body {
                font-size: 11pt;
            }
            
            .cover {
                height: 100vh;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
            }
            
            pre {
                font-size: 9pt;
                border: 1px solid #ccc;
            }
            
            .card {
                border: 1px solid #ccc;
            }
        }
    </style>
</head>
<body>

<!-- Cover Page -->
<div class="cover">
    <h1>AXI4 VIP</h1>
    <div class="subtitle">Quick Start Guide</div>
    <div class="version-box">
        <h2>Version 2.0</h2>
        <p>Get Started in 5 Minutes!</p>
        <p>""" + datetime.now().strftime("%B %Y") + """</p>
    </div>
</div>

<!-- Prerequisites -->
<h1>Prerequisites</h1>

<div class="card">
    <h3>System Requirements</h3>
    <table>
        <tr>
            <td><strong>✓ Operating System</strong></td>
            <td>Linux (RHEL 7+, Ubuntu 18.04+, CentOS 7+)</td>
        </tr>
        <tr>
            <td><strong>✓ Simulator</strong></td>
            <td>Synopsys VCS 2024.09 or later</td>
        </tr>
        <tr>
            <td><strong>✓ UVM Library</strong></td>
            <td>UVM 1.2</td>
        </tr>
        <tr>
            <td><strong>✓ Python</strong></td>
            <td>Version 3.6 or later</td>
        </tr>
        <tr>
            <td><strong>✓ Memory</strong></td>
            <td>16GB RAM minimum</td>
        </tr>
    </table>
</div>

<!-- Quick Setup -->
<h1>Quick Setup</h1>

<h2>Step 1: Clone Repository</h2>
<pre>
git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip
</pre>

<h2>Step 2: Configure Environment</h2>
<pre>
source setup_env.sh
cd sim/synopsys_sim
</pre>

<h2>Step 3: Configure Bus Matrix (Optional)</h2>
<div class="info">
The default configuration is 4x4 (4 masters, 4 slaves). To change, edit <code>include/axi4_bus_config.svh</code>
</div>

<pre>
// For 10x10 bus matrix
`define NUM_MASTERS 10
`define NUM_SLAVES  10
`define ID_MAP_BITS 16

// For 64x64 bus matrix
`define NUM_MASTERS 64
`define NUM_SLAVES  64
`define ID_MAP_BITS 64
</pre>

<h2>Step 4: Run Your First Test</h2>
<pre>
make TEST=axi4_write_read_test
</pre>

<div class="tip">
Check the log file for results: <code>grep "TEST PASSED" axi4_write_read_test.log</code>
</div>

<!-- Common Commands -->
<h1>Common Commands</h1>

<div class="card">
    <h3>Test Execution</h3>
    
    <div class="cmd-ref">
        <span class="desc">Run single test</span>
        <span class="cmd">make TEST=test_name</span>
    </div>
    
    <div class="cmd-ref">
        <span class="desc">Run with waveforms</span>
        <span class="cmd">make TEST=test_name WAVES=1</span>
    </div>
    
    <div class="cmd-ref">
        <span class="desc">Run with specific seed</span>
        <span class="cmd">make TEST=test_name SEED=12345</span>
    </div>
    
    <div class="cmd-ref">
        <span class="desc">Clean build</span>
        <span class="cmd">make clean</span>
    </div>
</div>

<div class="card">
    <h3>Regression Testing</h3>
    
    <div class="cmd-ref">
        <span class="desc">Run regression locally</span>
        <span class="cmd">python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list</span>
    </div>
    
    <div class="cmd-ref">
        <span class="desc">Run with coverage</span>
        <span class="cmd">python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov</span>
    </div>
    
    <div class="cmd-ref">
        <span class="desc">Run with LSF (parallel)</span>
        <span class="cmd">python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --lsf --parallel 10</span>
    </div>
    
    <div class="cmd-ref">
        <span class="desc">View coverage report</span>
        <span class="cmd">dve -cov -dir regression_result_*/coverage_collect/merged_coverage.vdb</span>
    </div>
</div>

<!-- Test Categories -->
<h1>Test Categories</h1>

<table>
    <tr>
        <th>Category</th>
        <th>Test Prefix</th>
        <th>Description</th>
        <th>Example</th>
    </tr>
    <tr>
        <td><strong>Basic Transfer</strong></td>
        <td>axi4_write_*, axi4_read_*</td>
        <td>Basic read/write operations</td>
        <td>axi4_write_read_test</td>
    </tr>
    <tr>
        <td><strong>Burst Tests</strong></td>
        <td>axi4_*_burst_*</td>
        <td>INCR, WRAP, FIXED bursts</td>
        <td>axi4_blocking_incr_burst_test</td>
    </tr>
    <tr>
        <td><strong>Protocol Tests</strong></td>
        <td>axi4_tc_046_* to axi4_tc_058_*</td>
        <td>Protocol compliance</td>
        <td>axi4_tc_047_id_multiple_writes_test</td>
    </tr>
    <tr>
        <td><strong>Boundary Tests</strong></td>
        <td>axi4_*_boundary_*</td>
        <td>Address boundaries</td>
        <td>axi4_lower_boundary_write_test</td>
    </tr>
    <tr>
        <td><strong>Error Tests</strong></td>
        <td>axi4_*_error_*</td>
        <td>Error responses</td>
        <td>axi4_slave_error_test</td>
    </tr>
</table>

<!-- Best Practices -->
<h1>Best Practices</h1>

<div class="card">
    <h3>Essential Guidelines</h3>
    
    <ol>
        <li><strong>Always include bus configuration header</strong>
            <pre>`include "axi4_bus_config.svh"</pre>
        </li>
        
        <li><strong>Use scalable ID mapping macros</strong>
            <pre>awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id));</pre>
            <div class="warning">Never hardcode ID values like <code>awid == AWID_2</code></div>
        </li>
        
        <li><strong>Clean before configuration changes</strong>
            <pre>make clean  # Always run when changing bus matrix size</pre>
        </li>
        
        <li><strong>Check regression logs for failures</strong>
            <pre>cd regression_result_*/logs/no_pass_logs/
ls *.log  # List failed tests</pre>
        </li>
        
        <li><strong>Use parallel execution for speed</strong>
            <pre>--parallel 10  # Run 10 tests simultaneously</pre>
        </li>
    </ol>
</div>

<!-- Troubleshooting -->
<h1>Quick Troubleshooting</h1>

<table>
    <tr>
        <th>Issue</th>
        <th>Solution</th>
    </tr>
    <tr>
        <td>ID mismatch errors</td>
        <td>Check ID is within valid range for bus configuration</td>
    </tr>
    <tr>
        <td>SLVERR responses</td>
        <td>Verify master-slave access permissions</td>
    </tr>
    <tr>
        <td>Compilation errors</td>
        <td>Ensure <code>axi4_bus_config.svh</code> is included</td>
    </tr>
    <tr>
        <td>Test timeouts</td>
        <td>Check for deadlocks in sequences, increase timeout</td>
    </tr>
    <tr>
        <td>Coverage merge fails</td>
        <td>Ensure all tests completed before merging</td>
    </tr>
</table>

<div class="tip">
Enable debug messages with: <code>+UVM_VERBOSITY=UVM_HIGH</code>
</div>

<!-- Support -->
<h1>Getting Help</h1>

<div class="card">
    <h3>Resources</h3>
    <ul>
        <li><strong>Full Documentation:</strong> <code>doc/AXI4_VIP_User_Guide.pdf</code></li>
        <li><strong>Architecture Guide:</strong> <code>doc/axi4_avip_architecture_document.pdf</code></li>
        <li><strong>Example Tests:</strong> <code>seq/master_sequences/</code></li>
        <li><strong>Email Support:</strong> axi4_vip_support@company.com</li>
        <li><strong>Issue Tracker:</strong> https://github.com/your-org/axi4_vip/issues</li>
    </ul>
</div>

<div class="info">
<strong>Pro Tip:</strong> Start with the example tests in <code>test/</code> directory and modify them for your needs.
</div>

<!-- Footer -->
<div style="text-align: center; margin-top: 50px; padding-top: 20px; border-top: 1px solid #ddd; color: #666;">
    <p>AXI4 Verification IP v2.0 | © 2025 AXI4 VIP Development Team</p>
</div>

</body>
</html>
"""
    
    # Save the HTML file
    with open("AXI4_VIP_Quick_Start_Professional.html", "w") as f:
        f.write(html_content)
    
    print("✅ Generated: AXI4_VIP_Quick_Start_Professional.html")
    print("\n📄 This is a print-optimized quick start guide.")
    print("   To create PDF: Open in browser → Print → Save as PDF")
    print("   Recommended print settings:")
    print("   - Paper size: Letter")
    print("   - Margins: Default")
    print("   - Scale: Fit to page")
    print("   - Background graphics: ON")

if __name__ == "__main__":
    create_quick_start_pdf()