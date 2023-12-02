module Top
#(
	parameter CLK_HZ = 100_000_000,
	parameter BIT_RATE = 256000,
	parameter PAYLOAD_BITS = 8
)
(
	input clk,
	input rst_n,
	input rx,
	output [2:0] LED
);

wire [7:0] rx_command;
wire valid;

UART #(.BIT_RATE(BIT_RATE), .PAYLOAD_BITS(PAYLOAD_BITS), .CLK_HZ(CLK_HZ)) UART_top
(
	.clk(clk),
	.rst_n(rst_n),
	.uart_rxd(rx),
	.command(rx_command),
	.rx_valid(valid)
);

PWM pwm
(
	.clk(clk),
	.rst_n(rst_n),
	.command(rx_command),
	.rx_valid(valid),
	.LED(LED)
);

endmodule