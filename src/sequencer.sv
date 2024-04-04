module sequencer(
    input logic clk_in,
    input logic reset_in,

    //To Memory controller
    input logic mem_busy_in,
    input logic inst_fetch_done_in,
    input logic data_read_done_in,

    input logic [1:0] inst_type_in,
    input logic [1:0] imm_type_in,

    output sys_state_t seq_state_out
);

sys_state_t state;

assign seq_state_out = state;

always@(posedge clk_in) begin
    if(reset_in) begin
        state <= STATE_FETCH;
    end else begin
        case(state)
            STATE_FETCH: begin
                state <= STATE_FETCH_WAIT;
            end
            STATE_FETCH_WAIT: begin
                if(inst_fetch_done_in == 1'b1)begin
                    state <= STATE_DECODE;
                end
            end
            STATE_DECODE: begin
                if(inst_type_in == 2'b00)begin//F-Type
                    state <= STATE_UPDATE_PC;
                end
                else if(inst_type_in == 2'b01)begin//J-type
                    state <= STATE_UPDATE_PC;
                end
                else if(inst_type_in == 2'b10)begin//R-type
                    state <= STATE_ALU_EXEC;
                end
                else if(inst_type_in == 2'b11)begin//I-Type
                    if(imm_type_in == 2'b00)begin//LD
                        state <= STATE_LOAD_MEM;
                    end
                    else if(imm_type_in == 2'b01)begin//ST
                        state <= STATE_STORE_MEM;
                    end
                    else begin//LDI(2'b10)
                        state <= STATE_UPDATE_PC;
                    end
                end
            end
            STATE_LOAD_MEM: begin
                state <= STATE_LOAD_MEM_WAIT;
            end
            STATE_LOAD_MEM_WAIT: begin
                if(data_read_done_in == 1'b1)begin
                    state <= STATE_UPDATE_PC;
                end
            end
            STATE_STORE_MEM: begin
                state <= STATE_STORE_MEM_WAIT;
            end
            STATE_STORE_MEM_WAIT: begin
                if(mem_busy_in == 1'b0)begin
                    state <= STATE_UPDATE_PC;
                end
            end
            STATE_ALU_EXEC: begin
                state <= STATE_UPDATE_PC;
            end
            STATE_UPDATE_PC: begin
                state <= STATE_FETCH;
            end
            default: begin
                state <= STATE_FETCH;
            end
        endcase
    end
end

endmodule