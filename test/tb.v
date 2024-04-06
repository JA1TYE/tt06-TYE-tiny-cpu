`default_nettype none `timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  wire [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  //SPI signals
  wire flash_cs_out;
  wire psram_cs_out;
  wire sclk_out;
  wire mosi_out;
  tri miso_in;

  wire flash_miso_out;
  wire psram_miso_out;

  assign ui_in[0] = miso_in;
  assign ui_in[7:1] = 7'b0;
  
  assign sclk_out = uo_out[0];
  assign flash_cs_out = uo_out[1];
  assign psram_cs_out = uo_out[2];
  assign mosi_out = uo_out[3];
  assign miso_in = flash_miso_out;
  assign miso_in = psram_miso_out;

  //Peripherals for test
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

  // Replace tt_um_example with your module name:
  tt_um_ja1tye_tiny_cpu user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
