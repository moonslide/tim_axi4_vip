class c_66_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_66_9;
    c_66_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "xx1x01x0zxx0x1z0z011zzzx0zxzx010xxzzzzzzzzzzxzxxxxxxxxxzxxxzxzxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
