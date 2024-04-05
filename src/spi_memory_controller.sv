module spi_flash_controller (
    //Control signals
    input wire clk_in,
    input wire reset_in,

    //SPI common signals
    output logic sclk_out,
    output logic mosi_out,
    input wire miso_in,

    output logic flash_cs_out,
    output logic psram_cs_out,

    //System bus signals
    //Note: This module is designed for 16-bit data bus,
    //      and lowest bit of addr_in is ignored.
    //      When you set 0x001F (it will be treated as 0x001E!)
    //      as addr_in value,you can get 16-bit data like below:
    //      flash_data_out[15:8] = data in 0x001E
    //      flash_data_out[7:0]  = data in 0x001F
    input logic [15:0] addr_in,
    input logic addr_valid_in,
    input logic [7:0] psram_data_in,
    input mem_type_t mem_type_in,
    output logic [15:0] flash_data_out,
    output logic flash_data_valid_out,
    output logic [7:0]psram_data_out,
    output logic psram_data_valid_out,
    output reg busy_out
);

enum logic [3:0] {
    IDLE,
    SEND_FLASH_READ_CMD,
    SEND_PSRAM_READ_CMD,
    SEND_PSRAM_WRITE_CMD,
    SEND_ADDR_ZERO,
    SEND_ADDR_HIGH,
    SEND_ADDR_LOW,
    READ_FLASH_DATA_HIGH,
    READ_FLASH_DATA_LOW,
    READ_PSRAM,
    WRITE_PSRAM
} state;

mem_type_t mem_type;

logic [15:0] addr_reg;
logic [3:0] clock_counter;
logic [7:0] shift_reg;
logic [7:0] write_data_reg;
logic miso_buf;

assign mosi_out = shift_reg[7];

assign busy_out = (state != IDLE);

assign psram_data_valid_out = ((state == READ_PSRAM) & (clock_counter == 4'h7) & (sclk_out == 1'b1))?1'b1:1'b0;
assign psram_data_out = {shift_reg[6:0],miso_buf};

assign flash_data_valid_out = ((state == READ_FLASH_DATA_LOW) & (clock_counter == 4'h7) & (sclk_out == 1'b1))?1'b1:1'b0;
assign flash_data_out = {write_data_reg,shift_reg[6:0],miso_buf};

always@(posedge clk_in)begin
    if(reset_in)begin
        state <= IDLE;
        sclk_out <= 1'b0;
        flash_cs_out <= 1'b1;
        psram_cs_out <= 1'b1;
        shift_reg <= 8'h00;
        miso_buf <= 1'b0;
        
        write_data_reg <= 8'h00;

        clock_counter <= 4'b0;
    end
    else begin
        if(state == IDLE)begin
            if(addr_valid_in == 1'b1)begin
                addr_reg <= addr_in;
                mem_type <= mem_type_in;

                clock_counter <= 4'h0;
                
                if(mem_type_in == TYPE_IMEM_READ)begin
                    state <= SEND_FLASH_READ_CMD;
                    shift_reg <= 8'h03;
                    flash_cs_out <= 1'b0;
                end
                else if(mem_type_in == TYPE_DMEM_READ)begin
                    state <= SEND_PSRAM_READ_CMD;
                    shift_reg <= 8'h03;
                    psram_cs_out <= 1'b0;
                end
                else if(mem_type_in == TYPE_DMEM_WRITE)begin
                    state <= SEND_PSRAM_WRITE_CMD;
                    shift_reg <= 8'h02;
                    write_data_reg <= psram_data_in;
                    psram_cs_out <= 1'b0;
                end
                sclk_out <= 1'b0;
                miso_buf <= miso_in;
            end
            else begin
                clock_counter <= 4'h0;
                flash_cs_out <= 1'b1;
                psram_cs_out <= 1'b1;
                sclk_out <= 1'b0;
            end
        end
        //Shift Operation
        else begin
            if(sclk_out == 1'b0)begin//Sample Edge
                sclk_out <= 1'b1;
                miso_buf <= miso_in;
            end
            else begin//Shift Edge
                sclk_out <= 1'b0;
                if(clock_counter == 4'h7)begin
                    clock_counter <= 4'h0;
                end
                else begin
                    clock_counter <= clock_counter + 1;
                    shift_reg <= {shift_reg[6:0],miso_buf};
                end
            end
        end

        //State Machine for shift register
        if(clock_counter == 4'h7 && sclk_out == 1'b1)begin
            if(
            state == SEND_FLASH_READ_CMD ||
            state == SEND_PSRAM_READ_CMD ||
            state == SEND_PSRAM_WRITE_CMD)begin
                shift_reg <= 8'h00;//Address[23:16]
                state <= SEND_ADDR_ZERO;
            end
            else if(state == SEND_ADDR_ZERO)begin
                shift_reg <= addr_reg[15:8];
                state <= SEND_ADDR_HIGH;
            end
            else if(state == SEND_ADDR_HIGH)begin
                shift_reg <= addr_reg[7:0];
                state <= SEND_ADDR_LOW;
            end
            else if(state == SEND_ADDR_LOW)begin
                if(mem_type == TYPE_IMEM_READ)begin
                    shift_reg <= 8'h00;
                    state <= READ_FLASH_DATA_HIGH;
                end
                else if(mem_type == TYPE_DMEM_READ)begin
                    shift_reg <= 8'h00;
                    state <= READ_PSRAM;
                end
                else if(mem_type == TYPE_DMEM_WRITE)begin
                    shift_reg <= write_data_reg;
                    state <= WRITE_PSRAM;
                end
            end
            else if(state == READ_FLASH_DATA_HIGH)begin
                write_data_reg <= {shift_reg[6:0],miso_buf};
                shift_reg <= 8'h00;
                state <= READ_FLASH_DATA_LOW;
            end
            else if(state == READ_FLASH_DATA_LOW)begin
                state <= IDLE;
            end
            else if(state == READ_PSRAM)begin
                state <= IDLE;
            end
            else if(state == WRITE_PSRAM)begin
                state <= IDLE;
            end
        end
    end
end

endmodule