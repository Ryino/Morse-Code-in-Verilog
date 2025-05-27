`timescale 1ns / 1ps
module tb_morse_code_encoder_part1;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [3:0] digit_in;

    // Output
    wire led;

    // Instantiate the DUT
    morse_code_encoder_part1 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .digit_in(digit_in),
        .led(led)
    );

    // Clock generation: 100 MHz -> 10ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        digit_in = 4'd0;

        // Apply reset
        #20;
        rst = 0;


        digit_in = 4'd3;
        #20;
        start = 1;
        #20;
        start = 0;


        #500_000_000;
        $finish;
    end

endmodule
