class c_64_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_64_9;
    c_64_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x0z01x001x0z101xxz111x111z011z11xzzzzzxzxxxxzxzzxxzxxzxxzzzzzzzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
