module UART
#(
	parameter CLK_HZ = 100_000_000,
	parameter BIT_RATE = 256000,
	parameter PAYLOAD_BITS = 8
)
(
	input clk,
	input rst_n,
	input uart_rxd,
	output [PAYLOAD_BITS - 1:0] command,
	output rx_valid
);

wire [PAYLOAD_BITS-1:0] uart_rx_data;
wire uart_rx_valid;
wire uart_rx_break;

reg  [PAYLOAD_BITS-1:0] command_reg;
assign command = command_reg;

assign rx_valid = uart_rx_valid; // Разрешающий сигнал

// Помещение полученных данных в регистр команды
always @ (posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        command_reg <= 8'hF0;
    end else if(uart_rx_valid) begin
        command_reg <= uart_rx_data[7:0];
    end
end

// Модуль приемника UART
uart_rx #(.BIT_RATE(BIT_RATE), .PAYLOAD_BITS(PAYLOAD_BITS), .CLK_HZ(CLK_HZ)) i_uart_rx
(
	.clk(clk),
	.rst_n(rst_n),
	.uart_rxd(uart_rxd),
	.uart_rx_en(1'b1),
	.uart_rx_break(uart_rx_break),
	.uart_rx_valid(uart_rx_valid),
	.uart_rx_data(uart_rx_data)
);

endmodule