module reorder_buffer(
    input   wire                clk_in,             // system clock signal
    input   wire                rst_in,             // reset signal
    input   wire                rdy_in,             // ready signal, pause cpu when low
    input   wire                pc_now_in,
    input   wire                is_storing,
    input   wire                register_busy       [REG_SIZE-1:0],
    input   wire    [31:0]      register_reorder    [REG_SIZE-1:0],
    input   wire    [31:0]      instruction_in,
    output  wire    [31:0]      instruction_out,
    output  wire                is_full_out
    output  wire    [31:0]      modify_reg_value;
    output  wire    [31:0]      modify_reg_number;
    output  wire                is_modifying_reg;
    output  wire    [3:0]       store_entry_out;
    output  wire                is_modifying_store_entry;
    output  wire    [31:0]      pc_predict_out;
    output  wire                is_branch_result;

);
//ROB size 暂定32
parameter ROB_SIZE = 32;
reg   [31:0]  rob_instruction   [ROB_SIZE-1:0];   //存入指令
reg   [4:0]   rob_entry         [ROB_SIZE-1:0];   //rob 编号
reg           rob_ready         [ROB_SIZE-1:0];   //whether ready
reg   [31:0]  rob_value         [ROB_SIZE-1:0];
reg   [3:0]   rob_des           [ROB_SIZE-1:0];
reg   
reg   [31:0]  rob_imme          [31:0];           //算出立即数
reg   [31:0]  rob_pc_now        [31:0];           //pc指针（或许是32位的？）
reg   [31:0]  rob_pc_des        [31:0];           //pc指针（或许是32位的？）
reg           rob_is_full;
reg   [31:0]  reorder_entry_now;                  //rob
reg   [4:0]   rob_head;                           //指向rob的头
reg   [4:0]   rob_rear;                           //指向rob的尾

reg   [31:0]  reg_value;
reg   [31:0]  reg_number;
reg           is_modifying;

reg   [3:0]   store_entry;
reg           is_storing_entry;

reg   [31:0]  pc_predict;
reg           is_branch;

assign is_full_out = rob_is_full;
assign modify_reg_number = reg_number;
assign modify_reg_value = reg_value;
assign is_modifying_reg = is_modifying;
assign store_entry_out = store_entry;
assign is_modifying_store_entry = is_storing_entry;

assign pc_predict_out = pc_predict;
assign is_branch_result = is_branch;

integer  i;

  always @(posedge clk_in) begin
    if(rst_in)begin//清空rob
      for(i = 0; i < ROB_SIZE; i = i + 1)begin
        rob_ready[i] <= 0;
        rob_head <= 0;
        rob_rear <= 0;
      end
    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
        //issue part
        rob_is_full = (rob_rear + 4'b0001 == rob_head) ? 1'b1 : 1'b0;
        if(rob_is_full == FALSE)begin//rob未满
        rob_rear = rob_rear + 1;
        rob_instruction[rob_rear] = instruction_in;//存入空的rob
        rob_entry[rob_ready] = rob_rear+1;

        //commit part
        if(!is_storing && rob_ready[rob_head])begin
        if(rob_instruction[rob_head][6:0] != 7'b1100011 || rob_instruction[rob_head][6:0] != 7'b0100011 )
        begin
          reg_value <= rob_value [rob_des[rob_head]];
          reg_number <= rob_des[rob_head];
        end
        if (rob_instruction[rob_head][6:0] != 7'b0100011)//STORE
        begin
          store_entry <= rob_entry[rob_head];
          is_storing_entry <= 1'b1;
          
        end
        if (rob_instruction[rob_head][6:0] != 7'b1100011)//BRANCH
        begin
          pc_predict <= rob_pc_now [rob_head];
          is_branch <= 1'b1;
        end
        rob_head = rob_head + 1;
        end
        end
    end

  end
endmodule
