`ifndef COMMON_PKG
`define COMMON_PKG
package common_pkg;

typedef enum logic [1:0] {
    TYPE_IDLE = 2'b00,
    TYPE_FLASH_READ = 2'b01,
    TYPE_PSRAM_READ = 2'b10,
    TYPE_PSRAM_WRITE = 2'b11
} mem_type_t;

endpackage
`endif

module SPI_FLASH(
    input logic sclk_in,
    input logic cs_in,
    input logic mosi_in,
    output logic miso_out
);

    //SPI FLASH emulation
    //Command and Address
    logic [7:0] command_reg;
    logic [23:0] address_reg;
    logic [7:0] memory_reg[0:1023];
    logic [6:0] counter;
    logic [7:0] out_data_reg;
    
    initial begin
        command_reg <= 8'b0;
        address_reg <= 24'b0;
        counter <= 7'b0;
        $readmemh("spi_flash_mem.txt",memory_reg);
    end

    //Reset internal registers
    always@(negedge cs_in)begin
        command_reg <= 8'b0;
        address_reg <= 24'b0;
        counter <= 7'b0;
        out_data_reg <= 8'b0;
    end

    assign miso_out = out_data_reg[7];

    always@(posedge sclk_in)begin//Sample Phase
        if(cs_in == 1'b0)begin
            if(counter < 7'd8)begin
                command_reg <= {command_reg[6:0],mosi_in};
            end
            else if(counter < 7'd32)begin
                address_reg <= {address_reg[22:0],mosi_in};
            end
            counter <= counter + 1;
        end
    end

    always@(negedge sclk_in)begin//Shift Phase
        if(cs_in == 1'b0)begin
            if(counter < 7'd32)begin
                out_data_reg <= 8'b0;
            end
            else if(counter < 7'd40)begin
                if(command_reg == 8'h03)begin
                    if(counter == 7'd32)begin
                        out_data_reg <= memory_reg[address_reg[15:0]];
                    end
                    else begin
                        out_data_reg <= {out_data_reg[6:0],1'b0};
                    end
                end
            end
            else if(counter < 7'd48)begin
                if(command_reg == 8'h03)begin
                    if(counter == 7'd40)begin
                        out_data_reg <= memory_reg[address_reg[15:0] + 1];
                    end
                    else begin
                        out_data_reg <= {out_data_reg[6:0],1'b0};
                    end
                end
            end
            else begin
                out_data_reg <= 8'b0;
            end
        end
    end
endmodule

module SPI_PSRAM (
    input logic sclk_in,
    input logic cs_in,
    input logic mosi_in,
    output logic miso_out
);

    //SPI PSRAM emulation
    //Command and Address
    logic [7:0] command_reg;
    logic [23:0] address_reg;
    logic [7:0] memory_reg[0:1023];
    logic [6:0] counter;
    logic [7:0] in_data_reg;
    logic [7:0] out_data_reg;
    
    initial begin
        command_reg <= 8'b0;
        address_reg <= 24'b0;
        counter <= 7'b0;
    end

    //Reset internal registers
    always@(negedge cs_in)begin
        command_reg <= 8'b0;
        address_reg <= 24'b0;
        counter <= 7'b0;
        in_data_reg <= 8'b0;
        out_data_reg <= 8'b0;
    end

    assign miso_out = out_data_reg[7];

    always@(posedge sclk_in)begin//Sample Phase
        if(cs_in == 1'b0)begin
            if(counter < 7'd8)begin
                command_reg <= {command_reg[6:0],mosi_in};
            end
            else if(counter < 7'd32)begin
                address_reg <= {address_reg[22:0],mosi_in};
            end
            else if(counter < 7'd40)begin
                //if command is write
                if(command_reg == 8'h02)begin
                    if(counter == 7'd39)begin
                        memory_reg[address_reg[15:0]] <= {in_data_reg[6:0],mosi_in};
                    end
                    else begin
                        in_data_reg <= {in_data_reg[6:0],mosi_in};
                    end
                end
            end
            counter <= counter + 1;
        end
    end

    always@(negedge sclk_in)begin//Shift Phase
        if(cs_in == 1'b0)begin
            if(counter < 7'd32)begin
                out_data_reg <= 8'b0;
            end
            else if(counter < 7'd40)begin
                if(command_reg == 8'h03)begin
                    if(counter == 7'd32)begin
                        out_data_reg <= memory_reg[address_reg[15:0]];
                    end
                    else begin
                        out_data_reg <= {out_data_reg[6:0],1'b0};
                    end
                end
            end
            else begin
                out_data_reg <= 8'b0;
            end
        end
    end
endmodule