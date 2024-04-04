`default_nettype none
module tiny_mcu (
    input logic clk_in,
    input logic reset_in,

    //Signals for SPI Flash/PSRAM
    output logic sclk_out,
    output logic flash_cs_out,
    output logic psram_cs_out,
    output logic mosi_out,
    input logic miso_in
);

    //Internal signals for sequencer
    sys_state_t seq_state;
    sequencer CPU_SEQ(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .mem_busy_in(mem_busy),
        .inst_fetch_done_in(flash_read_data_valid),
        .data_read_done_in(psram_read_data_valid),
        .inst_type_in(inst_type),
        .imm_type_in(imm_type),
        .seq_state_out(seq_state)
    );

    //Internal signals for program counter
    logic [15:0] pc_addr;
    program_counter PC(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .pc_update_en_in(seq_state == STATE_UPDATE_PC),
        .pc_update_sel_in(inst_type == 2'b01),
        .jump_addr_in({src_reg_buf[7:0],reg_read_result}),
        .program_counter_out(pc_addr)
    );

    //Internal signals for ALU
    logic [7:0] alu_result;
    logic [3:0] status;
    alu ALU(
        .alu_op_in(subtype_flag),
        .a_in(src_reg_buf),
        .b_in(reg_read_result),
        .result_out(alu_result),
        .status_in(status_reg),
        .status_out(status)
    );

    //Internal signals for status register
    logic status_write_en;
    logic status_copy_en;
    logic [3:0] status_reg;
    logic cond;
    //When imm_type[0] is 1, copy status to status register
    assign status_copy_en = (seq_state == STATE_DECODE) & (inst_type == 2'b00) & imm_type[0];
    assign status_write_en = (seq_state == STATE_ALU_EXEC);
    status_register SR(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .status_in(status),
        .status_write_en_in(status_write_en),
        .status_inst_in(subtype_flag[3:0]),
        .status_copy_en_in(status_copy_en),
        .status_invert_in(src_addr[0]),
        .status_out(status_reg),
        .cond_out(cond)
    );

    //Internal signals for instruction register
    logic [15:0] instruction_data;
    instruction_register IR(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .ir_write_en_in(flash_read_data_valid),
        .ir_data_in(flash_read_data),
        .cond_in(cond),
        .ir_data_out(instruction_data)
    );

    //Internal signals for instruction decoder
    logic [2:0] src_addr;
    logic [2:0] dst_addr;
    logic [7:0] imm;
    logic [1:0] imm_type;
    logic cond_en;
    logic [1:0] inst_type;
    logic [3:0] subtype_flag;

    inst_decoder ID(
        .inst_in(instruction_data),
        .src_addr_out(src_addr),
        .dst_addr_out(dst_addr),
        .imm_out(imm),
        .imm_type_out(imm_type),
        .cond_en_out(cond_en),
        .inst_type_out(inst_type),
        .subtype_flag_out(subtype_flag)
    );

    //Internal signals for register file
    logic [2:0] reg_read_addr;
    logic [7:0] src_reg_buf;
    logic [7:0] reg_read_result;
    logic [7:0] reg_write_data;
    logic [2:0] reg_write_addr;
    logic reg_write_en;
    assign reg_read_addr = (seq_state == STATE_DECODE) ? src_addr : dst_addr;
    assign reg_write_data = (inst_type != 2'b11)?alu_result:(imm_type == 2'b00)?psram_read_data:imm;
    assign reg_write_en = psram_read_data_valid|
                          ((inst_type == 2'b11) & (imm_type == 2'b10) & (seq_state == STATE_DECODE))|
                          (seq_state == STATE_ALU_EXEC);
    always_comb begin
        if(inst_type == 2'b11)begin
            if(imm_type != 2'b10)begin
                reg_write_addr = 3'h0;
            end
            else begin
                reg_write_addr = src_addr;
            end
        end
        else begin
            reg_write_addr = dst_addr;
        end
    end
    reg_file RF(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .read_addr_in(reg_read_addr),
        .write_addr_in(reg_write_addr),
        .write_en_in(reg_write_en),
        .write_data_in(reg_write_data),
        .read_data_out(reg_read_result)
    );

    always@(posedge clk_in)begin
        if(reset_in)begin
            src_reg_buf <= 8'h00;
        end
        else begin
            if(seq_state == STATE_DECODE)begin
                src_reg_buf <= reg_read_result;
            end
        end
    end

    //internal signals for memory controller
    logic [15:0] mem_addr;
    logic spi_mem_addr_valid;
    logic [7:0] psram_write_data;
    mem_type_t mem_type;
    logic [15:0] flash_read_data;
    logic flash_read_data_valid;
    logic [7:0] psram_read_data;
    logic psram_read_data_valid;
    logic mem_busy;

    assign psram_write_data = reg_read_result;
    assign mem_addr = (seq_state == STATE_FETCH) ? pc_addr : {imm[7:0],src_reg_buf};
    //メモリコントローラ経由でメモリアクセスを行うのは
    //Flashへのアクセス
    //Load命令/Store命令かつ、アドレスの上位4bitが0xfでないとき
    assign spi_mem_addr_valid = (seq_state == STATE_FETCH) |
                                (((seq_state == STATE_LOAD_MEM)|(seq_state == STATE_STORE_MEM)) & (mem_addr[15:12] != 4'hf));
    always_comb begin
        if(seq_state == STATE_FETCH)begin
            mem_type = TYPE_IMEM_READ;
        end
        else if(seq_state == STATE_LOAD_MEM)begin
            mem_type = TYPE_DMEM_READ;
        end
        else if(seq_state == STATE_STORE_MEM)begin
            mem_type = TYPE_DMEM_WRITE;
        end
    end
    spi_flash_controller SPI_CTRL(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .sclk_out(sclk_out),
        .mosi_out(mosi_out),
        .miso_in(miso_in),
        .flash_cs_out(flash_cs_out),
        .psram_cs_out(psram_cs_out),
        .addr_in(mem_addr),
        .addr_valid_in(spi_mem_addr_valid),
        .psram_data_in(psram_write_data),
        .mem_type_in(mem_type),
        .flash_data_out(flash_read_data),
        .flash_data_valid_out(flash_read_data_valid),
        .psram_data_out(psram_read_data),
        .psram_data_valid_out(psram_read_data_valid),
        .busy_out(mem_busy)
    );

    //Peripherals
    logic periph_addr_valid;
    //assign periph_addr_valid = 
    
endmodule