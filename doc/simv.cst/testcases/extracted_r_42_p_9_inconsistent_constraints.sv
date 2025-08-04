class c_42_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_42_9;
    c_42_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "01z1zzz001xx10zzxx0100zzx10zxxz0zzxxxzxxzxxzzxzzxxzxxzzzxzzzzzxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
