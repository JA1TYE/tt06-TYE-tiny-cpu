`timescale 1ns/1ps
`default_nettype none

module spi_mem_sim();
    //Control signals
    logic clk_in;
    logic reset_in;

    //SPI signals
    logic flash_cs_out;
    logic psram_cs_out;
    logic sclk_out;
    logic mosi_out;
    tri miso_in;

    //System bus signals
    logic [15:0] addr_in;
    logic addr_valid_in;
    logic [7:0] psram_data_in;
    logic [15:0] flash_data_out;
    logic flash_data_valid_out;
    logic [7:0] psram_data_out;
    logic psram_data_valid_out;
    logic busy_out;
    
    mem_type_t mem_type_in;

    logic flash_miso_out;
    logic psram_miso_out;

    assign miso_in = flash_miso_out;
    assign miso_in = psram_miso_out;

    spi_flash_controller DUT(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .sclk_out(sclk_out),
        .flash_cs_out(flash_cs_out),
        .psram_cs_out(psram_cs_out),
        .mosi_out(mosi_out),
        .miso_in(miso_in),
        .addr_in(addr_in),
        .addr_valid_in(addr_valid_in),
        .psram_data_in(psram_data_in),
        .mem_type_in(mem_type_in),
        .flash_data_out(flash_data_out),
        .flash_data_valid_out(flash_data_valid_out),
        .psram_data_out(psram_data_out),
        .psram_data_valid_out(psram_data_valid_out),
        .busy_out(busy_out)
        );

    SPI_FLASH spi_flash(
        .sclk_in(sclk_out),
        .cs_in(flash_cs_out),
        .mosi_in(mosi_out),
        .miso_out(flash_miso_out)
    );

    SPI_PSRAM spi_psram(
        .sclk_in(sclk_out),
        .cs_in(psram_cs_out),
        .mosi_in(mosi_out),
        .miso_out(psram_miso_out)
    );

    parameter real clk_unit = (1000_000_000.0/50_000_000.0);

    integer count = 0;

    initial begin
        $dumpfile("spi_mem.vcd");
        $dumpvars(0,spi_mem_sim);
        $display("clk_unit:%f\n",clk_unit);
        clk_in <= 1'b0;
        reset_in <= 1'b1;
        addr_valid_in <=1'b0;
        mem_type_in <= TYPE_IMEM_READ;
        addr_in <= 16'h0004;
        repeat(10)@(posedge clk_in);
        reset_in    <= 0;
        @(posedge clk_in);

        addr_valid_in <= 1'b1;
        count = 0;
        @(posedge clk_in);
        addr_valid_in <= 1'b0;
        @(negedge busy_out);
        $display("Flash Data:%h",flash_data_out);

        @(posedge clk_in);
        addr_valid_in <= 1'b1;
        mem_type_in <= TYPE_DMEM_READ;
        count = 0;
        @(posedge clk_in);
        addr_valid_in <= 1'b0;
        @(negedge busy_out);
        $display("PSRAM Data(before Write):%h",psram_data_out);

        @(posedge clk_in);
        addr_valid_in <= 1'b1;
        mem_type_in <= TYPE_DMEM_WRITE;
        psram_data_in <= 8'h55;
        count = 0;
        @(posedge clk_in);
        addr_valid_in <= 1'b0;
        @(negedge busy_out);
        $display("PSRAM Data Write Done!");

        @(posedge clk_in);
        addr_valid_in <= 1'b1;
        mem_type_in <= TYPE_DMEM_READ;
        count = 0;
        @(posedge clk_in);
        addr_valid_in <= 1'b0;
        @(negedge busy_out);
        $display("PSRAM Data(after Write):%h",psram_data_out);
        repeat(10000)@(posedge clk_in);
        $finish;
    end

    always@(posedge clk_in)begin
        count = count + 1;
    end

    always begin
        #(clk_unit/2.0) clk_in <= ~clk_in;
    end

endmodule