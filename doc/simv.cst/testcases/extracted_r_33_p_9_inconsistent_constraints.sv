class c_33_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_33_9;
    c_33_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x0x0x01z011z100x00zxzz0zzx0zz0xzxxxxxzxxzzzxzxzzzxzxzxxxzxzzxxxx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
