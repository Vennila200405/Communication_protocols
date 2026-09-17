`timescale 1ns/1ps
module spi_master_mode0 (
    input clk, rst, start,
    input [7:0] data_in,
    input miso,
    output reg [7:0] data_out,
    output reg sclk, mosi, cs, done
);

parameter IDLE     = 2'b00,
          LOAD     = 2'b01,
          TRANSFER = 2'b10,
          DONE     = 2'b11;

reg [1:0] state;
reg [2:0] bit_cnt;
reg [7:0] shift_reg, recv_reg;
reg clk_div;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        cs <= 1'b1;
        done <= 1'b0;
        mosi <= 1'b0;
        sclk <= 1'b0;
        clk_div <= 1'b0;
        data_out <= 8'h00;
        bit_cnt <= 3'd7;
        shift_reg <= 8'h00;
        recv_reg <= 8'h00;
    end else begin
        case (state)

            IDLE: begin
                cs <= 1'b1;
                done <= 1'b0;
                sclk <= 1'b0;
                sclk <= 1'b0;
                clk_div <= 1'b0;

                if (start) begin
                    state <= LOAD;
                end
            end

            LOAD: begin
                cs <= 1'b0;
                shift_reg <= data_in;
                bit_cnt <= 3'd7;
                mosi <= data_in[7]; 
                sclk <= 1'b0;
                clk_div <= 1'b0;
                state <= TRANSFER;
            end

            TRANSFER: begin
                clk_div <= ~clk_div;

              if (clk_div == 0) begin
                    sclk <= 1'b1;
                    recv_reg[bit_cnt] <= miso;
                end else begin
                    sclk <= 1'b0;

                    if (bit_cnt == 0) begin
                        state <= DONE;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                        mosi <= shift_reg[bit_cnt - 1'b1]; 
                    end
                end
            end

            DONE: begin
                cs <= 1'b1;
                sclk <= 1'b0;
                mosi <= 1'b0;
                data_out <= recv_reg;
                done <= 1'b1;
                state <= IDLE;
            end

            default: state <= IDLE;

        endcase
    end
end

endmodule
