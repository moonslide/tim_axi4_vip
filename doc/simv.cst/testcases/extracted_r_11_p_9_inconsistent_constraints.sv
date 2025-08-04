class c_11_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_11_9;
    c_11_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "1z0x10zx000100zx0x100z1zz00z1zzzzxzxzxzxxxzxxzzzzzzzzzxxzzxxzxxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
