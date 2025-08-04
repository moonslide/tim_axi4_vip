class c_14_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_14_9;
    c_14_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "0zzx0zz0xz0zx1zxx11zxxx001zzxz00zxzxxzxxzzxxzzxzzxxxzxxxxzxzzzzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
