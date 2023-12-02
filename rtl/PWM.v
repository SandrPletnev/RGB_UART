module PWM
(
	input clk,
	input rst_n,
	input [7:0] command,
	input rx_valid,
	output [2:0] LED
);

localparam IDLE = 0;
localparam COMMAND_DET = 1;

reg [4:0] cnt;
reg rx_valid_reg;
reg [1:0] cstate, nstate;
reg [2:0] color;
reg [3:0] brightness;

always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cstate <= IDLE;
	end
	else begin
		cstate <= nstate;
	end
end

always @ (*) begin
	nstate = cstate;
	case (cstate)
		IDLE : nstate = rx_valid_reg ? COMMAND_DET : IDLE;
		COMMAND_DET : nstate = IDLE;
		default : nstate = IDLE;
	endcase
end

always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		color <= 3'b0;
		brightness <= 4'b0;
		rx_valid_reg <= 1'b0;
	end
	else begin
		case (nstate)
			IDLE : begin
				color <= color;
				brightness <= brightness;
				rx_valid_reg <= rx_valid;
			end
			COMMAND_DET : begin
				color <= command[6:4];
				brightness <= command [3:0];
				rx_valid_reg <= 1'b0;
			end
			default : begin
				color <= color;
				brightness <= brightness;
				rx_valid_reg <= rx_valid;
			end
		endcase
	end
end

always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cnt <= 5'b0;
	end
	else if (cnt < 14) begin
		cnt <= cnt + 5'b1;
	end
	else begin
		cnt <= 5'b0;
	end
end

assign LED = (cnt < brightness) ? color : 3'b0;

endmodule