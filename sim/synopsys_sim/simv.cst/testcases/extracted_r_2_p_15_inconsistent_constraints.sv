class c_2_15;
    int ws = 1;
    bit[15:0] req_bid = 16'h0; // ( req.bid = axi4_globals_pkg::bid_e::BID_0 ) 

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../../seq/master_sequences/axi4_master_b_ready_delay_seq.sv:20)
    {
       (req_bid == (unsigned'((16'(ws)))));
    }
endclass

program p_2_15;
    c_2_15 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "1000xz11001xx01xz0x100z1z111z1x0xxxxxxzzzxxzxxzzxxzzxzxxzzxzxxzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
