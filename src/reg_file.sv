`default_nettype none
//8bit wide x 8 locations register file
module reg_file (
    //Control signals
    input logic clk_in,
    input logic reset_in,
    input logic [2:0] read_addr_in,
    input logic [2:0] write_addr_in,
    input logic write_en_in,
    input logic [7:0] write_data_in,
    output logic [7:0] read_data_out
);

    //Internal registers
    logic [7:0] reg_file [0:7];

    //Read operation
    assign read_data_out = reg_file[read_addr_in];

    //Write operation
    always@(posedge clk_in)begin
        if(write_en_in)begin
            reg_file[write_addr_in] <= write_data_in;
        end
    end
endmodule
