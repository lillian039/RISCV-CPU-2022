module instruction_queue(
    input   wire            clk_in,             // system clock signal
    input   wire            rst_in,             // reset signal
    input   wire            rdy_in,             // ready signal, pause cpu when low
    input   wire            instruction_ready,  //whether icache/mem get the instruction
    input   wire    [31:0]  instruction_in,     // 32 width instruction
    input   wire            rob_is_full,        //whether rob is full
    output  wire    [31:0]  instruction_out,
    output  wire            is_full,            // whether instrutcion queue is full
    output  wire            is_sending          // whether instruction queue is sending instrutcion
);

reg [31:0]  instruction_ISQ [31:0]; //size 32
reg [4:0]   isq_head;               //q_head 0-31
reg [4:0]   isq_rear;               //q_rear 0-31
reg         send_instruction;            
assign is_full = isq_head == isq_rear + 1;
assign instruction_out = instruction_ISQ[isq_head];//是上一个时钟周期的吗
assign is_sending = send_instruction;

always @(posedge clk_in) begin
    if(rst_in)begin//清空isq
    isq_head <= 0;
    isq_rear <= 0;
    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
        if(instruction_ready == TRUE)begin
        instruction_ISQ[isq_rear]<=instruction_in;
        isq_rear <= isq_rear + 1;
        end
        if(rob_is_full == FALSE && isq_head!=isq_rear)begin
        send_instruction <= TRUE;
        isq_head<=isq_head+1;//???不知道有没有问题
        end
        if(rob_is_full == TRUE || isq_head == isq_rear)begin
        send_instruction <= FALSE;
        end

    end

end
endmodule