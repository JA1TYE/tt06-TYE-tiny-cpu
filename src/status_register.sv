`default_nettype none
module status_register (
    //Control signals
    input logic clk_in,
    input logic reset_in,

    //Flag status input
    input logic [3:0] status_in,
    input logic status_write_en_in,

    input logic [3:0] status_inst_in,
    input logic status_copy_en_in,
    input logic status_invert_in,
    output logic [3:0] status_out,
    output logic cond_out
);

logic [3:0] status_flag;
logic status_result;
assign status_out = status_flag;

always@(posedge clk_in)begin
    if(reset_in)begin
        status_flag <= 4'b0000;
        cond_out <= 1'b0;
    end
    else begin
        if(status_write_en_in == 1'b1)begin
            status_flag <= status_in;
        end
        if(status_copy_en_in == 1'b1)begin
            if(status_invert_in == 1'b1)begin
                cond_out <= ~(|(status_flag & status_inst_in));
            end
            else begin
                cond_out <= |(status_flag & status_inst_in);
            end
        end
    end
end

endmodule
