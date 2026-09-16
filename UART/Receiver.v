module uart_rx(

    input PCLK,
    input PRESETn,
    input baud_tick,
    input rx,

    output reg [7:0] data_out,
    output reg data_valid,
    output reg parity_error,
    output reg busy
);

localparam IDLE    = 3'd0,
           START   = 3'd1,
           DATA    = 3'd2,
           PARITY  = 3'd3,
           STOP    = 3'd4,
           DONE    = 3'd5;

reg [2:0] current_state;
reg [2:0] next_state;

reg [7:0] shift_reg;
reg [2:0] bit_count;
reg       received_parity;

always @(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*)
begin

    next_state = current_state;

    case(current_state)

        IDLE:
        begin
            if(rx == 1'b0)
                next_state = START;
        end

        START:
        begin
            if(baud_tick)
                next_state = DATA;
        end

        DATA:
        begin
            if(baud_tick)
            begin
                if(bit_count == 3'd7)
                    next_state = PARITY;
            end
        end

        PARITY:
        begin
            if(baud_tick)
                next_state = STOP;
        end

        STOP:
        begin
            if(baud_tick)
                next_state = DONE;
        end

        DONE:
            next_state = IDLE;

        default:
            next_state = IDLE;

    endcase

end

always @(posedge PCLK or negedge PRESETn)
begin

    if(!PRESETn)
    begin
        shift_reg       <= 8'd0;
        bit_count       <= 3'd0;
        received_parity <= 1'b0;
        data_out        <= 8'd0;
        parity_error    <= 1'b0;
    end

    else
    begin

        case(current_state)

            IDLE:
            begin
                bit_count <= 3'd0;
            end

            DATA:
            begin
                if(baud_tick)
                begin
                
                    shift_reg <= {rx, shift_reg[7:1]};

                    if(bit_count != 3'd7)
                        bit_count <= bit_count + 1'b1;
                end
            end

            PARITY:
            begin
                if(baud_tick)
                begin
                    received_parity <= rx;

              
                    if(rx != (^shift_reg))
                        parity_error <= 1'b1;
                    else
                        parity_error <= 1'b0;
                end
            end

            STOP:
            begin
                if(baud_tick)
                begin
                    if(rx == 1'b1 && !parity_error)
                        data_out <= shift_reg;
                end
            end

            default:
            begin
            end

        endcase

    end

end

always @(*)
begin

    busy       = 1'b0;
    data_valid = 1'b0;

    case(current_state)

        IDLE:
        begin
            busy = 1'b0;
        end

        START:
        begin
            busy = 1'b1;
        end

        DATA:
        begin
            busy = 1'b1;
        end

        PARITY:
        begin
            busy = 1'b1;
        end

        STOP:
        begin
            busy = 1'b1;
        end

        DONE:
        begin
            busy = 1'b0;

            if(!parity_error)
                data_valid = 1'b1;
            else
                data_valid = 1'b0;
        end

    endcase
end

endmodule
