class c_39_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_39_9;
    c_39_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "xzxz011z0xx001z11xx1zzz0x0101xx1xxxxxzxzxxxzxxzxzzzzzxzzzzxzxzzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
