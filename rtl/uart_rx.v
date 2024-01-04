module uart_rx(
    input clk,
    input rst_n,
    input uart_rxd,
    input uart_rx_en,
    output uart_rx_break,
    output  uart_rx_valid,
    output reg [PAYLOAD_BITS-1:0] uart_rx_data
);

parameter BIT_RATE = 9600; // Входная скорость передачи данных
localparam BIT_P = 1_000_000_000 * 1/BIT_RATE; // Период

parameter CLK_HZ = 50_000_000; // Тактовая частота
localparam CLK_P = 1_000_000_000 * 1/CLK_HZ; // Период тактовой частоты

parameter PAYLOAD_BITS = 8; // Количество бит данных
parameter STOP_BITS = 1; // Количество стоп-бит

localparam CYCLES_PER_BIT = BIT_P / CLK_P; // Количество тактов на бит UART
localparam COUNT_REG_LEN = 1 + $clog2(CYCLES_PER_BIT); // Размер регистра для хранения длительности битов

reg rxd_reg; // Регистр принимаемых бит
reg rxd_reg_0; // Дополнительный регистр
reg [PAYLOAD_BITS-1:0] recieved_data; // Регистр для полученных данных
reg [COUNT_REG_LEN-1:0] cycle_counter; // Счетчик количества тактов бита данных
reg [3:0] bit_counter; // Счетчик количества принятых бит
reg bit_sample; // Регистр для выборки в середине бита
reg [2:0] fsm_state; // Текущее состояние конечного автомата
reg [2:0] n_fsm_state; // Следубщее состояние конечного автомата

localparam FSM_IDLE = 0;
localparam FSM_START= 1;
localparam FSM_RECV = 2;
localparam FSM_STOP = 3;

//-----------------------------------------------------------------------
// Присвоение выходных значений

assign uart_rx_break = uart_rx_valid && ~|recieved_data;
assign uart_rx_valid = fsm_state == FSM_STOP && n_fsm_state == FSM_IDLE; // Данные получены

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        uart_rx_data  <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_STOP) begin
        uart_rx_data  <= recieved_data; // Полученные данные заносятся в выходной регистр
    end
end

//-----------------------------------------------------------------------
// Выбор следующего состояния конечного автомата

wire next_bit = cycle_counter == CYCLES_PER_BIT ||
                        fsm_state == FSM_STOP && 
                        cycle_counter == CYCLES_PER_BIT/2; // Получение следующего бита
wire payload_done = bit_counter == PAYLOAD_BITS; // Получение завершено

// Логика перехода между состояниями
always @(*) begin : p_n_fsm_state
    case(fsm_state)
        FSM_IDLE : n_fsm_state = rxd_reg ? FSM_IDLE : FSM_START;
        FSM_START: n_fsm_state = next_bit ? FSM_RECV : FSM_START;
        FSM_RECV : n_fsm_state = payload_done ? FSM_STOP : FSM_RECV ;
        FSM_STOP : n_fsm_state = next_bit ? FSM_IDLE : FSM_STOP ;
        default  : n_fsm_state = FSM_IDLE;
    endcase
end

// Обновление recieved_data
integer i = 0;
always @(posedge clk, negedge rst_n) begin : p_recieved_data
    if(!rst_n) begin
        recieved_data <= {PAYLOAD_BITS{1'b0}};
    end else if(fsm_state == FSM_IDLE) begin
        recieved_data <= {PAYLOAD_BITS{1'b0}};
    end else if(fsm_state == FSM_RECV && next_bit) begin
        recieved_data[PAYLOAD_BITS-1] <= bit_sample; // Новый полученный бит встает на позицию MSB
        for (i = PAYLOAD_BITS-2; i >= 0; i = i - 1) begin // Остальные биты сдвигаются вправо
            recieved_data[i] <= recieved_data[i+1];
        end
    end
end

// Увеличение счетчика бит при приеме нового бита
always @(posedge clk, negedge rst_n) begin : p_bit_counter
    if(!rst_n) begin
        bit_counter <= 4'b0;
    end else if(fsm_state != FSM_RECV) begin
        bit_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(fsm_state == FSM_RECV && next_bit) begin
        bit_counter <= bit_counter + 1'b1;
    end
end

// Выборка принимаемого бита
always @(posedge clk, negedge rst_n) begin : p_bit_sample
    if(!rst_n) begin
        bit_sample <= 1'b0;
    end else if (cycle_counter == CYCLES_PER_BIT/2) begin // Выборка происходит в середине битового кадра
        bit_sample <= rxd_reg;
    end
end

// Увеличение счетчика количества тактов
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

// Переход на следующее состояние конечного автомата
always @(posedge clk, negedge rst_n) begin : p_fsm_state
    if(!rst_n) begin
        fsm_state <= FSM_IDLE;
    end else begin
        fsm_state <= n_fsm_state;
    end
end

// Обновление входного регистра принимаемых бит
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