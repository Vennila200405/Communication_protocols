`timescale 1ns/1ps

module apb_tb;

reg PCLK;
reg PRESETn;

reg transfer;
reg write_read;

reg [31:0] addr_in;
reg [31:0] data_in;

wire PSEL;
wire PENABLE;
wire PWRITE;

wire [31:0] PADDR;
wire [31:0] PWDATA;
wire [31:0] PRDATA;

wire PREADY;

wire [31:0] data_out;
wire ready_out;


apb_master master(

.PCLK(PCLK),
.PRESETn(PRESETn),

.transfer(transfer),
.write_read(write_read),

.addr_in(addr_in),
.data_in(data_in),

.PREADY(PREADY),
.PRDATA(PRDATA),

.PSEL(PSEL),
.PENABLE(PENABLE),
.PWRITE(PWRITE),

.PADDR(PADDR),
.PWDATA(PWDATA),

.data_out(data_out),
.ready_out(ready_out)

);


apb_slave slave(

.PCLK(PCLK),
.PRESETn(PRESETn),

.PSEL(PSEL),
.PENABLE(PENABLE),
.PWRITE(PWRITE),

.PADDR(PADDR),
.PWDATA(PWDATA),

.PRDATA(PRDATA),
.PREADY(PREADY)

);


always #5 PCLK=~PCLK;


initial
begin

PCLK=0;

PRESETn=0;

transfer=0;

#20;

PRESETn=1;



// WRITE

@(posedge PCLK);

transfer=1;
write_read=1;
addr_in=32'h04;
data_in=32'h12345678;

wait(ready_out);

@(posedge PCLK);

transfer=0;


// READ

@(posedge PCLK);

transfer=1;
write_read=0;
addr_in=32'h04;

wait(ready_out);

$display("READ DATA = %h",data_out);

@(posedge PCLK);

transfer=0;

#50;

$finish;

end

endmodule
