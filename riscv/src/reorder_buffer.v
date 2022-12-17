`include "operaType.v"

module reorder_buffer(
    input   wire                clk_in,             // system clock signal
    input   wire                rst_in,             // reset signal
    input   wire                rdy_in,             // ready signal, pause cpu when low

    output  wire                rob_is_full,
    output  wire                cur_entry,
    input   wire                roll_back,

    //ISQ
    input   wire                get_instruction,
    input   wire    [31:0]      isq_ins_in,
    input   wire    [31:0]      isq_pc_in,

    //decoder
    input   wire    [5:0]       rd_in,
    input   wire    [2:0]       op_type_in,
    input   wire    [5:0]       op_in,

    //broadcast
    output  reg                 rob_commit,
    output  reg     [31:0]      rob_pc_commit,
    output  reg     [5:0]       rob_op_commit,
    output  reg     [2:0]       rob_op_type_commit,
    output  reg     [31:0]      rob_result_out,

    //rs alu broadcast
    input   wire                    rs_broadcast,
    input   wire    [31:0]          rs_result,
    input   wire    [31:0]          rs_pc_in,
    input   wire    [`ENTRY_RANGE]  rs_entry,

    //lsb broadcast
    input   wire                    lsb_broadcast,
    input   wire    [31:0]          lsb_result,
    input   wire    [`ENTRY_RANGE]  lsb_entry,

    output  wire    [4:0]           rob_head_out,
    output  wire    [4:0]           rob_rear_out,

    input   wire                    lsb_store_addressed,
    input   wire    [`ENTRY_RANGE]  lsb_store_entry


);
    //ROB size
    parameter ROB_SIZE = 32;

    reg   [31:0]    rob_instruction   [ROB_SIZE-1:0];   //存入指令
    reg   [5:0]     rob_entry         [ROB_SIZE-1:0];   //rob 编号
    reg             rob_ready         [ROB_SIZE-1:0];   //whether ready
    reg   [31:0]    rob_result        [ROB_SIZE-1:0];
    reg   [5:0]     rob_des           [ROB_SIZE-1:0];
    reg   [5:0]     rob_op            [ROB_SIZE-1:0];
    reg   [2:0]     rob_op_type       [ROB_SIZE-1:0];
    reg   [31:0]    rob_pc            [ROB_SIZE-1:0];
    reg   [31:0]    rob_pc_result     [ROB_SIZE-1:0];

    reg   [4:0]     rob_head;                           //指向rob的头
    reg   [4:0]     rob_rear;                           //指向rob的尾

    reg             is_storing;

    assign rob_is_full = rob_head == rob_rear + 1;
    assign cur_entry = rob_rear;
    
    assign rob_head_out = rob_head;
    assign rob_rear_out = rob_rear;


    integer  i;

      always @(posedge clk_in) begin
        if(rst_in || roll_back)begin//清空rob
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
            if(get_instruction == `TRUE)begin
              rob_instruction[rob_rear] <= isq_ins_in;//存入空的rob
              rob_entry [rob_rear] <= rob_rear;
              rob_ready [rob_rear] <= 0;
              rob_des   [rob_rear] <= rd_in;
              rob_pc    [rob_rear] <= isq_pc_in;
              rob_op    [rob_rear] <= op_in;
              rob_op_type [rob_rear] <= op_type_in;
              rob_ready [rob_rear] <= `FALSE;
              rob_rear            <= rob_rear + 1;
            end

            //commit part
            if(!is_storing && rob_ready[rob_head])begin
                rob_commit <= `TRUE;
                rob_pc_commit <= rob_pc[rob_head];
                rob_op_commit <= rob_op[rob_head];
                rob_op_type_commit <= rob_op_type[rob_head];
                rob_result_out <= rob_result[rob_head];
                rob_ready[rob_head] <= `FALSE;
                rob_head <= rob_head + 1;
                if(rob_op_type[rob_head] == `SType) is_storing <= `TRUE;
            end
            else begin
              rob_commit <= `FALSE;
            end

            //broadcast
            if(lsb_broadcast)begin
              for(i = rob_head; i != rob_rear; i = i + 1)begin
                  if(rob_entry[i] == lsb_entry) begin
                    rob_ready[i] <= `TRUE;
                    rob_result[i] <= lsb_result;
                    is_storing <= `FALSE;
                  end
              end
            end

            if(lsb_store_addressed)begin
              for(i = rob_head; i != rob_rear; i = i + 1)begin
                  if(rob_entry[i] == lsb_store_entry) begin
                    rob_ready[i] <= `TRUE;
                  end
              end
            end

            if(rs_broadcast)begin
              for(i = rob_head; i != rob_rear; i = i + 1)begin
                  if(rob_entry[i] == rs_entry) begin
                    rob_ready[i] <= `TRUE;
                    rob_result[i] <= rs_result;
                    rob_pc_result[i] <= rs_pc_in;
                  end
              end
            end
            end


        end

endmodule
