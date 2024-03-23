`timescale 1ns/1ps
module spi_mem_sim();
    //Control signals
    logic clk_in;
    logic reset_in;

    //SPI signals
    logic sclk_out;
    logic cs_out;
    logic mosi_out;
    logic miso_in;

    //System bus signals
    logic [15:0] addr_in;
    logic addr_valid_in;
    logic [15:0] data_out;
    logic data_valid_out;
    logic busy_out;

    spi_flash_controller DUT(
        .clk_in(clk_in),
        .reset_in(reset_in),
        .sclk_out(sclk_out),
        .cs_out(cs_out),
        .mosi_out(mosi_out),
        .miso_in(miso_in),
        .addr_in(addr_in),
        .addr_valid_in(addr_valid_in),
        .data_out(data_out),
        .data_valid_out(data_valid_out),
        .busy_out(busy_out)
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
        addr_in <= 16'h1234;
        repeat(10)@(posedge clk_in);
        reset_in    <= 0;
        @(posedge clk_in);
        addr_valid_in <= 1'b1;
        count = 0;
        @(posedge clk_in);
        addr_valid_in <= 1'b0;
        repeat(10000)@(posedge clk_in);
        $finish;
    end

    always@(posedge clk_in)begin
        count = count + 1;
    end

    //SPI Flash emulation
    //Command and Address
    logic [31:0] input_reg;
    logic [6:0] pulse_counter;
    initial begin
        input_reg <= 32'b0;
        output_reg <= 16'h8086;
        pulse_counter <= 6'h0;
    end

    always@(posedge sclk_out)begin
        if(cs_out == 1'b0)begin
            if(pulse_counter < 6'd32)begin
                input_reg <= {input_reg[30:0],mosi_out};
                pulse_counter <= pulse_counter + 1;
            end
        end
        else begin
            input_reg <= 32'b0;
            pulse_counter <= 6'h0;
        end
    end
    logic [15:0] output_reg;

    always@(negedge sclk_out)begin
        if(cs_out == 1'b0)begin
            if((pulse_counter > 6'd31) && (pulse_counter < 6'd49))begin
                miso_in <= output_reg[15];
                output_reg <= {output_reg[14:0],1'b0};
                pulse_counter <= pulse_counter + 1;
            end
        end
        else begin
            output_reg <= 16'h8086;
            pulse_counter <= 6'h0;
        end
    end

    always begin
        #(clk_unit/2.0) clk_in <= ~clk_in;
    end

endmodule