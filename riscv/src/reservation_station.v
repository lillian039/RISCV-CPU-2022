module reservation_station
#(
    parameter REG_SIZE = 32;
    parameter ROB_SIZE = 32;
)
(
    input   wire                clk_in,// system clock signal
    input   wire                rst_in,// reset signal
    input   wire                rdy_in,// ready signal, pause cpu when low

    input   wire    [31:0]      pc_now_in,
    input   wire                is_storing,
    input   wire                get_instruction,
    input   wire    [31:0]      instruction_in,
    input   wire    [31:0]      entry_in,

    input   wire                register_busy    [REG_SIZE-1:0],
    input   wire    [31:0]      register_reorder [REG_SIZE-1:0],
    inout   wire    [31:-]      register_value   [REG_SIZE-1:0],

    input   wire                rob_ready        [ROB_SIZE-1:0],
    input   wire    [31:0]      rob_value        [ROB_SIZE-1:0],

    output  wire                is_full_out
    
    output  wire    [6:0]       opcode,
    output  wire    [31:0]      rs_op,   
    output  wire    [31:0]      rs_vj,
    output  wire    [31:0]      rs_vk,
    output  wire    [31:0]      rs_store_pc_out,
    output  wire    [31:0]      rs_imm,
);
parameter RS_SIZE=32;
reg     [3:0]       state   [RS_SIZE-1:0];
reg     [31:0]      Vj      [RS_SIZE-1:0];
reg     [31:0]      Vk      [RS_SIZE-1:0];  
reg     [31:0]      Qj      [RS_SIZE-1:0];  
reg     [31:0]      Qk      [RS_SIZE-1:0];
reg     [31:0]      A       [RS_SIZE-1:0];  //imm 立即数
reg     [31:0]      op      [RS_SIZE-1:0];
reg     [31:0]      result  [RS_SIZE-1:0];
reg     [31:0]      des     [RS_SIZE-1:0];
reg     [31:0]      rs_pc   [RS_SIZE-1:0];
reg     [6:0]       opcode;
reg     [6:0]       opcode_execute;
reg     [4:0]       rs1;
reg     [4:0]       rs2;
reg     [4:0]       rd;
reg     [2:0]       type_instruct;
reg     [31:0]      h;
reg     [31:0]      rs_op_out;
reg     [31:0]      rs_vj_out;
reg     [31:0]      rs_vk_out;
reg     [31:0]      rs_pc_out;
reg     [31:0]      rs_imm_out;

assign  rs_op = rs_op_out;
assign  rs_vj = rs_vj_out;
assign  rs_vk = rs_vk_out;
assign  rs_store_pc_out = rs_pc_out;
assign  rs_imm = rs_imm_out;

rs1 = 
integer i;
integer j;
assign 
always @(posedge clk ) begin
    if(rst_in)begin//清空
        for(i=0;i<RS_SIZE;i=i+1)begin
            state[i]=Empty;
        end
    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
      if(get_instruction)begin
        i=0;
        while(!(state[i]==Empty))begin
            i=i+1;
        end
        des[i] <= entry_in;
        state[i] <= Waiting;
        op[i] <= instruction_in;
        rs_pc[i] <= pc_now_in;
        Qj[i] <= 0;
        Qk[i] <= 0;
        opcode <= instruction_in [6:0];
        A [i] <= 0;
        //B format
        if(opcode == 7'b1100011)begin
            type_instruct = BType; 
            A[i][12] <= op[31];
            A[i][10:5] <= op[30:25];
            A[i][4:1] <= op[11:8];
            A[i][11] <= op[7];
            if(op[31] == 1'b1) A[31:12] <= ~A[i][31:12];
        end
        //J format
        else if(opcode == 7'b110111)begin
            type_instruct = JType;
            A[i][20] <= op[31];
            A[i][10:1] <= op[30:21];
            A[i][11] <= op[20];
            A[i][19:12] <= op[19:12];
            if(op[31] == 1'b1) A[i][31:20] <= ~A[i][31:20]
        end
        //I format
        else if(opcode == 7'b0010011 || opcode == 7'b0000011 || op == 7'b1100111)begin
            type_instruct = IType;
            A[i][11:0] <= op [31:20];
            if(op[31] == 1'b1) A[i][31:20] <= ~A[i][31:20];

        end
        //R format
        else if(opcode == 7'b0110011)type_instruct = RType;
        //U format
        else if(opcode == 7'b0110111 || opcode == 7'b0010111)begin
            type_instruct = UType;
            A[i][31:20] = op [31:20];
        end
        //getimm
        if(type_instruct == R || type_instruct == I || type_instruct == B )begin
            rs1 = op[19:15];
            if(register_busy[rs1])begin
                h = register_reorder[rs1];// h 得是 1 base 的
                if(rob_ready[h-1]) Vj[i] = rob_value[h-1];
                else Qj[i] = h;
            end
            else Vj[i] = register_value[rs1];
        end
        if(type_instruct == R || type_instruct == B)begin
            rs2 = op[24:20];
             if(register_busy[rs2])begin
                h = register_reorder[rs2];
                if(rob_ready[h-1]) Vj[i] = rob_value[h-1];
                else Qj[i] = h;
            end
            else Vj[i] = register_value[rs1];
        end
      end

      //then comes the execute part
      j=0;
      while (j < RS_SIZE && !Qj[j] == 0 && !Qk[j] == 0 && state[j]!=Waiting )begin
        j=j+1;
      end
      if(j != RS_SIZE)begin // find waiting
        state[j] = Finished;
        rs_op_out <= op[j];
        rs_vj_out <= Vj[j];
        rs_vk_out <= Vk[j];
        rs_pc_out <= rs_pc[j];
        rs_imm_out <= A[j];
      end
    //todo broadcast
    end

end
endmodule