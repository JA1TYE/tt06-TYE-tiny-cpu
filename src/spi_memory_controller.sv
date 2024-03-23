module spi_flash_controller (
    //Control signals
    input wire clk_in,
    input wire reset_in,

    //SPI signals
    output logic sclk_out,
    output logic cs_out,
    output logic mosi_out,
    input wire miso_in,

    //System bus signals
    //Note: This module is designed for 16-bit data bus,
    //      and lowest bit of addr_in is ignored.
    //      When you set 0x001F (it will be treated as 0x001E!)
    //      as addr_in value,you can get 16-bit data like below:
    //      data_out[15:8] = data in 0x001F
    //      data_out[7:0]  = data in 0x001E
    input wire [15:0] addr_in,
    input wire addr_valid_in,
    output reg [15:0] data_out,
    output reg data_valid_out,
    output reg busy_out
);

enum logic [2:0] {
    IDLE,
    SEND_CMD,
    SEND_ADDR_ZERO,
    SEND_ADDR_HIGH,
    SEND_ADDR_LOW,
    READ_DATA_HIGH,
    READ_DATA_LOW
} state;

logic [15:0] addr_reg;
logic [3:0] clock_counter;
logic [7:0] shift_reg;
logic miso_buf;

assign mosi_out = shift_reg[7];

always@(posedge clk_in)begin
    if(reset_in)begin
        state <= IDLE;
        sclk_out <= 1'b0;
        cs_out <= 1'b1;
        shift_reg <= 8'h00;
        miso_buf <= 1'b0;

        data_out <= 16'b0;
        data_valid_out<= 1'b0;
        busy_out <= 1'b0;

        clock_counter <= 5'b0;
    end
    else begin
        if(state == IDLE)begin
            if(addr_valid_in == 1'b1)begin
                addr_reg <= addr_in;
                busy_out <= 1'b1;
                data_valid_out <= 1'b0;
                clock_counter <= 4'h0;
                cs_out <= 1'b0;
                sclk_out <= 1'b0;
                shift_reg <= 8'h03;
                miso_buf <= miso_in;
                state <= SEND_CMD;
            end
            else begin
                busy_out <= 1'b0;
                data_valid_out <= 1'b0;
                clock_counter <= 4'h0;
                cs_out <= 1'b1;
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
            if(state == SEND_CMD)begin
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
                shift_reg <= 8'h00;
                state <= READ_DATA_HIGH;
            end
            else if(state == READ_DATA_HIGH)begin
                data_out[15:8] <= {shift_reg[6:0],miso_buf};
                state <= READ_DATA_LOW;
            end
            else if(state == READ_DATA_LOW)begin
                data_out[7:0] <= {shift_reg[6:0],miso_buf};
                data_valid_out <= 1'b1;
                cs_out <= 1'b1;
                busy_out <= 1'b0;
                state <= IDLE;
            end
        end
    end
end


endmodule