module morse_code_encoder_part1 (
    input clk,              // 100 MHz system clock
    input rst,              // Asynchronous reset, active high (BTN0)
    input start,            // Start encoding (BTN1)
    input [3:0] digit_in,   // 4-bit digit input (0-9)
    output reg led          // LED output for Morse code
);

    // Timing constants (for a 100 MHz clock)
    parameter CLK_HZ = 100_000_000;
    parameter DOT_LEN = CLK_HZ * 1;      // 1 second for dot
    parameter DASH_LEN = CLK_HZ * 3;     // 3 seconds for dash
    parameter SYMBOL_GAP = CLK_HZ / 2;   // 0.5 second gap between symbols

    // FSM State Definitions
    localparam STATE_IDLE      = 4'd0;
    localparam STATE_LOAD      = 4'd1;
    localparam STATE_SEND      = 4'd2;
    localparam STATE_WAIT_GAP  = 4'd3;
    localparam STATE_DONE      = 4'd4;

    reg [3:0] current_state = STATE_IDLE;
    reg [3:0] next_state;

    // Registers for Morse conversion and counting
    reg [4:0] morse_code;            // 5-bit Morse pattern
    reg [2:0] symbol_count;          // Always 5 for digits
    reg [2:0] symbol_index;          // Which symbol of the digit we are on
    reg [31:0] timer;                // Timer counter for duration

    // FSM next state combinational logic
    always @(*) begin
        case (current_state)
            STATE_IDLE: begin
                if (start) // When the start button is pressed, load the digit
                    next_state = STATE_LOAD;
                else
                    next_state = STATE_IDLE;
            end

            STATE_LOAD: begin
                next_state = STATE_SEND;
            end

            STATE_SEND: begin
                // Stay in SEND until the timer expires
                if (timer == 0)
                    next_state = STATE_WAIT_GAP;
                else
                    next_state = STATE_SEND;
            end

            STATE_WAIT_GAP: begin
                // When gap time is over:
                if (timer == 0) begin
                    if (symbol_index == symbol_count - 1)
                        next_state = STATE_DONE;
                    else
                        next_state = STATE_SEND;
                end
                else
                    next_state = STATE_WAIT_GAP;
            end

            STATE_DONE: begin
                // After finishing all symbols, return to idle state.
                next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // FSM sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= STATE_IDLE;
            led <= 0;
            timer <= 0;
            symbol_index <= 0;
            morse_code <= 0;
            symbol_count <= 0;
        end else begin
            current_state <= next_state;
            case (current_state)
                STATE_IDLE: begin
                    led <= 0;
                    // When start is asserted, remain in idle until the clock edge
                    symbol_index <= 0;
                end

                STATE_LOAD: begin
                    // Convert the 4-bit input to a 5-bit Morse code pattern
                    case(digit_in)
                        4'd0: begin morse_code <= 5'b11111; symbol_count <= 5; end  // 0: -----
                        4'd1: begin morse_code <= 5'b01111; symbol_count <= 5; end  // 1: .----
                        4'd2: begin morse_code <= 5'b00111; symbol_count <= 5; end  // 2: ..---
                        4'd3: begin morse_code <= 5'b00011; symbol_count <= 5; end  // 3: ...--
                        4'd4: begin morse_code <= 5'b00001; symbol_count <= 5; end  // 4: ....-
                        4'd5: begin morse_code <= 5'b00000; symbol_count <= 5; end  // 5: .....
                        4'd6: begin morse_code <= 5'b10000; symbol_count <= 5; end  // 6: -....
                        4'd7: begin morse_code <= 5'b11000; symbol_count <= 5; end  // 7: --...
                        4'd8: begin morse_code <= 5'b11100; symbol_count <= 5; end  // 8: ---..
                        4'd9: begin morse_code <= 5'b11110; symbol_count <= 5; end  // 9: ----.
                        default: begin morse_code <= 5'b00000; symbol_count <= 5; end
                    endcase
                    // Initialize timer based on the first symbol.
                    // We check the most-significant bit of morse_code.
                    timer <= (morse_code[4] == 1) ? DASH_LEN : DOT_LEN;
                    led <= 1; // LED on for the first symbol
                end

                STATE_SEND: begin
                    if (timer > 0)
                        timer <= timer - 1;
                    else begin
                        // Symbol duration complete, turn LED off.
                        led <= 0;
                        // Set timer for gap before next symbol.
                        timer <= SYMBOL_GAP;
                    end
                end

                STATE_WAIT_GAP: begin
                    if (timer > 0)
                        timer <= timer - 1;
                    else begin
                        // Gap finished. Move to next symbol if available.
                        symbol_index <= symbol_index + 1;
                        if (symbol_index < symbol_count - 1) begin
                            // Load next symbol's duration: bit order MSB-first.
                            timer <= (morse_code[4 - (symbol_index + 1)] == 1) ? DASH_LEN : DOT_LEN;
                            led <= 1;
                        end
                    end
                end

                STATE_DONE: begin
                    led <= 0;
                    // Stay in DONE briefly, then return to IDLE on the next cycle.
                end

                default: begin
                    led <= 0;
                end
            endcase
        end
    end

endmodule
