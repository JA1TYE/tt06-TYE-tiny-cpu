`timescale 1ns/1ps

module alu_sim();
    import common_pkg::*;

    logic [7:0] a_in;
    logic [7:0] b_in;
    logic [3:0] alu_op_in;
    logic [3:0] status_in;
    logic [7:0] result_out;
    logic [3:0] status_out;

    alu DUT(.*);

    initial begin
        $dumpfile("alu_sim.vcd");
        $dumpvars(0,alu_sim);
        //SLR
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h0;
        #10;
        status_in = 4'hf;
        #10;
        //SLL
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h1;
        #10;
        status_in = 4'hf;
        #10;
        //INC
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h4;
        #10;
        status_in = 4'hf;
        #10;
        //DEC
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h5;
        #10;
        status_in = 4'hf;
        #10;
        //ADD
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h6;
        #10;
        status_in = 4'hf;
        #10;
        //NOT
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h8;
        #10;
        status_in = 4'hf;
        #10;
        //AND
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'h9;
        #10;
        status_in = 4'hf;
        #10;
        //OR
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'ha;
        #10;
        status_in = 4'hf;
        #10;
        //MOV
        a_in = 8'h11;
        b_in = 8'hcf;
        status_in = 4'h0;
        alu_op_in = 4'hb;
        #10;
        status_in = 4'hf;
        #10;
        $finish;
    end

endmodule