module reorder_buffer(
    input   wire          clk_in,// system clock signal
    input   wire          rst_in,// reset signal
    input   wire          rdy_in,// ready signal, pause cpu when low
    input   wire          pc_now_in,
    input   wire  [31:0]  instruction_in,
    output  wire  [31:0]  instruction_out
    output  wire          is_full_out
);
//ROB size 暂定32

reg [31:0] rob_instruction[31:0];//存入指令
reg [3:0] rob_entry[31:0];//rob 编号
reg rob_ready[31:0];//whether ready?
reg[31:0] rob_imme[31:0];//算出立即数
reg[31:0] rob_pc_now[31:0];//pc指针（或许是32位的？）
reg[31:0] rob_pc_des[31:0];//pc指针（或许是32位的？）
reg rob_is_full;
reg[31:0] reorder_entry_now;//rob
reg [4:0]rob_head;//指向rob的头
reg[4:0]rob_rear;//指向rob的尾
integer  i;
  always @(posedge clk_in) begin
    if(rst_in)begin//清空rob

    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
        rob_is_full=(rob_rear+4'b0001==rob_head)?1'b1:1'b0;
        if(rob_is_full==FALSE)begin//rob未满
        rob_rear=rob_rear+1;
        rob_instruction[rob_rear]=instruction_in;//存入空的rob
        
        end
    end
    assign is_full_out=is_full;

  end
endmodule
