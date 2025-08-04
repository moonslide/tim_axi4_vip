class c_23_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_23_9;
    c_23_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "1xxz0x0zxx0010x0zxxx0xx1xzz1x10xxzzxxzzzxzxzxxxzxxzzzzxzxxxxxxxx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
