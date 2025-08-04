class c_62_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_62_9;
    c_62_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "zxzxzzzxxzz11zzx11zx1xx01xz11xx0xzzxzxxxzxzxzzxzxzzxzzzxxxxxzxxx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
