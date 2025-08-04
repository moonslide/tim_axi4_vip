class c_12_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_12_9;
    c_12_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "z001x0011z0110xz1zx0zzzx1z110x1xzxzxzxxzxxxxxzxxzzxxxzxzxxxzxzxx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
