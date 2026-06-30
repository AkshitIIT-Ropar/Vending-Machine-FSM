// =============================================================================
// Module      : vending_machine_tb
// Description : Self-checking testbench for vending_machine.v
//               Drives coin sequences, automatically checks dispense/change
//               against expected values, and prints PASS/FAIL per test case.
//               Also dumps a VCD waveform for visual inspection in GTKWave.
// =============================================================================

`timescale 1ns / 1ps

module vending_machine_tb;

    reg clk, rst_n, coin5, coin10, coin25;
    wire dispense;
    wire [2:0] change;

    integer pass_count = 0;
    integer fail_count = 0;

    // -------------------------------------------------------------------
    // Device under test
    // -------------------------------------------------------------------
    vending_machine uut (
        .clk      (clk),
        .rst_n    (rst_n),
        .coin5    (coin5),
        .coin10   (coin10),
        .coin25   (coin25),
        .dispense (dispense),
        .change   (change)
    );

    // -------------------------------------------------------------------
    // Clock generation: 100 MHz (10ns period)
    // -------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------
    // Task: insert_coin
    // Pulses exactly one coin line for one clock cycle.
    // which: 0 = coin5, 1 = coin10, 2 = coin25
    // -------------------------------------------------------------------
    task insert_coin;
        input [1:0] which;
        begin
            coin5  = (which == 0);
            coin10 = (which == 1);
            coin25 = (which == 2);
            @(posedge clk);
            #1;
            coin5  = 0;
            coin10 = 0;
            coin25 = 0;
        end
    endtask

    // -------------------------------------------------------------------
    // Task: check
    // Compares actual dispense/change against expected values after the
    // coin insertion has been processed, and logs PASS/FAIL.
    // -------------------------------------------------------------------
    task check;
        input        exp_dispense;
        input [2:0]  exp_change;
        input [255:0] label; // test case description string
        begin
            #1; // allow combinational outputs to settle
            if (dispense === exp_dispense && change === exp_change) begin
                $display("[PASS] %0s | dispense=%b change=%0dp", label, dispense, change*5);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | got dispense=%b change=%0dp | expected dispense=%b change=%0dp",
                          label, dispense, change*5, exp_dispense, exp_change*5);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------
    // Task: reset_dut
    // -------------------------------------------------------------------
    task reset_dut;
        begin
            rst_n  = 0;
            coin5  = 0;
            coin10 = 0;
            coin25 = 0;
            @(posedge clk);
            #1;
            rst_n = 1;
        end
    endtask

    // -------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------
    initial begin
        $dumpfile("vending_machine.vcd");
        $dumpvars(0, vending_machine_tb);

        $display("===========================================================");
        $display(" Vending Machine FSM - Self Checking Testbench");
        $display("===========================================================");

        reset_dut;

        // ---- Test 1: 10p + 10p + 10p = 30p exact ----
        insert_coin(1); check(0, 0, "T1a: 10p inserted, no dispense yet");
        insert_coin(1); check(0, 0, "T1b: 20p inserted, no dispense yet");
        insert_coin(1); check(1, 0, "T1c: 30p reached via 3x10p, exact change");
        @(posedge clk); #1; check(0, 0, "T1d: back to idle after dispense");

        // ---- Test 2: 5p + 25p = 30p exact ----
        reset_dut;
        insert_coin(0); check(0, 0, "T2a: 5p inserted");
        insert_coin(2); check(1, 0, "T2b: 5p+25p=30p exact change");
        @(posedge clk); #1;

        // ---- Test 3: 10p + 25p = 35p, change = 5p ----
        reset_dut;
        insert_coin(1); check(0, 0, "T3a: 10p inserted");
        insert_coin(2); check(1, 1, "T3b: 10p+25p=35p change=5p");
        @(posedge clk); #1;

        // ---- Test 4: 15p + 25p = 40p, change = 10p ----
        reset_dut;
        insert_coin(0); insert_coin(0); insert_coin(0); // 5+5+5=15p
        check(0, 0, "T4a: 15p collected via 3x5p");
        insert_coin(2); check(1, 2, "T4b: 15p+25p=40p change=10p");
        @(posedge clk); #1;

        // ---- Test 5: 20p + 10p = 30p exact ----
        reset_dut;
        insert_coin(1); insert_coin(1); // 10+10=20p
        check(0, 0, "T5a: 20p collected via 2x10p");
        insert_coin(1); check(1, 0, "T5b: 20p+10p=30p exact change");
        @(posedge clk); #1;

        // ---- Test 6: 20p + 25p = 45p, change = 15p ----
        reset_dut;
        insert_coin(1); insert_coin(1); // 20p
        check(0, 0, "T6a: 20p collected");
        insert_coin(2); check(1, 3, "T6b: 20p+25p=45p change=15p");
        @(posedge clk); #1;

        // ---- Test 7: 25p + 5p = 30p exact ----
        reset_dut;
        insert_coin(2); check(0, 0, "T7a: 25p inserted");
        insert_coin(0); check(1, 0, "T7b: 25p+5p=30p exact change");
        @(posedge clk); #1;

        // ---- Test 8: 25p + 10p = 35p, change = 5p ----
        reset_dut;
        insert_coin(2); check(0, 0, "T8a: 25p inserted");
        insert_coin(1); check(1, 1, "T8b: 25p+10p=35p change=5p");
        @(posedge clk); #1;

        // ---- Test 9: 25p + 25p = 50p, change = 20p (max overpay case) ----
        reset_dut;
        insert_coin(2); check(0, 0, "T9a: 25p inserted");
        insert_coin(2); check(1, 4, "T9b: 25p+25p=50p change=20p");
        @(posedge clk); #1;

        // ---- Test 10: all 5p coins, 6x5p = 30p exact ----
        reset_dut;
        insert_coin(0); insert_coin(0); insert_coin(0);
        insert_coin(0); insert_coin(0);
        check(0, 0, "T10a: 25p collected via 5x5p");
        insert_coin(0); check(1, 0, "T10b: 30p reached via 6x5p, exact change");
        @(posedge clk); #1;

        // ---- Test 11: mid-transaction reset clears state ----
        reset_dut;
        insert_coin(1); insert_coin(1); // 20p
        check(0, 0, "T11a: 20p collected before reset");
        reset_dut;
        check(0, 0, "T11b: state cleared after reset");
        insert_coin(2); check(0, 0, "T11c: 25p only, no dispense after reset");

        // ---- Summary ----
        $display("===========================================================");
        $display(" Results: %0d PASSED, %0d FAILED out of %0d tests",
                   pass_count, fail_count, pass_count + fail_count);
        if (fail_count == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" SOME TESTS FAILED - see log above");
        $display("===========================================================");

        $finish;
    end

endmodule
