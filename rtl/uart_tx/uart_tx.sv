//-----------------------------------------------------------------------------
//  Project  : UART Transmitter
//  Module   : uart_tx
//  Children : baud_gen, uart_tx_core
//
//  Description:
//     Top-level UART TX wrapper with baud generator and TX core.
//
//-----------------------------------------------------------------------------

module uart_tx #(
    parameter int CLOCK_RATE = 100_000_000,
    parameter int BAUD_RATE  = 115_200
)(
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  tx_data,
    input  logic        tx_data_valid,
    output logic        tx_data_ready,
    output logic        txd
);

    logic baud_x16_en;

    baud_gen #(
        .CLOCK_RATE (CLOCK_RATE),
        .BAUD_RATE  (BAUD_RATE)
    ) baud_gen_i0 (
        .clk            (clk),
        .rst            (rst),
        .baud_x16_en    (baud_x16_en)
    );

    uart_tx_core uart_tx_core_i0 (
        .clk            (clk),
        .rst            (rst),
        .baud_x16_en    (baud_x16_en),
        .tx_data        (tx_data),
        .tx_data_valid  (tx_data_valid),
        .tx_data_ready  (tx_data_ready),
        .txd            (txd)
    );

endmodule
