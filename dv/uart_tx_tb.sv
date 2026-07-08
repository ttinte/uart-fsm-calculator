`timescale 1ns/1ps

module uart_tx_tb;

    localparam int CLOCK_RATE = 100_000_000;
    localparam int BAUD_RATE  = 115_200;

    localparam time CLK_PERIOD = 10ns;
    localparam time BIT_PERIOD = 1s / BAUD_RATE;

    logic clk;
    logic rst;
    logic [7:0] i_tx_data;
    logic i_tx_data_valid;
    logic i_tx_data_ready;
    logic o_txd;

    // =========================================================
    // DUT
    // =========================================================
    uart_tx #(
        .CLOCK_RATE (CLOCK_RATE),
        .BAUD_RATE  (BAUD_RATE)
    ) dut (
        .clk            (clk),
        .rst            (rst),
        .tx_data        (i_tx_data),
        .tx_data_valid  (i_tx_data_valid),
        .tx_data_ready  (i_tx_data_ready),
        .txd            (o_txd)
    );

    // =========================================================
    // Clock Generation & Reset Task
    // =========================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    task automatic apply_reset();
        rst             = 1'b1;
        i_tx_data       = '0;
        i_tx_data_valid = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);
    endtask

    // =========================================================
    // UART Checker Task
    // =========================================================
    task automatic expect_byte(input logic [7:0] expected, input string tag);
        int i;
        bit err_seen = 0;
        bit start_seen = 0;
        bit timeout_seen = 0;

        fork
            begin
                @(negedge o_txd);
                start_seen = 1;
            end
            begin
                #(BIT_PERIOD*12);
                timeout_seen = 1;
            end
        join_any
        disable fork;

        if (timeout_seen && !start_seen) begin
            $error("[%0t] TIMEOUT %s: no start bit for 0x%02h",
                $time, tag, expected);
            return;
        end

        #(BIT_PERIOD/2);
        if (o_txd !== 1'b0) begin
            $error("[%0t] FAIL %s: bad start bit", $time, tag);
            err_seen = 1;
        end

        for (i = 0; i < 8; i++) begin
            #(BIT_PERIOD);
            if (o_txd !== expected[i]) begin
                $error("[%0t] FAIL %s: Bad data bit %0d: expected %0b got %0b",
                        $time, tag, i, expected[i], o_txd);
                err_seen = 1;
            end
        end

        #(BIT_PERIOD);
        if (o_txd !== 1'b1) begin
            $error("[%0t] FAIL %s: Bad stop bit", $time, tag);
            err_seen = 1;
        end

        if (!err_seen) $display("[%0t] PASS %s: 0x%02h", $time, tag, expected);

    endtask

    // =========================================================
    // Single byte Test Task
    // =========================================================
    task automatic test_single_byte(input logic [7:0] expected);
        fork
            begin
                i_tx_data = expected;
                i_tx_data_valid = 1'b1;
                #(BIT_PERIOD);
                i_tx_data_valid = 1'b0;
            end
            expect_byte(expected, "");
        join
    endtask

    // =========================================================
    // Back-To-Back Test Task
    // =========================================================
    task automatic test_back_to_back(input logic [7:0] byte1, byte2);
        fork
            begin
                i_tx_data = byte1;
                i_tx_data_valid = 1'b1;
                #(BIT_PERIOD*2);
                i_tx_data = byte2;

                #(BIT_PERIOD*10);
                i_tx_data_valid = 1'b0;
            end
            begin
                expect_byte(byte1, "b2b");
                expect_byte(byte2, "b2b");
            end
        join
    endtask


    // =========================================================
    // Main Test Sequence
    // =========================================================
    initial begin
        $display("========================================");
        $display(" UART TX TESTBENCH ");
        $display(" CLOCK_RATE = %0d Hz", CLOCK_RATE);
        $display(" BAUD_RATE  = %0d", BAUD_RATE);
        $display(" BIT_PERIOD = %0t", BIT_PERIOD);
        $display("========================================");

        apply_reset();

        test_single_byte(8'h00);
        test_single_byte(8'hFF);
        test_single_byte(8'hA5);
        test_single_byte(8'h5A);
        test_single_byte(8'h01);
        test_single_byte(8'h80);
        test_single_byte(8'h0D);    // CR

        test_back_to_back(8'h55, 8'hAA);


        $display("========================================");
        $display(" UART TX TESTBENCH DONE");
        $display("========================================");

        $finish;
    end

endmodule
