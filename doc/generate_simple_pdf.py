#!/usr/bin/env python3
"""
Generate a simple AXI4 VIP Quick Start PDF
"""

import os
import subprocess
from datetime import datetime

def create_simple_pdf():
    """Create a simple PDF using basic PostScript"""
    
    ps_content = r"""%!PS-Adobe-3.0
%%Title: AXI4 VIP Quick Start Guide
%%Creator: AXI4 VIP Documentation Generator
%%Pages: 4
%%BoundingBox: 0 0 612 792
%%EndComments

%%BeginProlog
/Helvetica-Bold findfont 36 scalefont /TitleFont exch def
/Helvetica-Bold findfont 24 scalefont /HeadingFont exch def
/Helvetica-Bold findfont 18 scalefont /SubheadingFont exch def
/Helvetica findfont 12 scalefont /BodyFont exch def
/Courier findfont 10 scalefont /CodeFont exch def
%%EndProlog

%%Page: 1 1
% Title Page
0.9 0.95 1.0 setrgbcolor
0 0 612 792 rectfill

0 0.2 0.4 setrgbcolor
TitleFont setfont
206 600 moveto
(AXI4 VIP) show

HeadingFont setfont
156 550 moveto
(Quick Start Guide) show

0 0 0 setrgbcolor
1 setlinewidth
206 350 200 100 rectstroke

SubheadingFont setfont
236 420 moveto
(Version 2.0) show

BodyFont setfont
200 395 moveto
(Get Started in 5 Minutes!) show
250 370 moveto
(""" + datetime.now().strftime("%B %Y") + r""") show

showpage

%%Page: 2 2
% Prerequisites and Setup
HeadingFont setfont
0 0.2 0.4 setrgbcolor
50 720 moveto
(Prerequisites) show

BodyFont setfont
0 0 0 setrgbcolor
50 650 moveto
(System Requirements:) show

50 620 moveto
(- Linux (RHEL 7+, Ubuntu 18.04+, CentOS 7+)) show
50 600 moveto
(- Synopsys VCS 2024.09 or later) show
50 580 moveto
(- UVM 1.2) show
50 560 moveto
(- Python 3.6 or later) show
50 540 moveto
(- 16GB RAM minimum) show

HeadingFont setfont
0 0.2 0.4 setrgbcolor
50 480 moveto
(Quick Setup) show

SubheadingFont setfont
0 0.4 0.8 setrgbcolor
50 440 moveto
(Step 1: Clone Repository) show

0.9 0.95 1.0 setrgbcolor
50 360 512 50 rectfill
0 0 0 setrgbcolor
50 360 512 50 rectstroke

CodeFont setfont
60 395 moveto
(git clone https://github.com/your-org/axi4_vip.git) show
60 380 moveto
(cd axi4_vip) show

SubheadingFont setfont
0 0.4 0.8 setrgbcolor
50 320 moveto
(Step 2: Configure and Run) show

0.9 0.95 1.0 setrgbcolor
50 240 512 50 rectfill
0 0 0 setrgbcolor
50 240 512 50 rectstroke

CodeFont setfont
60 275 moveto
(cd sim/synopsys_sim) show
60 260 moveto
(make TEST=axi4_write_read_test) show

showpage

%%Page: 3 3
% Common Commands
HeadingFont setfont
0 0.2 0.4 setrgbcolor
50 720 moveto
(Common Commands) show

SubheadingFont setfont
0 0.4 0.8 setrgbcolor
50 670 moveto
(Test Execution) show

BodyFont setfont
0 0 0 setrgbcolor
50 630 moveto
(Run single test:) show
CodeFont setfont
300 630 moveto
(make TEST=test_name) show

BodyFont setfont
50 600 moveto
(Run with waveforms:) show
CodeFont setfont
300 600 moveto
(make TEST=test_name WAVES=1) show

BodyFont setfont
50 570 moveto
(Clean build:) show
CodeFont setfont
300 570 moveto
(make clean) show

SubheadingFont setfont
0 0.4 0.8 setrgbcolor
50 520 moveto
(Regression Testing) show

BodyFont setfont
0 0 0 setrgbcolor
50 480 moveto
(Run regression:) show
CodeFont setfont
50 460 moveto
(python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list) show

BodyFont setfont
50 420 moveto
(With coverage:) show
CodeFont setfont
50 400 moveto
(python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov) show

BodyFont setfont
50 360 moveto
(With LSF:) show
CodeFont setfont
50 340 moveto
(python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --lsf) show

SubheadingFont setfont
0 0.4 0.8 setrgbcolor
50 280 moveto
(Test Categories) show

BodyFont setfont
0 0 0 setrgbcolor
50 240 moveto
(Basic Transfer: axi4_write_*, axi4_read_*) show
50 220 moveto
(Protocol Tests: axi4_tc_046_* to axi4_tc_058_*) show
50 200 moveto
(Boundary Tests: axi4_*_boundary_*) show
50 180 moveto
(Error Tests: axi4_*_error_*) show

showpage

%%Page: 4 4
% Best Practices and Support
HeadingFont setfont
0 0.2 0.4 setrgbcolor
50 720 moveto
(Best Practices) show

BodyFont setfont
0 0 0 setrgbcolor
50 670 moveto
(1. Always include bus configuration header:) show
CodeFont setfont
70 650 moveto
(`include "axi4_bus_config.svh") show

BodyFont setfont
50 610 moveto
(2. Use scalable ID mapping macros:) show
CodeFont setfont
70 590 moveto
(awid == `GET_AWID_ENUM\(`GET_EFFECTIVE_AWID\(master_id\)\);) show

BodyFont setfont
50 550 moveto
(3. Clean before configuration changes:) show
CodeFont setfont
70 530 moveto
(make clean) show

BodyFont setfont
50 490 moveto
(4. Check regression logs for failures:) show
CodeFont setfont
70 470 moveto
(cd regression_result_*/logs/no_pass_logs/) show

HeadingFont setfont
0 0.2 0.4 setrgbcolor
50 400 moveto
(Getting Help) show

BodyFont setfont
0 0 0 setrgbcolor
50 350 moveto
(Documentation: doc/AXI4_VIP_User_Guide.pdf) show
50 330 moveto
(Email: axi4_vip_support@company.com) show
50 310 moveto
(Issues: https://github.com/your-org/axi4_vip/issues) show

0.5 0.5 0.5 setrgbcolor
206 100 moveto
(AXI4 VIP v2.0 - ) show
(""" + datetime.now().strftime("%Y") + r""") show

showpage

%%Trailer
%%EOF
"""
    
    # Save PostScript file
    ps_filename = "AXI4_VIP_Quick_Start_Simple.ps"
    with open(ps_filename, "w") as f:
        f.write(ps_content)
    
    print(f"✅ Generated: {ps_filename}")
    
    # Try to convert to PDF
    try:
        result = subprocess.run(["ps2pdf", ps_filename, "AXI4_VIP_Quick_Start.pdf"], 
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        if result.returncode == 0:
            print("✅ Generated: AXI4_VIP_Quick_Start.pdf")
            # Clean up PS file
            os.remove(ps_filename)
            return True
        else:
            print(f"❌ ps2pdf failed: {result.stderr}")
            return False
    except FileNotFoundError:
        print("⚠️  ps2pdf not found.")
        return False

if __name__ == "__main__":
    create_simple_pdf()