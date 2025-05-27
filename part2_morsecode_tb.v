`timescale 1ns/1ps

module tb_morse_code_encoder;

    // Inputs
    reg clk;
    reg rst;
    reg start_single;
    reg start_sequence;
    reg [3:0] digit_in;
    reg mode_select;

    // Output
    wire led;

    // Instantiate the Unit Under Test (UUT)
    morse_code_encoder #(
        .CLK_HZ(100_000) // Use 100 kHz instead of 100 MHz for faster simulation
    ) uut (
        .clk(clk),
        .rst(rst),
        .start_single(start_single),
        .start_sequence(start_sequence),
        .digit_in(digit_in),
        .mode_select(mode_select),
        .led(led)
    );

    // Clock generation (10 us period = 100 kHz)
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $display("Starting testbench for morse_code_encoder...");

        // Initialize Inputs
        clk = 0;
        rst = 1;
        start_single = 0;
        start_sequence = 0;
        digit_in = 0;
        mode_select = 0;

        // Reset pulse
        #20;
        rst = 0;

        // Test single digit mode (digit = 5 = ".....")
        mode_select = 0;       // digit mode
        digit_in = 4'd5;
        start_single = 1;
        #10;
        start_single = 0;

        // Wait for the sequence to play out
        #500000; // Wait enough time for the sequence

        // Test sequence mode: store 3 digits and encode
        mode_select = 1; // number mode

        // Store 3 digits (1, 2, 3)
        digit_in = 4'd1;
        start_single = 1;
        #10; start_single = 0;
        #1000;

        digit_in = 4'd2;
        start_single = 1;
        #10; start_single = 0;
        #1000;

        digit_in = 4'd3;
        start_single = 1;
        #10; start_single = 0;
        #1000;

        // Start sequence
        start_sequence = 1;
        #10; start_sequence = 0;

        // Wait for the full sequence to finish
        #2000000;

        $display("Testbench completed.");
        $finish;
    end

endmodule
