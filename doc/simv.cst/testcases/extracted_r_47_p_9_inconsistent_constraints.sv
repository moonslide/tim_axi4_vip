class c_47_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_47_9;
    c_47_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x1zz01xz0zx011x1z0z10xxz1zz01x01xzxxzxxxzxzxzxxxxxxzzxxxzxzzxxxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
