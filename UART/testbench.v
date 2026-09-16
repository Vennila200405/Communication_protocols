`timescale 1ns/1ps

module uart_tb;

reg PCLK;
reg PRESETn;
reg baud_tick;
reg tx_start;
reg  [7:0]  tx_data;

wire tx;
wire busy_tx;
wire tx_done;

wire [7:0] data_out;
wire       data_valid;
wire       parity_error;
wire       busy_rx;

uart_tx DUT_TX
(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .baud_tick(baud_tick),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .busy(busy_tx),
    .tx_done(tx_done)
);

uart_rx DUT_RX
(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .baud_tick(baud_tick),
    .rx(tx),

    .data_out(data_out),
    .data_valid(data_valid),
    .parity_error(parity_error),
    .busy(busy_rx)
);

initial
begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
end

integer count;

always @(posedge PCLK)
begin
    if(!PRESETn)
    begin
        count <= 0;
        baud_tick <= 0;
    end
    else
    begin
        if(count == 15)
        begin
            baud_tick <= 1;
            count <= 0;
        end
        else
        begin
            baud_tick <= 0;
            count <= count + 1;
        end
    end
end

task send_byte;

input [7:0] data;

begin

    @(posedge PCLK);

    while(busy_tx)
        @(posedge PCLK);

    tx_data   = data;
    tx_start  = 1'b1;

    @(posedge PCLK);
    tx_start = 1'b0;

    wait(tx_done);

    @(posedge PCLK);

end

endtask

initial
begin

    PRESETn   = 0;
    tx_start  = 0;
    tx_data   = 8'h00;

    #100;

    PRESETn = 1;

    #50;

    send_byte(8'h55);

    #500;

    send_byte(8'hA3);

    #500;

    send_byte(8'hF0);

    #500;

    send_byte(8'h3C);

    #1000;

    $finish;

end

initial
begin

    $display("-------------------------------------------------------------");
    $display("Time\tTX\tTX_DONE\tRX_BUSY\tVALID\tPARITY_ERR\tDATA");
    $display("-------------------------------------------------------------");

    $monitor("%0t\t%b\t%b\t%b\t%b\t%b\t\t%h",
              $time,
              tx,
              tx_done,
              busy_rx,
              data_valid,
              parity_error,
              data_out);

end

always @(posedge PCLK)
begin
    if(data_valid)
    begin
        $display("\nReceived Data = %h at time %0t\n",
                 data_out,
                 $time);
    end
end

endmodule
