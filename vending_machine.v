// =============================================================================
// Module      : vending_machine
// Description : Moore FSM based vending machine controller.
//               Accepts 5p, 10p, and 25p coins, accumulates the total, and
//               dispenses an item once the total reaches or exceeds 30p.
//               Returns correct change (0p / 5p / 10p / 15p / 20p) where
//               applicable.
// Author      : AK
// Date        : 2026
// =============================================================================

module vending_machine (
    input  wire       clk,      // system clock
    input  wire       rst_n,    // active-low synchronous reset
    input  wire       coin5,    // insert 5 paise coin (pulse, 1 cycle)
    input  wire       coin10,   // insert 10 paise coin (pulse, 1 cycle)
    input  wire       coin25,   // insert 25 paise coin (pulse, 1 cycle)
    output reg        dispense, // 1 = item dispensed this cycle
    output reg  [2:0] change    // change returned: 0=0p 1=5p 2=10p 3=15p 4=20p
);

    // -------------------------------------------------------------------
    // State encoding
    // -------------------------------------------------------------------
    parameter S0       = 3'd0;  // 0 paise collected
    parameter S5       = 3'd1;  // 5 paise collected
    parameter S10      = 3'd2;  // 10 paise collected
    parameter S15      = 3'd3;  // 15 paise collected
    parameter S20      = 3'd4;  // 20 paise collected
    parameter S25      = 3'd5;  // 25 paise collected
    parameter DISPENSE = 3'd6;  // total >= 30p, dispense item

    reg [2:0] state, next_state;
    reg [2:0] prev_state;       // remembers which state led into DISPENSE
    reg [1:0] trig_coin, trig_coin_next; // 0=none 1=coin5 2=coin10 3=coin25

    // -------------------------------------------------------------------
    // Always block 1: state register (sequential)
    // -------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n)
            state <= S0;
        else
            state <= next_state;
    end

    // Track the state we came from and which coin triggered the transition.
    // Both are needed to compute the correct change amount in DISPENSE.
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_state <= S0;
            trig_coin  <= 2'd0;
        end else begin
            prev_state <= state;
            trig_coin  <= trig_coin_next;
        end
    end

    // Combinationally capture which coin is active right now, so it is
    // ready to latch on the next clock edge alongside prev_state.
    always @(*) begin
        trig_coin_next = 2'd0;
        if      (coin5)  trig_coin_next = 2'd1;
        else if (coin10) trig_coin_next = 2'd2;
        else if (coin25) trig_coin_next = 2'd3;
    end

    // -------------------------------------------------------------------
    // Always block 2: next-state logic (combinational)
    // -------------------------------------------------------------------
    always @(*) begin
        next_state = state; // default: hold current state, avoids latch inference
        case (state)
            S0: begin
                if      (coin5)  next_state = S5;
                else if (coin10) next_state = S10;
                else if (coin25) next_state = S25;
            end
            S5: begin
                if      (coin5)  next_state = S10;
                else if (coin10) next_state = S15;
                else if (coin25) next_state = DISPENSE; // 5+25=30 exact
            end
            S10: begin
                if      (coin5)  next_state = S15;
                else if (coin10) next_state = S20;
                else if (coin25) next_state = DISPENSE; // 10+25=35, change=5p
            end
            S15: begin
                if      (coin5)  next_state = S20;
                else if (coin10) next_state = S25;
                else if (coin25) next_state = DISPENSE; // 15+25=40, change=10p
            end
            S20: begin
                if      (coin5)  next_state = S25;
                else if (coin10) next_state = DISPENSE; // 20+10=30 exact
                else if (coin25) next_state = DISPENSE; // 20+25=45, change=15p
            end
            S25: begin
                if      (coin5)  next_state = DISPENSE; // 25+5=30 exact
                else if (coin10) next_state = DISPENSE; // 25+10=35, change=5p
                else if (coin25) next_state = DISPENSE; // 25+25=50, change=20p
            end
            DISPENSE: next_state = S0; // always return to idle after dispensing
            default:  next_state = S0;
        endcase
    end

    // -------------------------------------------------------------------
    // Always block 3: output logic (combinational, Moore style)
    // Outputs depend only on current state, prev_state, and trig_coin —
    // all of which are registered, so this remains a valid Moore output
    // (a function of state only, since prev_state/trig_coin are part of
    // the extended state captured by the flip-flops above).
    // -------------------------------------------------------------------
    always @(*) begin
        dispense = 1'b0;
        change   = 3'd0;
        if (state == DISPENSE) begin
            dispense = 1'b1;
            case ({prev_state, trig_coin})
                {S5,  2'd3}: change = 3'd0; // 5+25=30  -> 0p
                {S10, 2'd3}: change = 3'd1; // 10+25=35 -> 5p
                {S15, 2'd3}: change = 3'd2; // 15+25=40 -> 10p
                {S20, 2'd2}: change = 3'd0; // 20+10=30 -> 0p
                {S20, 2'd3}: change = 3'd3; // 20+25=45 -> 15p
                {S25, 2'd1}: change = 3'd0; // 25+5=30  -> 0p
                {S25, 2'd2}: change = 3'd1; // 25+10=35 -> 5p
                {S25, 2'd3}: change = 3'd4; // 25+25=50 -> 20p
                default:     change = 3'd0;
            endcase
        end
    end

endmodule
