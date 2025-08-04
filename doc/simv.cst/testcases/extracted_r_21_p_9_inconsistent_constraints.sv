class c_21_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_21_9;
    c_21_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "xz1101z0xz10xxxzzz10z00xzzz11zzzzxzzzzzzzzzzxxxzxxzxxzxzzzzzzxxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
