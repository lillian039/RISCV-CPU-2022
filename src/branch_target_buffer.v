`include "operaType.v"
`define    stronglyNotTaken     2'b00
`define    weaklyNotTaken       2'b01
`define    weaklyTaken          2'b10
`define    stronglyTaken        2'b11

module branch_target_buffer(
    input   wire            clk_in,                 //  system clock signal
    input   wire            rst_in,                 //  reset signal
    input   wire            rdy_in,                 //  ready signal, pause cpu when low

    input   wire            fetch_new_instruction,

    //ISQ decoder
    input   wire    [2:0]   op_type,
    input   wire    [5:0]   op_in,
    input   wire    [31:0]  imm,

    //pc reg
    output  wire    [31:0]  pc_out,

    //ROB
    input   wire            rob_commit,
    input   wire    [31:0]  rob_pc_commit,
    input   wire    [5:0]   rob_op_commit,
    input   wire    [2:0]   rob_op_type,
    input   wire    [31:0]  rob_result,
    input   wire    [31:0]  rob_pc_result,
    output  reg             roll_back,

    //fetch
    output  reg             stop_fetching//meet JALR     

);
    parameter           BTBSIZE = 64;

    reg         [1:0]   btb  [BTBSIZE-1:0];

    reg         [31:0]  sum;
    reg         [31:0]  wrong;
    reg         [31:0]  pc;

    assign      pc_out = pc;

    integer             i;
    wire     [5:0]     hash_idx_pc  = pc[5:0];
    wire     [5:0]     hash_idx_rob = rob_pc_commit[5:0];

    always @(posedge clk_in) begin
        if (rst_in)begin//清空btb
        for( i = 0; i < BTBSIZE; i = i + 1)begin
            btb[i] <= `weaklyNotTaken;
        end
            pc <= 0;
            stop_fetching <= `FALSE;
            sum <= 0;
            wrong <= 0;
        end

        else if(!rdy_in)begin//低信号或没有需要判断的jump  pause
        end

        else if(roll_back)begin
            stop_fetching <= `FALSE;
            roll_back <= `FALSE;
        end 

        else begin
        if(fetch_new_instruction)begin
            if(op_in == `JAL)begin
                pc <= pc + imm;
            end
            else if(op_in == `JALR)begin
                stop_fetching <= `TRUE;
            end
            else if(op_type == `BType)begin
                sum <= sum + 1;
                if (btb[hash_idx_pc] == `weaklyTaken || btb[hash_idx_pc] == `stronglyTaken) pc <= pc + imm;
                else pc <= pc + 4;
            end
            else begin
                pc <= pc + 4;
            end
        end
        if(rob_commit)begin
            if(rob_op_commit == `JALR)begin
                stop_fetching <= `FALSE;
                pc <= rob_pc_result;
                roll_back <= `FALSE;
            end  
            else if(rob_op_type == `BType)begin
                if(btb[hash_idx_rob] == `weaklyNotTaken || btb[hash_idx_rob] == `stronglyNotTaken )begin
                    if(rob_result == `TRUE) begin
                        roll_back <= `TRUE;
                        wrong <= wrong + 1;
                        pc <= rob_pc_result;
                    end
                    else roll_back <= `FALSE;
                end
                else begin
                    if(rob_result == `FALSE) begin
                        roll_back <= `TRUE;
                        wrong <= wrong + 1;
                        pc <= rob_pc_commit + 4;
                    end
                    else begin
                        roll_back <= `FALSE;
                    end
                end
                if(rob_result == `TRUE  && btb[hash_idx_rob] < 2'b11) btb[hash_idx_rob] <= btb[hash_idx_rob] + 1;
                else if(rob_result == `FALSE && btb[hash_idx_rob] > 2'b00) btb[hash_idx_rob] <= btb[hash_idx_rob] - 1;
            end
        end
        else roll_back <= `FALSE;
        end

    end
endmodule