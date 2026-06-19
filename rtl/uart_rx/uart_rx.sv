//-----------------------------------------------------------------------------
//  Project  : UART Receiver
//  Module   : uart_rx
//  Children : baud_gen, uart_rx_core
//
//  Description:
//     Top-level UART RX wrapper with input sync, baud generator, and RX core.
//
//-----------------------------------------------------------------------------

module uart_rx #(
    parameter int CLOCK_RATE = 100_000_000,
    parameter int BAUD_RATE  = 115_200
)(
    input  logic clk,
    input  logic rst,
    input  logic rxd_async,
    output logic [7:0] rx_data,
    output logic rx_data_valid,
    output logic frame_err
);

    logic baud_x16_en;
    logic rxd;

    cdc_sync_2ff rxd_sync_i0 (
        .clk            (clk),
        .rst            (rst),
        .async_in       (rxd_async),
        .sync_out       (rxd)
    );

    baud_gen #(
        .CLOCK_RATE (CLOCK_RATE),
        .BAUD_RATE  (BAUD_RATE)
    ) baud_gen_i0 (
        .clk            (clk),
        .rst            (rst),
        .baud_x16_en    (baud_x16_en)
    );

    uart_rx_core uart_rx_core_i0 (
        .clk            (clk),
        .rst            (rst),
        .baud_x16_en    (baud_x16_en),
        .rxd            (rxd),
        .rx_data        (rx_data),
        .rx_data_valid  (rx_data_valid),
        .frame_err      (frame_err)
    );

endmodule