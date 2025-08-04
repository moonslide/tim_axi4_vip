class c_3_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_3_9;
    c_3_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "10zxxz111x1xzz0001xzx1z0z01zxxz0xxxxzxzxxxzxxxxzzxzzzzzzzzzzxzxx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
