class c_17_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_17_9;
    c_17_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x100zzz00x1zxx0z0x01101xz0zxx1x1xzzzxzxzxxzzzzzzxxzzxxzxzzxxxzxx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
