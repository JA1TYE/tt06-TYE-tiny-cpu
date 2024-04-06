`timescale 1ns/1ps

module top_sim();
    //Control signals
    logic clk_in;
    logic reset_in;

    //SPI signals
    logic flash_cs_out;
    logic psram_cs_out;
    logic sclk_out;
    logic mosi_out;
    tri miso_in;

    logic flash_miso_out;
    logic psram_miso_out;

    //assign miso_in = (flash_cs_out == 1'b0) ? flash_miso_out : psram_miso_out;

    assign miso_in = flash_miso_out;
    assign miso_in = psram_miso_out;

    logic [7:0]ui_in;
    logic [7:0]uo_out;
    
    assign ui_in[0] = miso_in;
    assign sclk_out = uo_out[0];
    assign flash_cs_out = uo_out[1];
    assign psram_cs_out = uo_out[2];
    assign mosi_out = uo_out[3];

    tt_um_ja1tye_tiny_cpu DUT(
        .clk(clk_in),
        .rst_n(~reset_in),
        .ena(1'b1),
        .ui_in(ui_in),
        .uio_in(8'h00),
        .uo_out(uo_out),
        .uio_out(),
        .uio_oe()
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
        $dumpfile("top_sim.vcd");
        $dumpvars(0,top_sim);
        $display("clk_unit:%f\n",clk_unit);
        clk_in <= 1'b0;
        reset_in <= 1'b1;
        repeat(10)@(posedge clk_in);
        reset_in    <= 0;
        @(posedge clk_in);
        count = 0;
        repeat(100000)@(posedge clk_in);
        $display("pc:%x",DUT.MCU.pc_addr);
        $finish;
    end

    always@(posedge clk_in)begin
        count = count + 1;
    end

    always begin
        #(clk_unit/2.0) clk_in <= ~clk_in;
    end

endmodule