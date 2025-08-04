class c_1_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_1_9;
    c_1_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "1zx01xz1x1zxxzz011zx00x1001zxx11zxxxxxxzxxzxzxxxxxxxzxzzzxxzzzzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
