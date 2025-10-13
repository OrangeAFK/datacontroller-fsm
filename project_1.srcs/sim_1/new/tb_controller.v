`timescale 1ns / 1ps
module tb_fsm_deterministic;

    // Inputs
    reg CLK, RESET, REQ, RW, MEM_READY;

    // Outputs
    wire MEM_EN_moore, DATA_EN_moore, DONE_moore;
    wire MEM_EN_mealy, DATA_EN_mealy, DONE_mealy;

    // Clock parameters
    parameter CLK_PERIOD = 10;

    // Clock generation
    always #(CLK_PERIOD/2) CLK = ~CLK;

    // Instantiate DUTs
    moore uut_moore (
        .REQ(REQ), .RW(RW), .CLK(CLK), .RESET(RESET),
        .MEM_READY(MEM_READY),
        .MEM_EN(MEM_EN_moore), .DATA_EN(DATA_EN_moore), .DONE(DONE_moore)
    );

    mealy uut_mealy (
        .REQ(REQ), .RW(RW), .CLK(CLK), .RESET(RESET),
        .MEM_READY(MEM_READY),
        .MEM_EN(MEM_EN_mealy), .DATA_EN(DATA_EN_mealy), .DONE(DONE_mealy)
    );

    //----------------------------------------------------------------------
    // Helper tasks for clean deterministic stimulus
    //----------------------------------------------------------------------

    // Apply synchronous reset
    task do_reset;
        begin
            RESET = 1;
            #(3*CLK_PERIOD);
            RESET = 0;
        end
    endtask

    // Deterministic test sequence for read and write operations
    task do_transaction(input RW_mode, input integer ready_delay, input integer hold_time);
        begin
            RW = RW_mode;
            REQ = 1;
            MEM_READY = 0;

            // Wait before memory becomes ready
            #(ready_delay);
            MEM_READY = 1;

            // Hold REQ and READY high for defined time
            #(hold_time);
            REQ = 0;
            MEM_READY = 0;
        end
    endtask

    //----------------------------------------------------------------------
    // Main deterministic sequence
    //----------------------------------------------------------------------

    initial begin
        // VCD dump for waveform inspection
        $dumpfile("fsm_deterministic.vcd");
        $dumpvars(0, tb_fsm_deterministic);

        // Initialize
        CLK = 0; RESET = 0; REQ = 0; RW = 0; MEM_READY = 0;

        do_reset();

        $display("\n=== Starting Deterministic FSM Timing Test ===\n");

        // Test 1: READ - memory ready quickly after REQ
        $display("\n-- Test 1: READ (fast memory) --");
        do_transaction(0, 2*CLK_PERIOD, 5*CLK_PERIOD);

        // Test 2: WRITE - memory ready delayed
        $display("\n-- Test 2: WRITE (slow memory) --");
        do_transaction(1, 8*CLK_PERIOD, 3*CLK_PERIOD);

        // Test 3: READ - memory ready coincides exactly with rising CLK edge
        $display("\n-- Test 3: READ (ready aligns with clock edge) --");
        REQ = 1; RW = 0; MEM_READY = 0;
        #(CLK_PERIOD - 1); MEM_READY = 1;  // Just before clock edge
        #(2*CLK_PERIOD);
        REQ = 0; MEM_READY = 0;

        // Test 4: WRITE - MEM_READY glitch before actual ready
        $display("\n-- Test 4: WRITE (ready glitch before valid) --");
        REQ = 1; RW = 1;
        MEM_READY = 1; #(CLK_PERIOD/3); MEM_READY = 0; // glitch
        #(4*CLK_PERIOD); MEM_READY = 1; #(CLK_PERIOD);
        REQ = 0; MEM_READY = 0;

        // Test 5: READ - back-to-back transactions (stress timing recovery)
        $display("\n-- Test 5: Back-to-back READs --");
        do_transaction(0, 4*CLK_PERIOD, 3*CLK_PERIOD);
        #(2*CLK_PERIOD);
        do_transaction(0, 1*CLK_PERIOD, 3*CLK_PERIOD);

        // Done
        #(10*CLK_PERIOD);
        $display("\n=== Simulation Complete ===\n");
        $finish;
    end

    //----------------------------------------------------------------------
    // Continuous monitoring for timing analysis
    //----------------------------------------------------------------------
    initial begin
        $display("  TIME | REQ RW MEM_READY || Moore: MEM_EN DATA_EN DONE || Mealy: MEM_EN DATA_EN DONE");
        $display("---------------------------------------------------------------------------------------");
        $monitor("%6t |  %b   %b     %b     ||   %b      %b      %b   ||   %b      %b      %b",
                 $time, REQ, RW, MEM_READY,
                 MEM_EN_moore, DATA_EN_moore, DONE_moore,
                 MEM_EN_mealy, DATA_EN_mealy, DONE_mealy);
    end

endmodule
