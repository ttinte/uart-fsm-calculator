//-----------------------------------------------------------------------------
//  Module   : sync_fifo_buffer.sv
//  Children : None
//
//  Description:
//     Read-side adapter for a standard synchronous FIFO.
//
//-----------------------------------------------------------------------------

module sync_fifo_buffer #(
    parameter int WIDTH = 8
)(
    input  logic             clk,
    input  logic             rst,

    output logic             fifo_rd_en,
    input  logic [WIDTH-1:0] fifo_dout,
    input  logic             fifo_empty,

    input  logic             data_ready,
    output logic [WIDTH-1:0] data,
    output logic             data_valid
);

    logic take_data;
    logic load_pending;
    logic start_load;

    assign take_data  = data_valid && data_ready;
    assign start_load = !fifo_empty && !load_pending && (!data_valid || take_data);
    

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_rd_en   <= 1'b0;
            load_pending <= 1'b0;
            data         <= '0;
            data_valid   <= 1'b0;
        end
        else begin
            fifo_rd_en <= 1'b0;

            if (take_data) begin
                data_valid <= 1'b0;
            end

            if (load_pending) begin
                data         <= fifo_dout;
                data_valid   <= 1'b1;
                load_pending <= 1'b0;
            end

            if (start_load) begin
                fifo_rd_en   <= 1'b1;
                load_pending <= 1'b1;
            end
        end
    end

endmodule
