`timescale 1 ns / 100 ps

module testbench;

parameter Tt = 10;
parameter CLK_HZ = 100_000_000;
parameter BIT_RATE = 256000;
parameter PAYLOAD_BITS = 8;

localparam BIT_P = 1_000_000_000 * 1/BIT_RATE;
localparam CLK_P = 1_000_000_000 * 1/CLK_HZ;
localparam CYCLES_PER_BIT = BIT_P/CLK_P;

logic clk;
logic rst_n;
logic [2:0] LED;
logic rx;
logic [7:0] command [3:0];
integer i = 0;

Top #(.BIT_RATE(BIT_RATE), .PAYLOAD_BITS(PAYLOAD_BITS), .CLK_HZ(CLK_HZ)) top
(
	.clk(clk),
	.rst_n(rst_n),
	.LED(LED),
	.rx(rx)
);

initial begin
	clk = 0;
	forever clk = #(Tt/2) ~clk;
end

initial begin
	rst_n = 0;
	rx = 1;
	command[0] = 8'b01011111;
	command[1] = 8'b00101010;
	command[2] = 8'b01000010;
	command[3] = 8'b01111010;
	repeat(4) @(posedge clk);
	rst_n = 1;
	repeat(4) @(posedge clk);
	
	repeat(4) begin
		rx = 0;
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][0];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][1];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][2];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][3];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][4];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][5];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][6];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = command[i][7];
		repeat(CYCLES_PER_BIT) @(posedge clk);
		rx = 1;
		i++;
		repeat(1000) @(posedge clk);
	end
end

endmodule
