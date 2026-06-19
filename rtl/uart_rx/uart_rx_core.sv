//-----------------------------------------------------------------------------
//  Module   : uart_rx_core.sv
//  Children : None
//
//  Description:
//     UART RX FSM with 16x oversampling, 8-bit data capture, and stop-bit check.
//
//-----------------------------------------------------------------------------

module uart_rx_core (
    input  logic        clk,
    input  logic        rst,

    input  logic        baud_x16_en,
    input  logic        rxd,

    output logic [7:0]  rx_data,
    output logic        rx_data_valid,
    output logic        frame_err
);

    localparam logic [3:0] HALF_BIT_TICKS = 4'd7;
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
    logic [7:0] shifter;

    // FSM Next-state logic
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (!rxd) begin
                    next_state = START;
                end
            end

            START: begin
                if (tick == HALF_BIT_TICKS) begin
                    if (rxd) begin        
                        next_state = IDLE;
                    end
                    else begin            
                        next_state = DATA;
                    end
                end
            end

            DATA:  begin
                if (tick == FULL_BIT_TICKS && nbits == 3'd7) begin   
                    next_state = STOP;
                end
            end

            STOP: begin
                if (tick == FULL_BIT_TICKS) begin    
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end 

    // FSM state ff
    always_ff @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            tick          <= '0;
            nbits         <= '0;
            shifter       <= '0;
            rx_data       <= '0;
            rx_data_valid <= 1'b0;
            frame_err     <= 1'b0;
        end
        else begin
            rx_data_valid <= 1'b0;
            frame_err     <= 1'b0;

            if (baud_x16_en) begin
                state <= next_state;

                case (state)
                    IDLE: begin
                        tick <= '0;
                    end

                    START: begin
                        tick <= tick + 4'd1;
                        if (tick == HALF_BIT_TICKS) begin
                            tick  <= '0;
                            nbits <= '0;
                        end
                    end

                    DATA: begin
                        tick <= tick + 4'd1;
                        if (tick == FULL_BIT_TICKS) begin
                            tick    <= '0;
                            shifter <= {rxd, shifter[7:1]};
                            nbits   <= nbits + 3'd1;
                        end
                    end

                    STOP: begin
                        tick <= tick + 4'd1;
                        if (tick == FULL_BIT_TICKS) begin
                            tick            <= '0;
                            rx_data         <= shifter;
                            rx_data_valid   <= rxd;
                            frame_err       <= !rxd;
                        end
                    end

                endcase
            end
        end
    end

endmodule