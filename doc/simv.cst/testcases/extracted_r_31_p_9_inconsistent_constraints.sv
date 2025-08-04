class c_31_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_31_9;
    c_31_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "zxxz01zx001zzxzzxz1z1x01x011zz00zzzxxzxzzxxzxxxzxxzxzxxxzzzxxzxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
