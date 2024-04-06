module mcu_peripheral(
    input logic clk_in,
    input logic reset_in,

    //SPI signals
    output logic sclk_out,
    output logic mosi_out,
    output logic cs_out,

    //GPIO signals
    input logic [7:0] gpio_in,
    output logic [7:0] gpio_out,
    output logic [7:0] gpio_dir_out,

    //To Memory bus
    output logic [7:0] periph_data_out,
    output logic periph_data_valid_out,
    input logic  [7:0] periph_data_in,
    input logic [3:0]periph_addr_in,
    input logic periph_addr_valid_in,
    input logic periph_write_en_in
);
//Peripheral Address Map
//Address[15:12] == 0xf
//0xfx00:GPIO Dir
//0xfx01:GPIO Out
//0xfx02:GPIO In
//0xfx04:SPI Divider Value
//0xfx05:SPI CS Control
//0xfx06:SPI Status
//0xfx07:SPI Data

//2FF Synchronizer for GPIO input
logic [7:0] gpio_in_sync;
logic [7:0] gpio_in_reg;

//Memory Interface
always@(posedge clk_in) begin
    //2FF Synchronizer
    gpio_in_sync <= gpio_in;
    gpio_in_reg <= gpio_in_sync;

    if(reset_in) begin
        periph_data_out <= 8'h00;
        periph_data_valid_out <= 1'b0;
        gpio_dir_out <= 8'h00;
        gpio_out <= 8'h00;
        cs_out <= 1'b1;
    end
    else begin
        if(periph_addr_valid_in) begin
            if(periph_write_en_in) begin//Write
                case(periph_addr_in[3:0])
                    4'h0:begin//GPIO Dir
                        gpio_dir_out <= periph_data_in;
                    end
                    4'h1:begin//GPIO Out
                        gpio_out <= periph_data_in;
                    end
                    4'h4:begin//SPI Divider Value
                        div_val_reg <= periph_data_in[3:0];
                    end
                    4'h5:begin//SPI CS Control
                        cs_out <= periph_data_in[0];
                    end
                    4'h7:begin//SPI Data
                        if(busy_flag == 1'b0) begin
                            shift_reg <= periph_data_in;
                            busy_flag <= 1'b1;
                        end
                    end
                endcase
                periph_data_valid_out <= 1'b0;
            end
            else begin//Read
                case(periph_addr_in[3:0])
                    4'h0:begin//GPIO Dir
                        periph_data_out <= gpio_dir_out;
                    end
                    4'h1:begin//GPIO Out
                        periph_data_out <= gpio_out;
                    end
                    4'h2:begin//GPIO In
                        periph_data_out <= gpio_in_reg;
                    end
                    4'h4:begin//SPI Divider Value
                        periph_data_out <= {4'h0,div_val_reg};
                    end
                    4'h5:begin//SPI CS Control
                        periph_data_out <= {7'h0,cs_out};
                    end
                    4'h6:begin//SPI Status
                        periph_data_out <= {7'h0,busy_flag};
                    end
                    4'h7:begin//SPI Data
                        periph_data_out <= shift_reg;
                    end
                    default:begin
                        periph_data_out <= 8'h00;
                    end
                endcase
                periph_data_valid_out <= 1'b1;
            end
        end
        else begin
            periph_data_valid_out <= 1'b0;
        end
    end
end

//SPI Shift Register
logic [7:0] shift_reg;
logic [2:0] clock_counter;
logic [3:0] clock_div;
logic [3:0] div_val_reg;
logic busy_flag;

assign mosi_out = shift_reg[7];

always@(posedge clk_in) begin
    if(reset_in) begin
        shift_reg <= 8'h00;
        clock_counter <= 3'b0;
        clock_div <= 3'b0;
        busy_flag <= 1'b0;
        sclk_out <= 1'b0;
    end
    else begin
        if(busy_flag == 1'b1)begin
            if(clock_div == div_val_reg) begin
                clock_div <= 3'b0;
                if(sclk_out == 1'b0)begin//Sample Edge
                    sclk_out <= 1'b1;
                end
                else begin//Shift Edge
                    sclk_out <= 1'b0;
                    if(clock_counter == 4'h7)begin
                        clock_counter <= 4'h0;
                        busy_flag <= 1'b0;
                    end
                    else begin
                        clock_counter <= clock_counter + 1;
                        shift_reg <= {shift_reg[6:0],shift_reg[7]};
                    end
                end
            end
            else begin
                clock_div <= clock_div + 1;
            end
        end
    end
end

endmodule