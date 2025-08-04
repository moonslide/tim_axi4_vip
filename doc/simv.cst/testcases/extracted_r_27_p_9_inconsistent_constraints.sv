class c_27_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_27_9;
    c_27_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "z0xzx1z01z0xxx01z0x001x10x001z11zxxxzxzzzxzxxxzzxzzzzxxzzxzxxzzz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
