`timescale 1ns/1ps
module tb_spi_master_mode0;
    reg clk;
    reg rst;
    reg start;
    reg  [7:0] data_in;
    wire miso;
    wire [7:0] data_out;
    wire sclk;
    wire mosi;
    wire cs;
    wire done;
    spi_master_mode0 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .miso(miso),
        .data_out(data_out),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .done(done)
    );
    always #5 clk = ~clk;
    // Simple SPI Slave Behavioral Model (Mode 0: CPOL=0, CPHA=0)
reg [7:0] slave_tx_reg = 8'hA5; // Data slave will send back to master
reg [7:0] slave_rx_reg = 8'h00; // Buffer for data received from master
reg [2:0] slave_bit_cnt = 3'd7;

    assign miso = (~cs) ? slave_tx_reg[slave_bit_cnt] : 1'bz;

    // Slave receiver/shifter logic
    always @(posedge sclk or posedge cs) begin
        if (cs) begin
            slave_bit_cnt <= 3'd7;
        end else begin
            slave_rx_reg[slave_bit_cnt] <= mosi;
        end
    end
      always @(negedge sclk) begin
        if (!cs) begin
            // Prepare next MISO bit on SCLK falling edge
            if (slave_bit_cnt > 0)
                slave_bit_cnt <= slave_bit_cnt - 1'b1;
        end
    end
// Stimulus & Verification Sequence
    initial begin
        clk     = 0;
        rst     = 1;
        start   = 0;
        data_in = 8'h00;
      
        #20;
        rst = 0;
        #20;

        // --- TEST CASE 1: Transmit 8'hC3, Expect Slave to Return 8'hA5 ---
        $display("[%0ntns] TEST 1: Sending 0xC3 (Master) | Expected Slave Return: 0xA5", $time);
        
        data_in = 8'hC3;
        start   = 1;
        #10;
        start   = 0; 

        // Wait for transmission complete flag
        wait(done == 1'b1);
        #10;
      
        if (data_out === 8'hA5 && slave_rx_reg === 8'hC3) begin
            $display("[%0ntns] SUCCESS: Master received 0x%0H, Slave received 0x%0H", $time, data_out, slave_rx_reg);
        end else begin
            $display("[%0ntns] ERROR: Master received 0x%0H (Expected 0xA5), Slave received 0x%0H (Expected 0xC3)", 
                     $time, data_out, slave_rx_reg);
        end
       #50;

        // --- TEST CASE 2: Transmit 8'h3C with new Slave Data 8'h5A ---
        slave_tx_reg = 8'h5A;
        data_in      = 8'h3C;
        
        $display("[%0ntns] TEST 2: Sending 0x3C (Master) | Expected Slave Return: 0x5A", $time);
        start = 1;
        #10;
        start = 0;

        wait(done == 1'b1);
        #10;

        if (data_out === 8'h5A && slave_rx_reg === 8'h3C) begin
            $display("[%0ntns] SUCCESS: Master received 0x%0H, Slave received 0x%0H", $time, data_out, slave_rx_reg);
        end else begin
            $display("[%0ntns] ERROR: Master received 0x%0H (Expected 0x5A), Slave received 0x%0H (Expected 0x3C)", 
                     $time, data_out, slave_rx_reg);
        end

        #100;
        $display("Simulation Finished Successfully.");
        $finish;
    end
  
    initial begin
        $dumpfile("spi_master_tb.vcd");
        $dumpvars(0, tb_spi_master_mode0);
    end
endmodule
