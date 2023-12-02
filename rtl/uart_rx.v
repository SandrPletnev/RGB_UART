module uart_rx(
    input clk,
    input rst_n,
    input uart_rxd,
    input uart_rx_en,
    output uart_rx_break,
    output  uart_rx_valid,
    output reg [PAYLOAD_BITS-1:0] uart_rx_data
);

parameter   BIT_RATE = 9600;
localparam  BIT_P = 1_000_000_000 * 1/BIT_RATE;

parameter   CLK_HZ = 50_000_000;
localparam  CLK_P = 1_000_000_000 * 1/CLK_HZ; 

parameter   PAYLOAD_BITS    = 8;
parameter   STOP_BITS       = 1;

localparam CYCLES_PER_BIT = BIT_P / CLK_P;
localparam       COUNT_REG_LEN      = 1+$clog2(CYCLES_PER_BIT);

reg rxd_reg;
reg rxd_reg_0;
reg [PAYLOAD_BITS-1:0] recieved_data;
reg [COUNT_REG_LEN-1:0] cycle_counter;
reg [3:0] bit_counter;
reg bit_sample;
reg [2:0] fsm_state;
reg [2:0] n_fsm_state;

localparam FSM_IDLE = 0;
localparam FSM_START= 1;
localparam FSM_RECV = 2;
localparam FSM_STOP = 3;

assign uart_rx_break = uart_rx_valid && ~|recieved_data;
assign uart_rx_valid = fsm_state == FSM_STOP && n_fsm_state == FSM_IDLE;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        uart_rx_data  <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_STOP) begin
        uart_rx_data  <= recieved_data;
    end
end

wire next_bit = cycle_counter == CYCLES_PER_BIT ||
                        fsm_state == FSM_STOP && 
                        cycle_counter == CYCLES_PER_BIT/2;
wire payload_done = bit_counter == PAYLOAD_BITS  ;

always @(*) begin : p_n_fsm_state
    case(fsm_state)
        FSM_IDLE : n_fsm_state = rxd_reg ? FSM_IDLE : FSM_START;
        FSM_START: n_fsm_state = next_bit ? FSM_RECV : FSM_START;
        FSM_RECV : n_fsm_state = payload_done ? FSM_STOP : FSM_RECV ;
        FSM_STOP : n_fsm_state = next_bit ? FSM_IDLE : FSM_STOP ;
        default  : n_fsm_state = FSM_IDLE;
    endcase
end

integer i = 0;
always @(posedge clk, negedge rst_n) begin : p_recieved_data
    if(!rst_n) begin
        recieved_data <= {PAYLOAD_BITS{1'b0}};
    end else if(fsm_state == FSM_IDLE) begin
        recieved_data <= {PAYLOAD_BITS{1'b0}};
    end else if(fsm_state == FSM_RECV && next_bit) begin
        recieved_data[PAYLOAD_BITS-1] <= bit_sample;
        for ( i = PAYLOAD_BITS-2; i >= 0; i = i - 1) begin
            recieved_data[i] <= recieved_data[i+1];
        end
    end
end

always @(posedge clk, negedge rst_n) begin : p_bit_counter
    if(!rst_n) begin
        bit_counter <= 4'b0;
    end else if(fsm_state != FSM_RECV) begin
        bit_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(fsm_state == FSM_RECV && next_bit) begin
        bit_counter <= bit_counter + 1'b1;
    end
end

always @(posedge clk, negedge rst_n) begin : p_bit_sample
    if(!rst_n) begin
        bit_sample <= 1'b0;
    end else if (cycle_counter == CYCLES_PER_BIT/2) begin
        bit_sample <= rxd_reg;
    end
end

always @(posedge clk, negedge rst_n) begin : p_cycle_counter
    if(!rst_n) begin
        cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(next_bit) begin
        cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(fsm_state == FSM_START || 
                fsm_state == FSM_RECV || 
                fsm_state == FSM_STOP) begin
        cycle_counter <= cycle_counter + 1'b1;
    end
end

always @(posedge clk, negedge rst_n) begin : p_fsm_state
    if(!rst_n) begin
        fsm_state <= FSM_IDLE;
    end else begin
        fsm_state <= n_fsm_state;
    end
end

always @(posedge clk, negedge rst_n) begin : p_rxd_reg
    if(!rst_n) begin
        rxd_reg <= 1'b1;
        rxd_reg_0 <= 1'b1;
    end else if(uart_rx_en) begin
        rxd_reg <= rxd_reg_0;
        rxd_reg_0 <= uart_rxd;
    end
end


endmodule