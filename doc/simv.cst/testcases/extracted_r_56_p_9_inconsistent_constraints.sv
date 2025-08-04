class c_56_9;
    bit[63:0] awaddr = 64'h0;

    constraint WITH_CONSTRAINT_this    // (constraint_mode = ON) (../slave/axi4_slave_driver_proxy.sv:222)
    {
       (awaddr != 0);
    }
endclass

program p_56_9;
    c_56_9 obj;
    string randState;

    initial
        begin
            obj = new;
            randState = "x1z110xx01z1zzz0100xxx0z0z101z00xxzzxxzxzxxzzzzzzxxzxxzzzzzxxzxz";
            obj.set_randstate(randState);
            obj.randomize();
        end
endprogram
