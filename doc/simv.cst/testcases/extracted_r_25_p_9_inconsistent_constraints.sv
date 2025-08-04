class c_25_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_25_9;
    c_25_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "10x1zz01xzxz00110xz001xz1xzz0z11zxxxzxxzzxzxxxzzxxxxzxzxzxxxxzzx";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
