class c_60_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_60_9;
    c_60_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "00xx0z11x1xz00zx1z1x01011x00x0xzzzxzxzzxxxxxzzzzxxxxxxxzzzxxxxzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
