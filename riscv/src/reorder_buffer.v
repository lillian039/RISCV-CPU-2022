module reorder_buffer(
    input wire clk_in,// system clock signal
    input wire rst_in,// reset signal
    input wire rdy_in,// ready signal, pause cpu when low
    input wire [31:0] instruction_in,
    output wire [31:0] instruction_out
    output wire is_full_out
);
//ROB size 暂定32

reg [31:0] instruction[31:0];//存入指令
reg [3:0] entry[31:0];//rob 编号
reg ready[31:0];//whether ready?
reg[31:0] imme[31:0];//算出立即数
reg[31:0] pc_now[31:0];//pc指针（或许是32位的？）
reg[31:0] pc_des[31:0];//pc指针（或许是32位的？）
reg is_full;
reg flag_is_empty_place;
integer  i;
  always @(posedge clk_in) begin
    if(rst_in)begin//清空rob

    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin loop1
        for(int i=0;i<32;i=i+1)begin
        if(ready==1'b1)begin
        instruction[i]=instruction_in[i];//存入空的rob
        disable loop1;
        end
        end
    end
    assign is_full_out=is_full;

  end
endmodule
