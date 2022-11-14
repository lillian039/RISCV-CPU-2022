module instruction_queue(
    input   wire            clk_in,             // system clock signal
    input   wire            rst_in,             // reset signal
    input   wire            rdy_in,             // ready signal, pause cpu when low
    input   wire    [31:0]  instruction_in,     // 32 width instruction
    output  wire    [31:0]  instruction_out,
    output  wire            is_full,            // whether instrutcion queue is full
    output  wire            has_data            // whether instruction queue has data
);

reg [31:0]  instruction_ISQ [31:0]; //size 32
reg [4:0]   isq_head;               //q_head
reg [4:0]   isq_rear;               //q_rear
reg         icache_hit;

always @(posedge clk_in) begin
    if(rst_in)begin//清空isq

    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
       
    end

end

endmodule