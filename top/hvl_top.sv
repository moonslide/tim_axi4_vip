//--------------------------------------------------------------------------------------------
// Module: Hvl top module
//--------------------------------------------------------------------------------------------
module hvl_top;

  //-------------------------------------------------------
  // Package : Importing Uvm Pakckage and Test Package
  //-------------------------------------------------------
  import axi4_test_pkg::*;
  import uvm_pkg::*;

  //-------------------------------------------------------
  // run_test for simulation
  //-------------------------------------------------------
  initial begin : START_TEST 
    
    // The test to start is given at the command line
    // The command-line UVM_TESTNAME takes the precedance
    run_test("axi4_base_test");

  end
`ifdef DUMP_FSDB
        initial begin
            string fsdb_filename;
        
            // ? +fsdbfile=my_dump.fsdb
            if (!$value$plusargs("fsdbfile=%s", fsdb_filename)) begin
                fsdb_filename = "default.fsdb"; // if no used for default.fsdb
            end
        
            $fsdbDumpfile(fsdb_filename);  // 
            $fsdbDumpvars(0, hdl_top);   //
//            $fsdbDumpvars(" uvm_test_top.axi4_env_h.axi4_master_agent_h[0]", "+class","+object_level=5");   //

        end
`endif

  

endmodule : hvl_top
