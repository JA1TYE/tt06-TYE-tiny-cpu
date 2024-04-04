//8-bit alu module
module alu(
    input logic [7:0] a_in,
    input logic [7:0] b_in,
    input logic [3:0] alu_op_in,
    input logic [3:0] status_in,
    output logic [7:0] result_out,
    output logic [3:0] status_out
); 

    logic [7:0] adder_a_in;
    logic [7:0] adder_b_in;
    logic [8:0] adder_result_out;
    logic carry_out;
    logic ovf_out;
    logic zero_out;
    logic sign_out;
    logic carry_in;
    logic ovf_in;
    logic ovf_temp;

    assign carry_in = status_in[3];
    assign ovf_in = status_in[1];

    assign status_out = {carry_out,sign_out,ovf_out,zero_out};
    assign sign_out = result_out[7];
    assign zero_out = (result_out == 8'h0);
    assign ovf_temp = a_in[7] & b_in[7] & ~result_out[7] | ~a_in[7] & ~b_in[7] & result_out[7];

    assign adder_a_in = a_in;
    always_comb begin
        case(alu_op_in)
            4'h4: adder_b_in = 8'h01;
            4'h5: adder_b_in = 8'hff;
            default: adder_b_in = b_in;
        endcase
    end

    always_comb begin
        case(alu_op_in)
            4'h0: begin//Shift Logical Right
                {result_out,carry_out} = {1'b0,a_in[7:0]};
                ovf_out = ovf_in;
            end
            4'h1: begin//Shift Logical Left
                {carry_out,result_out} = {a_in[7:0],1'b0};
                ovf_out = ovf_in;
            end
            4'h4: begin//Increment
                {carry_out,result_out} = adder_result_out;
                ovf_out = ovf_temp;
            end
            4'h5: begin//Decrement
                {carry_out,result_out} = adder_result_out;
                ovf_out = ovf_temp;
            end
            4'h6: begin//Add
                {carry_out,result_out} = adder_result_out;
                ovf_out = ovf_temp;
            end
            4'h8: begin//NOT
                result_out = ~a_in;
                carry_out = carry_in;
                ovf_out = ovf_in;
            end
            4'h9: begin//AND
                result_out = a_in & b_in;
                carry_out = carry_in;
                ovf_out = ovf_in;
            end
            4'ha: begin//OR
                result_out = a_in | b_in;
                carry_out = carry_in;
                ovf_out = ovf_in;
            end
            4'hb: begin//MOV
                result_out = a_in;
                carry_out = carry_in;
                ovf_out = ovf_in;
            end
            default: begin
                result_out = 8'h00;
                carry_out = 1'b0;
                ovf_out = 1'b0;
            end
        endcase
    end

    assign adder_result_out = adder_a_in + adder_b_in;

endmodule