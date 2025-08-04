class c_37_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_37_9;
    c_37_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "xxz00101zz0z00zz0z0z1z0z11100zz0zxzzxxzxzzzzzzzxzzxxzxzxzxzxzxzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
