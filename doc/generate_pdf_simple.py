#!/usr/bin/env python3
"""
Generate PDF documentation using markdown and basic HTML/CSS
This version has minimal dependencies
"""

import os
from datetime import datetime

def generate_html_guide(filename, title, content):
    """Generate an HTML file that can be converted to PDF"""
    
    html_template = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>{title}</title>
    <style>
        @page {{
            size: letter;
            margin: 1in;
            @bottom-right {{
                content: "Page " counter(page) " of " counter(pages);
            }}
        }}
        
        body {{
            font-family: 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }}
        
        h1 {{
            color: #003366;
            border-bottom: 3px solid #003366;
            padding-bottom: 10px;
            page-break-before: always;
        }}
        
        h1:first-child {{
            page-break-before: avoid;
        }}
        
        h2 {{
            color: #004080;
            margin-top: 30px;
        }}
        
        h3 {{
            color: #0066cc;
            margin-top: 20px;
        }}
        
        .cover {{
            text-align: center;
            page-break-after: always;
            padding-top: 100px;
        }}
        
        .cover h1 {{
            font-size: 48px;
            border: none;
            margin-bottom: 20px;
        }}
        
        .cover .subtitle {{
            font-size: 24px;
            color: #666;
            margin-bottom: 50px;
        }}
        
        .version-box {{
            display: inline-block;
            border: 2px solid #003366;
            padding: 20px 40px;
            margin-top: 50px;
            background-color: #f0f8ff;
        }}
        
        code {{
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }}
        
        pre {{
            background-color: #f5f5f5;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            overflow-x: auto;
            line-height: 1.4;
        }}
        
        pre code {{
            background-color: transparent;
            padding: 0;
        }}
        
        table {{
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
        }}
        
        th {{
            background-color: #003366;
            color: white;
            padding: 12px;
            text-align: left;
        }}
        
        td {{
            border: 1px solid #ddd;
            padding: 10px;
        }}
        
        tr:nth-child(even) {{
            background-color: #f9f9f9;
        }}
        
        .tip {{
            background-color: #fffacd;
            border-left: 4px solid #ffd700;
            padding: 10px 15px;
            margin: 20px 0;
        }}
        
        .warning {{
            background-color: #ffe4e1;
            border-left: 4px solid #ff6b6b;
            padding: 10px 15px;
            margin: 20px 0;
        }}
        
        .info {{
            background-color: #e6f3ff;
            border-left: 4px solid #0066cc;
            padding: 10px 15px;
            margin: 20px 0;
        }}
        
        ul, ol {{
            margin: 15px 0;
            padding-left: 30px;
        }}
        
        li {{
            margin: 5px 0;
        }}
        
        .toc {{
            background-color: #f8f8f8;
            border: 1px solid #ddd;
            padding: 20px;
            margin: 30px 0;
            page-break-after: always;
        }}
        
        .toc h2 {{
            margin-top: 0;
        }}
        
        .toc ul {{
            list-style-type: none;
            padding-left: 0;
        }}
        
        .toc li {{
            margin: 8px 0;
        }}
        
        .toc a {{
            color: #003366;
            text-decoration: none;
        }}
        
        .toc a:hover {{
            text-decoration: underline;
        }}
        
        @media print {{
            body {{
                margin: 0;
                padding: 0;
            }}
            
            h1 {{
                page-break-before: always;
            }}
            
            h1:first-child {{
                page-break-before: avoid;
            }}
            
            pre, table {{
                page-break-inside: avoid;
            }}
        }}
    </style>
</head>
<body>
{content}
</body>
</html>
"""
    
    with open(filename, 'w') as f:
        f.write(html_template.format(title=title, content=content))
    
    print(f"✅ Generated: {filename}")

def create_comprehensive_guide():
    """Create the comprehensive user guide"""
    
    content = """
<div class="cover">
    <h1>AXI4 Verification IP</h1>
    <div class="subtitle">Comprehensive User Guide</div>
    <div class="version-box">
        <strong>Version 2.0</strong><br>
        July 2025<br>
        Production Release
    </div>
</div>

<div class="toc">
    <h2>Table of Contents</h2>
    <ul>
        <li>1. <a href="#introduction">Introduction</a></li>
        <li>2. <a href="#getting-started">Getting Started</a></li>
        <li>3. <a href="#architecture">Architecture Overview</a></li>
        <li>4. <a href="#configuration">Configuration Guide</a></li>
        <li>5. <a href="#running-tests">Running Tests</a></li>
        <li>6. <a href="#test-development">Test Development</a></li>
        <li>7. <a href="#scalability">Scalability Features</a></li>
        <li>8. <a href="#troubleshooting">Troubleshooting</a></li>
        <li>9. <a href="#best-practices">Best Practices</a></li>
        <li>10. <a href="#api-reference">API Reference</a></li>
    </ul>
</div>

<h1 id="introduction">1. Introduction</h1>

<p>The AXI4 Verification IP (VIP) is a state-of-the-art verification solution designed to ensure comprehensive testing of AXI4 protocol implementations. Built on the industry-standard Universal Verification Methodology (UVM), this VIP provides a robust framework for verifying AXI4 interfaces in modern System-on-Chip (SoC) designs.</p>

<h2>1.1 Key Features</h2>

<ul>
    <li><strong>Scalable Architecture:</strong> Supports bus matrices from 4x4 to 64x64 and beyond</li>
    <li><strong>Comprehensive Coverage:</strong> 113+ test cases covering all AXI4 protocol aspects</li>
    <li><strong>UVM Compliant:</strong> Built using UVM 1.2 best practices</li>
    <li><strong>Protocol Compliance:</strong> Full IHI0022D specification support</li>
    <li><strong>Advanced Features:</strong> QoS, exclusive access, and protocol violation detection</li>
    <li><strong>Performance:</strong> Optimized for simulation speed with parallel test support</li>
</ul>

<h2>1.2 Supported Configurations</h2>

<table>
    <tr>
        <th>Feature</th>
        <th>Specification</th>
    </tr>
    <tr>
        <td>Protocol Version</td>
        <td>AXI4 (IHI0022D)</td>
    </tr>
    <tr>
        <td>Data Width</td>
        <td>8, 16, 32, 64, 128, 256, 512, 1024 bits</td>
    </tr>
    <tr>
        <td>Address Width</td>
        <td>Up to 64 bits</td>
    </tr>
    <tr>
        <td>Burst Types</td>
        <td>FIXED, INCR, WRAP</td>
    </tr>
    <tr>
        <td>Outstanding Transactions</td>
        <td>Configurable per master</td>
    </tr>
    <tr>
        <td>Bus Matrix Size</td>
        <td>4x4 to 64x64 (configurable)</td>
    </tr>
</table>

<h1 id="getting-started">2. Getting Started</h1>

<h2>2.1 System Requirements</h2>

<table>
    <tr>
        <th>Component</th>
        <th>Requirement</th>
    </tr>
    <tr>
        <td>Operating System</td>
        <td>Linux (RHEL 7+, Ubuntu 18.04+, CentOS 7+)</td>
    </tr>
    <tr>
        <td>Simulator</td>
        <td>Synopsys VCS 2024.09 or later</td>
    </tr>
    <tr>
        <td>UVM Version</td>
        <td>UVM 1.2</td>
    </tr>
    <tr>
        <td>Memory</td>
        <td>Minimum 16GB RAM (32GB recommended)</td>
    </tr>
    <tr>
        <td>Python</td>
        <td>Version 3.6 or later</td>
    </tr>
</table>

<h2>2.2 Installation</h2>

<pre><code># Clone the repository
git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip

# Set up environment
source setup_env.sh

# Navigate to simulation directory
cd sim/synopsys_sim</code></pre>

<h2>2.3 Quick Test Run</h2>

<pre><code># Run a simple write-read test
make TEST=axi4_write_read_test

# Check results
cat axi4_write_read_test.log | grep "TEST PASSED"</code></pre>

<h1 id="architecture">3. Architecture Overview</h1>

<h2>3.1 Component Hierarchy</h2>

<pre><code>axi4_env
├── axi4_master_agent[0..N-1]
│   ├── axi4_master_driver
│   ├── axi4_master_monitor
│   └── axi4_master_sequencer
├── axi4_slave_agent[0..N-1]
│   ├── axi4_slave_driver
│   ├── axi4_slave_monitor
│   └── axi4_slave_sequencer
├── axi4_scoreboard
├── axi4_coverage
└── axi4_bus_matrix</code></pre>

<h2>3.2 Directory Structure</h2>

<pre><code>tim_axi4_vip/
├── doc/              # Documentation
├── env/              # Environment components
├── include/          # Configuration headers
├── master/           # Master agent
├── slave/            # Slave agent
├── seq/              # Test sequences
├── test/             # Test cases
├── sim/              # Simulation scripts
└── bm/               # Bus matrix model</code></pre>

<h1 id="configuration">4. Configuration Guide</h1>

<h2>4.1 Bus Matrix Configuration</h2>

<p>The VIP configuration is controlled by <code>include/axi4_bus_config.svh</code>:</p>

<pre><code>// Configure bus matrix size
`define NUM_MASTERS 4      // Number of masters
`define NUM_SLAVES 4       // Number of slaves
`define ID_MAP_BITS 4      // ID width for mapping

// Scalable ID mapping macros
`define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
`define GET_EFFECTIVE_ARID(master_id) ((master_id) % `ID_MAP_BITS)</code></pre>

<h2>4.2 Supported Configurations</h2>

<table>
    <tr>
        <th>Configuration</th>
        <th>Masters</th>
        <th>Slaves</th>
        <th>Use Case</th>
    </tr>
    <tr>
        <td>BASE_BUS_MATRIX</td>
        <td>4</td>
        <td>4</td>
        <td>Small SoCs, IoT devices</td>
    </tr>
    <tr>
        <td>ENHANCED_BUS_MATRIX</td>
        <td>10</td>
        <td>10</td>
        <td>Medium complexity SoCs</td>
    </tr>
    <tr>
        <td>LARGE_BUS_MATRIX</td>
        <td>64</td>
        <td>64</td>
        <td>Data centers, AI accelerators</td>
    </tr>
</table>

<div class="info">
<strong>Note:</strong> When changing configurations, always run <code>make clean</code> before recompiling.
</div>

<h1 id="running-tests">5. Running Tests</h1>

<h2>5.1 Single Test Execution</h2>

<pre><code># Basic test run
make TEST=axi4_write_read_test

# With waveform generation
make TEST=axi4_write_read_test WAVES=1

# With specific seed
make TEST=axi4_write_read_test SEED=12345</code></pre>

<h2>5.2 Regression Testing</h2>

<pre><code># Local regression
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list

# With coverage
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov

# Using LSF
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --lsf --parallel 10</code></pre>

<h2>5.3 Regression Options</h2>

<table>
    <tr>
        <th>Option</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>--test-list FILE</td>
        <td>Specify test list file</td>
    </tr>
    <tr>
        <td>--cov</td>
        <td>Enable coverage collection</td>
    </tr>
    <tr>
        <td>--lsf</td>
        <td>Use LSF for distributed execution</td>
    </tr>
    <tr>
        <td>--parallel N</td>
        <td>Run N tests in parallel</td>
    </tr>
    <tr>
        <td>--timeout SECONDS</td>
        <td>Set test timeout (default: 600)</td>
    </tr>
</table>

<h1 id="test-development">6. Test Development</h1>

<h2>6.1 Creating a New Test</h2>

<p>Example test class:</p>

<pre><code>class my_axi4_test extends axi4_base_test;
  `uvm_component_utils(my_axi4_test)
  
  function new(string name = "my_axi4_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    my_axi4_vseq vseq;
    super.run_phase(phase);
    
    vseq = my_axi4_vseq::type_id::create("vseq");
    vseq.start(null);
  endtask
endclass</code></pre>

<h2>6.2 Using Scalable ID Mapping</h2>

<div class="warning">
<strong>Important:</strong> Always include the bus configuration header and use scalable ID macros in your sequences.
</div>

<pre><code>`include "axi4_bus_config.svh"

class my_write_seq extends axi4_master_base_seq;
  task body();
    start_item(req);
    assert(req.randomize() with {
      tx_type == WRITE;
      // Scalable ID assignment
      awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id));
      awaddr inside {[SLAVE_START:SLAVE_END]};
      awlen == 4'hF;  // 16 beats
      awsize == WRITE_4_BYTES;
      awburst == WRITE_INCR;
    });
    finish_item(req);
  endtask
endclass</code></pre>

<h1 id="scalability">7. Scalability Features</h1>

<h2>7.1 ID Mapping Strategy</h2>

<p>The VIP uses modulo-based ID mapping for scalability:</p>

<table>
    <tr>
        <th>Bus Size</th>
        <th>Masters</th>
        <th>Mapping Strategy</th>
    </tr>
    <tr>
        <td>4x4</td>
        <td>4</td>
        <td>Direct mapping (0-3)</td>
    </tr>
    <tr>
        <td>10x10</td>
        <td>10</td>
        <td>Direct mapping (0-9)</td>
    </tr>
    <tr>
        <td>64x64</td>
        <td>64</td>
        <td>Modulo 16 mapping</td>
    </tr>
</table>

<h2>7.2 Configuring for Large Matrices</h2>

<pre><code>// For 64x64 configuration
`define NUM_MASTERS 64
`define NUM_SLAVES 64
`define ID_MAP_BITS 64

// ID mapping automatically handles modulo operation
// Master 17 -> AWID = 17 % 16 = 1 -> AWID_1</code></pre>

<h1 id="troubleshooting">8. Troubleshooting</h1>

<h2>8.1 Common Issues</h2>

<div class="tip">
<strong>Tip:</strong> Always check regression logs in <code>regression_result_*/logs/no_pass_logs/</code> for detailed error messages.
</div>

<table>
    <tr>
        <th>Issue</th>
        <th>Solution</th>
    </tr>
    <tr>
        <td>Master ID mismatch errors</td>
        <td>Ensure IDs are within valid range for bus configuration</td>
    </tr>
    <tr>
        <td>SLVERR responses</td>
        <td>Check master-slave access permissions</td>
    </tr>
    <tr>
        <td>Compilation errors</td>
        <td>Verify axi4_bus_config.svh is included</td>
    </tr>
    <tr>
        <td>Test timeouts</td>
        <td>Check for deadlocks in sequences</td>
    </tr>
</table>

<h2>8.2 Debug Commands</h2>

<pre><code># Enable UVM debug messages
+UVM_VERBOSITY=UVM_HIGH

# Enable phase tracing
+UVM_PHASE_TRACE

# Enable objection tracing
+UVM_OBJECTION_TRACE</code></pre>

<h1 id="best-practices">9. Best Practices</h1>

<h2>9.1 Coding Guidelines</h2>

<ul>
    <li>Always use scalable ID mapping macros</li>
    <li>Include axi4_bus_config.svh in all sequences</li>
    <li>Test with multiple bus configurations</li>
    <li>Use meaningful test and sequence names</li>
    <li>Document test intent with comments</li>
</ul>

<h2>9.2 Performance Tips</h2>

<ul>
    <li>Use parallel regression runs with LSF</li>
    <li>Optimize sequences for minimal simulation time</li>
    <li>Use coverage filtering for faster runs</li>
    <li>Clean build directory regularly</li>
</ul>

<h1 id="api-reference">10. API Reference</h1>

<p>Detailed API documentation is available in the following files:</p>

<ul>
    <li><code>doc/axi4_master_api.html</code> - Master agent API</li>
    <li><code>doc/axi4_slave_api.html</code> - Slave agent API</li>
    <li><code>doc/axi4_sequence_api.html</code> - Sequence library API</li>
</ul>

<div class="info">
<strong>Version:</strong> 2.0<br>
<strong>Date:</strong> July 2025<br>
<strong>Contact:</strong> axi4_vip_support@company.com
</div>
"""
    
    generate_html_guide("AXI4_VIP_User_Guide.html", "AXI4 VIP User Guide", content)

def create_quick_start_guide():
    """Create the quick start guide"""
    
    content = """
<div class="cover">
    <h1>AXI4 VIP</h1>
    <div class="subtitle">Quick Start Guide</div>
    <div class="version-box">
        Get up and running in 5 minutes!
    </div>
</div>

<h1>Prerequisites</h1>

<table>
    <tr>
        <td>✓ Linux system</td>
        <td>✓ Synopsys VCS 2024.09+</td>
    </tr>
    <tr>
        <td>✓ Python 3.6+</td>
        <td>✓ UVM 1.2</td>
    </tr>
</table>

<h1>Quick Setup</h1>

<h2>1. Clone Repository</h2>
<pre><code>git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip</code></pre>

<h2>2. Configure Bus Size (Optional)</h2>
<pre><code># Edit include/axi4_bus_config.svh
`define NUM_MASTERS 10  # For 10x10 matrix
`define NUM_SLAVES 10
`define ID_MAP_BITS 16</code></pre>

<h2>3. Run Your First Test</h2>
<pre><code>cd sim/synopsys_sim
make TEST=axi4_write_read_test</code></pre>

<h2>4. Run Full Regression</h2>
<pre><code>python3 axi4_regression_makefile.py \\
  --test-list axi4_transfers_regression.list --cov</code></pre>

<h1>Common Commands</h1>

<table>
    <tr>
        <th>Task</th>
        <th>Command</th>
    </tr>
    <tr>
        <td>Run single test</td>
        <td><code>make TEST=&lt;test_name&gt;</code></td>
    </tr>
    <tr>
        <td>Run with waves</td>
        <td><code>make TEST=&lt;test_name&gt; WAVES=1</code></td>
    </tr>
    <tr>
        <td>Clean build</td>
        <td><code>make clean</code></td>
    </tr>
    <tr>
        <td>Run regression</td>
        <td><code>python3 axi4_regression_makefile.py --test-list &lt;list&gt;</code></td>
    </tr>
    <tr>
        <td>Run with LSF</td>
        <td><code>python3 axi4_regression_makefile.py --test-list &lt;list&gt; --lsf</code></td>
    </tr>
    <tr>
        <td>View coverage</td>
        <td><code>dve -cov -dir */coverage_collect/merged_coverage.vdb</code></td>
    </tr>
</table>

<h1>Pro Tips</h1>

<div class="tip">
💡 Always include <code>`include "axi4_bus_config.svh"</code> in new sequences
</div>

<div class="tip">
💡 Use scalable ID macros: <code>`GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id))</code>
</div>

<div class="tip">
💡 Check logs in <code>regression_result_*/logs/no_pass_logs/</code> for failures
</div>

<div class="tip">
💡 Run <code>make clean</code> before switching bus matrix configurations
</div>

<div class="tip">
💡 Use <code>--parallel</code> option for faster regression runs
</div>

<h1>Test Categories</h1>

<table>
    <tr>
        <th>Category</th>
        <th>Test Prefix</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Basic Transfer</td>
        <td>axi4_write_*, axi4_read_*</td>
        <td>Basic read/write operations</td>
    </tr>
    <tr>
        <td>Protocol Tests</td>
        <td>axi4_tc_046_* to axi4_tc_058_*</td>
        <td>Protocol compliance tests</td>
    </tr>
    <tr>
        <td>Boundary Tests</td>
        <td>axi4_*_boundary_*</td>
        <td>Address boundary testing</td>
    </tr>
    <tr>
        <td>Error Tests</td>
        <td>axi4_*_error_*</td>
        <td>Error response testing</td>
    </tr>
</table>

<h1>Need Help?</h1>

<div class="info">
<strong>Documentation:</strong> See doc/AXI4_VIP_User_Guide.html for comprehensive guide<br>
<strong>Email:</strong> axi4_vip_support@company.com<br>
<strong>Issues:</strong> https://github.com/your-org/axi4_vip/issues
</div>
"""
    
    generate_html_guide("AXI4_VIP_Quick_Start_Guide.html", "AXI4 VIP Quick Start", content)

def create_markdown_guides():
    """Create markdown versions that can be easily converted to PDF"""
    
    # Comprehensive guide
    comprehensive_md = """# AXI4 Verification IP User Guide
Version 2.0 - July 2025

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Architecture Overview](#architecture-overview)
4. [Configuration Guide](#configuration-guide)
5. [Running Tests](#running-tests)
6. [Test Development](#test-development)
7. [Scalability Features](#scalability-features)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Introduction

The AXI4 Verification IP (VIP) is a comprehensive UVM-based verification solution for AXI4 protocol compliance testing. It supports scalable bus matrix configurations from 4x4 to 64x64 and beyond.

### Key Features

- **Scalable Architecture**: Supports any bus matrix size without code changes
- **Comprehensive Coverage**: 113+ test cases covering all protocol aspects
- **Full Protocol Support**: IHI0022D specification compliant
- **Performance Optimized**: Parallel test execution with LSF support
- **Advanced Features**: QoS, exclusive access, protocol violation detection

### Supported Configurations

| Feature | Specification |
|---------|--------------|
| Protocol Version | AXI4 (IHI0022D) |
| Data Width | 8, 16, 32, 64, 128, 256, 512, 1024 bits |
| Address Width | Up to 64 bits |
| Burst Types | FIXED, INCR, WRAP |
| Bus Matrix | 4x4 to 64x64 and beyond |

## Getting Started

### System Requirements

- **OS**: Linux (RHEL 7+, Ubuntu 18.04+, CentOS 7+)
- **Simulator**: Synopsys VCS 2024.09 or later
- **UVM**: Version 1.2
- **Memory**: 16GB minimum (32GB recommended)
- **Python**: 3.6 or later

### Installation

```bash
# Clone repository
git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip

# Set up environment
source setup_env.sh

# Navigate to simulation directory
cd sim/synopsys_sim
```

### Quick Test

```bash
# Run simple test
make TEST=axi4_write_read_test

# Check results
grep "TEST PASSED" axi4_write_read_test.log
```

## Configuration Guide

### Bus Matrix Configuration

Edit `include/axi4_bus_config.svh`:

```systemverilog
// Configure bus size
`define NUM_MASTERS 4      // Number of masters
`define NUM_SLAVES 4       // Number of slaves
`define ID_MAP_BITS 4      // ID width

// ID mapping macros (automatic)
`define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
```

### Configuration Examples

| Configuration | Masters | Slaves | Use Case |
|--------------|---------|---------|----------|
| BASE_BUS_MATRIX | 4 | 4 | IoT, Small SoCs |
| ENHANCED_BUS_MATRIX | 10 | 10 | Medium SoCs |
| LARGE_BUS_MATRIX | 64 | 64 | Data Centers |

## Running Tests

### Single Test

```bash
# Basic run
make TEST=axi4_write_read_test

# With waveforms
make TEST=axi4_write_read_test WAVES=1

# With seed
make TEST=axi4_write_read_test SEED=12345
```

### Regression Testing

```bash
# Local regression
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list

# With coverage
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov

# Using LSF (parallel)
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --lsf --parallel 10
```

## Test Development

### Creating New Test

```systemverilog
`include "axi4_bus_config.svh"

class my_test extends axi4_base_test;
  `uvm_component_utils(my_test)
  
  task run_phase(uvm_phase phase);
    my_seq seq;
    seq = my_seq::type_id::create("seq");
    seq.start(env.master[0].sequencer);
  endtask
endclass
```

### Using Scalable IDs

```systemverilog
class my_seq extends axi4_master_base_seq;
  task body();
    start_item(req);
    assert(req.randomize() with {
      tx_type == WRITE;
      // Scalable ID - works for any bus size
      awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id));
      awaddr inside {[START_ADDR:END_ADDR]};
    });
    finish_item(req);
  endtask
endclass
```

## Best Practices

1. **Always use scalable ID macros** - Never hardcode ID values
2. **Include bus config header** - Add to all sequence files
3. **Test multiple configurations** - Verify with different bus sizes
4. **Check regression results** - Review logs for failures
5. **Document test intent** - Add clear comments

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| ID mismatch errors | Check ID is within valid range |
| SLVERR responses | Verify access permissions |
| Compilation errors | Include axi4_bus_config.svh |
| Test timeouts | Check for sequence deadlocks |

### Debug Options

```bash
+UVM_VERBOSITY=UVM_HIGH
+UVM_PHASE_TRACE
+UVM_OBJECTION_TRACE
```

---
**Support**: axi4_vip_support@company.com  
**Version**: 2.0 (July 2025)
"""
    
    # Quick start guide
    quick_md = """# AXI4 VIP Quick Start Guide
Get up and running in 5 minutes!

## Prerequisites

✓ Linux system  
✓ Synopsys VCS 2024.09+  
✓ Python 3.6+  
✓ UVM 1.2  

## Quick Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip
```

### 2. Configure Bus Size (Optional)
```systemverilog
// Edit include/axi4_bus_config.svh
`define NUM_MASTERS 10  // For 10x10 matrix
`define NUM_SLAVES 10
`define ID_MAP_BITS 16
```

### 3. Run Test
```bash
cd sim/synopsys_sim
make TEST=axi4_write_read_test
```

### 4. Run Regression
```bash
python3 axi4_regression_makefile.py \\
  --test-list axi4_transfers_regression.list --cov
```

## Common Commands

| Task | Command |
|------|---------|
| Single test | `make TEST=<name>` |
| With waves | `make TEST=<name> WAVES=1` |
| Clean build | `make clean` |
| Regression | `python3 axi4_regression_makefile.py --test-list <list>` |
| With LSF | Add `--lsf --parallel 10` |

## Pro Tips

💡 Always include `axi4_bus_config.svh`  
💡 Use scalable ID macros  
💡 Check `*/logs/no_pass_logs/` for errors  
💡 Run `make clean` when changing config  
💡 Use `--parallel` for speed  

## Need Help?

📚 Full Guide: `doc/AXI4_VIP_User_Guide.pdf`  
📧 Support: axi4_vip_support@company.com  
🐛 Issues: GitHub Issues page  
"""
    
    # Write markdown files
    with open("AXI4_VIP_User_Guide.md", "w") as f:
        f.write(comprehensive_md)
    print("✅ Generated: AXI4_VIP_User_Guide.md")
    
    with open("AXI4_VIP_Quick_Start.md", "w") as f:
        f.write(quick_md)
    print("✅ Generated: AXI4_VIP_Quick_Start.md")

if __name__ == "__main__":
    print("Generating AXI4 VIP Documentation...")
    print("=" * 50)
    
    # Generate HTML versions
    create_comprehensive_guide()
    create_quick_start_guide()
    
    # Generate Markdown versions
    create_markdown_guides()
    
    print("\n✅ Documentation generation complete!")
    print("\nGenerated files:")
    print("  - AXI4_VIP_User_Guide.html (can be printed to PDF)")
    print("  - AXI4_VIP_Quick_Start_Guide.html (can be printed to PDF)")
    print("  - AXI4_VIP_User_Guide.md (markdown version)")
    print("  - AXI4_VIP_Quick_Start.md (markdown version)")
    print("\nTo convert to PDF:")
    print("  1. Open HTML files in a browser")
    print("  2. Print to PDF (Ctrl+P)")
    print("  3. Or use: wkhtmltopdf input.html output.pdf")