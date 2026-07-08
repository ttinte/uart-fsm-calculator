//-----------------------------------------------------------------------------
//  Module   : uart_tx_core.sv
//  Children : None
//
//  Description:
//     UART TX FSM with 16x baud timing, start bit, 8 data bits, and stop bit.
//
//-----------------------------------------------------------------------------

module uart_tx_core (
    input  logic        clk,
    input  logic        rst,

    input  logic        baud_x16_en,

    input  logic [7:0]  tx_data,
    input  logic        tx_data_valid,

    output logic        tx_data_ready,
    output logic        txd
);

    localparam logic [3:0] FULL_BIT_TICKS = 4'd15;

    // FSM states
    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state, next_state;

    logic [3:0] tick;
    logic [2:0] nbits;
    logic [7:0] tx_data_reg;

    // FSM Next-state logic
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (tx_data_valid) begin
                    next_state = START;
                end
            end

            START: begin
                if (baud_x16_en && tick == FULL_BIT_TICKS) begin
                    next_state = DATA;
                end
            end

            DATA: begin
                if (baud_x16_en && tick == FULL_BIT_TICKS && nbits == 3'd7) begin
                    next_state = STOP;
                end
            end

            STOP: begin
                if (baud_x16_en && tick == FULL_BIT_TICKS) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // FSM state ffs
    always_ff @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            tick    <= '0;
            nbits   <= '0;
            txd     <= 1'b1;
        end
        else begin
            state <= next_state;
            if (baud_x16_en) tx_data_ready <= 1'b0;
            
            if (state == IDLE && next_state == START) begin
                tx_data_reg <= tx_data;
            end

            case (state)
                IDLE: begin
                    txd  <= 1'b1;
                    tx_data_ready <= 1'b1;
                    tick <= '0;
                end

                START: begin
                    if (baud_x16_en) begin
                        txd  <= 1'b0;

                        tick <= tick + 4'd1;
                        if (tick == FULL_BIT_TICKS) begin
                            tick        <= '0;
                            nbits       <= '0;
                        end
                    end
                end

                DATA: begin
                    if (baud_x16_en) begin
                        txd <= tx_data_reg[nbits];

                        tick <= tick + 4'd1;
                        if (tick == FULL_BIT_TICKS) begin
                            tick <= '0;
                            nbits <= nbits + 3'd1;
                        end
                    end
                end

                STOP: begin
                    if (baud_x16_en) begin
                        txd <= 1'b1;

                        tick <= tick + 4'd1;
                        if (tick == FULL_BIT_TICKS) begin
                            tick <= '0;
                            tx_data_ready <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
