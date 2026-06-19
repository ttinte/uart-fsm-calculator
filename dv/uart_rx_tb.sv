`timescale 1ns/1ps

module uart_rx_tb;

    localparam int CLOCK_RATE = 100_000_000;
    localparam int BAUD_RATE  = 115_200;

    localparam time CLK_PERIOD = 10ns;
    localparam time BIT_PERIOD = 1s / BAUD_RATE;

    logic clk;
    logic rst;
    logic i_rxd_async;

    logic [7:0] o_rx_data;
    logic o_rx_data_valid;
    logic o_frame_err;

    // =========================================================
    // DUT
    // =========================================================
    uart_rx #(
        .CLOCK_RATE (CLOCK_RATE),
        .BAUD_RATE  (BAUD_RATE)
    ) dut (
        .clk            (clk),
        .rst            (rst),
        .rxd_async      (i_rxd_async),
        .rx_data        (o_rx_data),
        .rx_data_valid  (o_rx_data_valid),
        .frame_err      (o_frame_err)
    );

    // =========================================================
    // Clock Generation & Reset Task
    // =========================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    task automatic apply_reset();
        rst         = 1'b1;
        i_rxd_async = 1'b1;
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);
    endtask

    // =========================================================
    // UART Driver Task
    // =========================================================
    task automatic uart_send_byte(input logic [7:0] data);
        int i;
        i_rxd_async = 1'b0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i++) begin
            i_rxd_async = data[i];
            #(BIT_PERIOD);
        end
        i_rxd_async = 1'b1;
        #(BIT_PERIOD);
    endtask

    // =========================================================
    // UART Driver Task (framing error: stop bit = 0)
    // =========================================================
    task automatic uart_send_byte_bad_stop(input logic [7:0] data);
        int i;
        i_rxd_async = 1'b0;
        #(BIT_PERIOD);
        for (i = 0; i < 8; i++) begin
            i_rxd_async = data[i];
            #(BIT_PERIOD);
        end
        i_rxd_async = 1'b0;   // stop bit = 0 (framing error)
        #(BIT_PERIOD);

        i_rxd_async = 1'b1;   // restore line to idle
        #(BIT_PERIOD);
    endtask

    // =========================================================
    // UART Checker Task
    // Wait for rx_data_valid with timeout 
    // Check data matches expected, verify 1-cycle pulse.
    // =========================================================
    task automatic expect_byte(input logic [7:0] expected, input string tag);
        logic [7:0] received;
        bit         valid_seen, err_seen;

        valid_seen = 0;
        err_seen = 0;
        received   = '0;

        fork
            begin
                @(posedge clk iff o_rx_data_valid);
                #1step;
                received   = o_rx_data;
                valid_seen = 1;
                @(posedge clk);
                #1step;
                if (o_rx_data_valid)
                    $error("[%0t] FAIL %s: rx_data_valid held >1 cycle for 0x%02h",
                           $time, tag, expected);
            end
            begin
                @(posedge clk iff o_frame_err);
                #1step;
                err_seen = 1;
            end
            #(BIT_PERIOD * 12);
        join_any
        disable fork;

        if (err_seen)
            $error("[%0t] FAIL %s: unexpected frame_err for 0x%02h",
                   $time, tag, expected);
        else if (!valid_seen)
            $error("[%0t] TIMEOUT %s: no rx_data_valid for expected = 0x%02h",
                   $time, tag, expected);
        else if (received !== expected)
            $error("[%0t] FAIL %s: expected = 0x%02h, received = 0x%02h",
                   $time, tag, expected, received);
        else
            $display("[%0t] PASS %s: received = 0x%02h", $time, tag, received);
    endtask

    // =========================================================
    // Single byte Test Task
    // =========================================================
    task automatic test_single_byte(input logic [7:0] expected);
        fork
            uart_send_byte(expected);
            expect_byte(expected, "");
        join
    endtask

    // =========================================================
    // Back-To-Back Test Task
    // =========================================================
    task automatic test_back_to_back(input logic [7:0] byte1, byte2);
        fork
            begin
                uart_send_byte(byte1);
                uart_send_byte(byte2);
            end
            begin
                expect_byte(byte1, "b2b");
                expect_byte(byte2, "b2b");
            end
        join
    endtask

    // =========================================================
    // Frame Error Test Task
    // =========================================================
    task automatic test_frame_err(input logic [7:0] data);
        bit err_seen, valid_seen;

        err_seen   = 0;
        valid_seen = 0;

        fork
            uart_send_byte_bad_stop(data);
            begin
                fork
                    begin
                        @(posedge clk iff o_frame_err);
                        err_seen   = o_frame_err;
                        @(posedge clk);
                        #1step;
                        if (o_frame_err)
                            $error("[%0t] FAIL frame_err: o_frame_err held >1 cycle", $time);
                    end
                    begin
                        @(posedge clk iff o_rx_data_valid);
                        valid_seen = 1;
                    end
                    #(BIT_PERIOD * 12);
                join_any
                disable fork;
            end
        join

        if (valid_seen && !err_seen)
            $error("[%0t] FAIL frame_err: valid fired instead of frame_err", $time);
        else if (valid_seen && err_seen)
            $error("[%0t] FAIL frame_err: valid fired with frame_err", $time);
        else if (!err_seen)
            $error("[%0t] TIMEOUT frame_err: no frame_err", $time);
        else
            $display("[%0t] PASS frame_err: valid suppressed", $time);

    endtask

    // =========================================================
    // Glitch Rejection Test Task
    // =========================================================
    task automatic test_glitch_rejection();
        bit false_event;
        false_event = 0;
        fork
            begin
                i_rxd_async = 1'b0;
                #(CLK_PERIOD * 0.5);
                i_rxd_async = 1'b1;
            end
            begin
                fork
                    begin
                        forever begin
                        @(posedge clk iff (o_rx_data_valid || o_frame_err));
                        #1step;
                        false_event = 1;
                        end
                    end
                    #(BIT_PERIOD * 12);
                join_any
                disable fork;
            end
        join

        if (false_event)
            $error("[%0t] FAIL glitch: false event", $time);
        else
            $display("[%0t] PASS glitch: no false event", $time);
    endtask

    // =========================================================
    // Main Test Sequence
    // =========================================================
    initial begin
        $display("========================================");
        $display(" UART RX TESTBENCH ");
        $display(" CLOCK_RATE = %0d Hz", CLOCK_RATE);
        $display(" BAUD_RATE  = %0d", BAUD_RATE);
        $display(" BIT_PERIOD = %0t", BIT_PERIOD);
        $display("========================================");

        apply_reset();

        #(BIT_PERIOD/3);
        test_single_byte(8'h00);
        test_single_byte(8'hFF);
        test_single_byte(8'hA5);
        test_single_byte(8'h5A);
        test_single_byte(8'h01);
        test_single_byte(8'h80);
        test_single_byte(8'h0D);    // CR

        test_back_to_back(8'h55, 8'hAA);

        #(BIT_PERIOD);
        test_frame_err(8'h41);
        
        #(BIT_PERIOD*3);
        test_glitch_rejection();

        repeat (10) @(posedge clk);

        $display("========================================");
        $display(" UART RX TESTBENCH DONE");
        $display("========================================");

        $finish;
    end

endmodule