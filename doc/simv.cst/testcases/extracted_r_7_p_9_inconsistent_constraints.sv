class c_7_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_7_9;
    c_7_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x1xx10x00xzx1xz00zxzz1z1z00z111zxzxxzzzzxxzxxzzzxxxzxzzzzxxxxzzz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
