/*
 * Copyright (c) 2024 Ryota Suzuki
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_ja1tye_tiny_cpu (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    logic miso_in;
    logic sclk_out;
    logic flash_cs_out;
    logic psram_cs_out;
    logic mosi_out;

    // All output pins must be assigned. If not used, assign to 0.
    assign uio_out = 0;
    assign uio_oe  = 0;

    assign miso_in = ui_in[0];

    assign uo_out[0] = sclk_out;
    assign uo_out[1] = flash_cs_out;
    assign uo_out[2] = psram_cs_out;
    assign uo_out[3] = mosi_out;
    assign uo_out[7:4] = 4'h0;

  tiny_mcu MCU(
    .clk_in(clk),
    .reset_in(~rst_n),
    .sclk_out(sclk_out),
    .flash_cs_out(flash_cs_out),
    .psram_cs_out(psram_cs_out),
    .mosi_out(mosi_out),
    .miso_in(miso_in)
  );

endmodule
