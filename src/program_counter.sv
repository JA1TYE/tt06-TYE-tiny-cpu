module program_counter(
    input logic clk_in,
    input logic reset_in,

    input logic [15:0] jump_addr_in,
    input logic pc_update_en_in,
    input logic pc_update_sel_in,

    output logic [15:0] program_counter_out
);

logic [14:0] program_counter;

assign program_counter_out = {program_counter[14:0], 1'b0};

always@(posedge clk_in) begin
    if(reset_in) begin
        program_counter <= 15'h0000;
    end
    else begin
        if(pc_update_en_in == 1'b1)begin
            if(pc_update_sel_in == 1'b0)begin
                program_counter <= program_counter + 1;
            end
            else begin
                program_counter <= jump_addr_in[15:1];
            end
        end
    end
end

endmodule
