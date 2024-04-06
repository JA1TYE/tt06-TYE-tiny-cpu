`default_nettype none
module inst_decoder (
    //Instruction input
    input logic [15:0] inst_in,
    output logic [2:0] src_addr_out,
    output logic [2:0] dst_addr_out,
    output logic [7:0] imm_out,
    output logic [1:0] imm_type_out,
    output logic cond_en_out,
    output logic [1:0] inst_type_out,
    output logic [3:0] subtype_flag_out
);

assign dst_addr_out = inst_in[7:5];
assign src_addr_out = inst_in[10:8];
assign imm_out = inst_in[7:0];
assign imm_type_out = inst_in[12:11];
assign inst_type_out = inst_in[15:14];
assign subtype_flag_out = inst_in[3:0];
assign cond_en_out = inst_in[13];


endmodule
