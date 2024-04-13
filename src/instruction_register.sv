`default_nettype none
module instruction_register(
    input logic clk_in,
    input logic reset_in,

    input logic ir_write_en_in,
    input logic [15:0] ir_data_in,
    input logic cond_in,
    output logic [15:0] ir_data_out
);

logic [15:0] ir_data;

assign ir_data_out = ir_data;

always@(posedge clk_in) begin
    if(reset_in) begin
        ir_data <= 16'h0;
    end
    else begin
        if(ir_write_en_in == 1'b1)begin
            //If skip cond is true or 0xffff instruction is fetched, set IR to 0x0000(NOP) 
            if((ir_data_in[13] & cond_in)|(ir_data[15:14] == 2'b11 & ir_data[12:11] == 2'b11))begin
                ir_data <= 16'h0000;
            end
            else begin
                ir_data <= ir_data_in;
            end
        end
    end
end

endmodule
