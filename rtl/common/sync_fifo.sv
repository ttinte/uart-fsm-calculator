//-----------------------------------------------------------------------------
//  Module   : sync_fifo.sv
//  Children : None
//
//  Description:
//     Standard synchronous FIFO with registered read data.
//
//-----------------------------------------------------------------------------

module sync_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16
)(
    input  logic             clk,
    input  logic             rst,

    input  logic             wr_en,
    input  logic [WIDTH-1:0] din,

    input  logic             rd_en,
    output logic [WIDTH-1:0] dout,

    output logic             full,
    output logic             empty
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;

    logic [$clog2(DEPTH+1)-1:0] count;

    assign full  = (count == DEPTH);
    assign empty = (count == '0);


    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            dout    <= '0;
        end
        else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
                
                if (rd_en && !empty)
                    count <= count;
                else
                    count <= count + 1'b1;
            end

            if (rd_en && !empty) begin
                dout    <= mem[rd_ptr];
                
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

                if (wr_en && !full)
                    count <= count;
                else
                    count <= count - 1'b1;
            end
        end
    end

endmodule
