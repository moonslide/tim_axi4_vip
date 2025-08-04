class c_29_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_29_9;
    c_29_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x010z1xx01z11101x101x0xzx10x0000xxzzzxzzzzzxxxxzzxzzzxzxxxxxxxzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
