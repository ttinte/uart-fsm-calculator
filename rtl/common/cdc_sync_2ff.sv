//-----------------------------------------------------------------------------
//  Module   : cdc_sync_2ff.sv
//  Children : None
//
//  Description:
//     Two-flop synchronizer for a single asynchronous input.
//
//-----------------------------------------------------------------------------

module cdc_sync_2ff (
    input  logic clk,
    input  logic rst,
    input  logic async_in,
    output logic sync_out
);

    (* ASYNC_REG = "TRUE" *) logic sync_ff1, sync_ff2;

    always_ff @(posedge clk) begin
        if (rst) begin
            sync_ff1 <= '0;
            sync_ff2 <= '0;
        end
        else begin
            sync_ff1 <= async_in;
            sync_ff2 <= sync_ff1;
        end
    end

    assign sync_out = sync_ff2;

endmodule