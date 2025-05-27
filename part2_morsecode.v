module morse_code_encoder (
    input clk,                  // 100 MHz system clock
    input rst,                  // Active high reset (BTN0)
    input start_single,         // BTN1 - Store or encode one digit
    input start_sequence,       // BTN2 - Begin full digit buffer encoding
    input [3:0] digit_in,       // Input digit from switches 0-3
    input mode_select,          // Switch 4: 0 = digit mode, 1 = number mode
    output reg led              // Morse code output on LED
);

    // Clock-based timing constants
    parameter CLK_HZ = 100_000_000;
    parameter DOT_LEN = CLK_HZ * 1;          // 1 second
    parameter DASH_LEN = CLK_HZ * 3;         // 3 seconds
    parameter SYMBOL_GAP = CLK_HZ / 2;       // 0.5 seconds
    parameter DIGIT_PAUSE = CLK_HZ * 10;     // 10 seconds
    
//    // Clock-based timing constants
//    parameter CLK_HZ = 100_000_000;
//    parameter DOT_LEN = (CLK_HZ * 1) / 1_000_000;    // 1 us (originally 1 second)
//    parameter DASH_LEN = (CLK_HZ * 3) / 1_000_000;   // 3 us (originally 3 seconds)
//    parameter SYMBOL_GAP = (CLK_HZ / 2) / 1_000_000; // 0.5 us (originally 0.5 seconds)
//    parameter DIGIT_PAUSE = (CLK_HZ * 2) / 1_000_000; // 2 us (originally 2 seconds)

    // FSM state definitions using localparams
    localparam STATE_IDLE        = 4'd0;
    localparam STATE_STORE       = 4'd1;
    localparam STATE_LOAD        = 4'd2;
    localparam STATE_SEND        = 4'd3;
    localparam STATE_WAIT_GAP    = 4'd4;
    localparam STATE_WAIT_DIGIT  = 4'd5;
    localparam STATE_NEXT        = 4'd6;
    localparam STATE_DONE        = 4'd7;

    reg [3:0] current_state = STATE_IDLE;
    reg [3:0] next_state;

    // Button edge detection
    reg prev_single, prev_sequence;
    wire single_edge = start_single & ~prev_single;
    wire sequence_edge = start_sequence & ~prev_sequence;

    // Registers
    reg [3:0] digit_buffer[0:5];
    reg [2:0] total_digits = 0;
    reg [2:0] current_index = 0;
    reg [4:0] morse_code;
    reg [2:0] symbol_count;
    reg [2:0] symbol_index;
    reg [31:0] timer = 0;
    reg [3:0] active_digit = 0;
    reg timer_set = 0;  // New flag to track timer initialization for digit pause

    // Edge detection registers
    always @(posedge clk) begin
        prev_single <= start_single;
        prev_sequence <= start_sequence;
    end

    // FSM state update
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    // FSM next state logic
    always @(*) begin
        case (current_state)
            STATE_IDLE: begin
                if (mode_select == 1'b1) begin
                    if (sequence_edge) next_state = STATE_LOAD;
                    else if (single_edge) next_state = STATE_STORE;
                    else next_state = STATE_IDLE;
                end else begin
                    if (single_edge) next_state = STATE_LOAD;
                    else next_state = STATE_IDLE;
                end
            end
            STATE_STORE:      next_state = STATE_IDLE;
            STATE_LOAD:       next_state = STATE_SEND;
            STATE_SEND:       next_state = (timer == 0) ? STATE_WAIT_GAP : STATE_SEND;
            STATE_WAIT_GAP: begin
                if (timer == 0) begin
                    if (symbol_index == symbol_count - 1) begin
                        if (current_index < total_digits - 1)
                            next_state = STATE_WAIT_DIGIT;
                        else
                            next_state = STATE_DONE;
                    end else
                        next_state = STATE_SEND;
                end else
                    next_state = STATE_WAIT_GAP;
            end
            STATE_WAIT_DIGIT: next_state = (timer == 0 && timer_set) ? STATE_NEXT : STATE_WAIT_DIGIT;
            STATE_NEXT:       next_state = STATE_LOAD;
            STATE_DONE:       next_state = STATE_IDLE;
            default:          next_state = STATE_IDLE;
        endcase
    end

    // Main FSM logic
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led <= 0;
            total_digits <= 0;
            current_index <= 0;
            symbol_index <= 0;
            timer <= 0;
            active_digit <= 0;
            timer_set <= 0;  // Reset timer_set
            for (i = 0; i < 6; i = i + 1)
                digit_buffer[i] <= 0;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    led <= 0;
                    timer_set <= 0;  // Reset timer_set in IDLE
                end
                STATE_STORE: begin
                    if (total_digits < 6) begin
                        digit_buffer[total_digits] <= digit_in;
                        total_digits <= total_digits + 1;
                    end
                end
                STATE_LOAD: begin
                    active_digit <= (mode_select) ? digit_buffer[current_index] : digit_in;
                    case ((mode_select) ? digit_buffer[current_index] : digit_in)
                        4'd0: begin morse_code <= 5'b11111; symbol_count <= 5; end
                        4'd1: begin morse_code <= 5'b01111; symbol_count <= 5; end
                        4'd2: begin morse_code <= 5'b00111; symbol_count <= 5; end
                        4'd3: begin morse_code <= 5'b00011; symbol_count <= 5; end
                        4'd4: begin morse_code <= 5'b00001; symbol_count <= 5; end
                        4'd5: begin morse_code <= 5'b00000; symbol_count <= 5; end
                        4'd6: begin morse_code <= 5'b10000; symbol_count <= 5; end
                        4'd7: begin morse_code <= 5'b11000; symbol_count <= 5; end
                        4'd8: begin morse_code <= 5'b11100; symbol_count <= 5; end
                        4'd9: begin morse_code <= 5'b11110; symbol_count <= 5; end
                        default: begin morse_code <= 5'b00000; symbol_count <= 0; end
                    endcase
                    symbol_index <= 0;
                    timer <= (morse_code[4] == 1) ? DASH_LEN : DOT_LEN;
                    led <= 1;
                    timer_set <= 0;  // Reset timer_set
                end
                STATE_SEND: begin
                    if (timer > 0)
                        timer <= timer - 1;
                    else begin
                        led <= 0;
                        timer <= SYMBOL_GAP;
                    end
                end
                STATE_WAIT_GAP: begin
                    if (timer > 0)
                        timer <= timer - 1;
                    else begin
                        symbol_index <= symbol_index + 1;
                        if (symbol_index < symbol_count - 1) begin
                            timer <= (morse_code[4 - (symbol_index + 1)] == 1) ? DASH_LEN : DOT_LEN;
                            led <= 1;
                        end
                    end
                end
                STATE_WAIT_DIGIT: begin
                    led <= 0;
                    if (timer == 0 && !timer_set) begin
                        timer <= DIGIT_PAUSE;
                        timer_set <= 1;  // Set flag to indicate timer is initialized
                    end else if (timer > 0) begin
                        timer <= timer - 1;
                    end
                end
                STATE_NEXT: begin
                    current_index <= current_index + 1;
                    timer_set <= 0;  // Reset timer_set for next digit
                end
                STATE_DONE: begin
                    led <= 0;
                    current_index <= 0;
                    total_digits <= 0;
                    timer_set <= 0;  // Reset timer_set
                end
            endcase
        end
    end
endmodule