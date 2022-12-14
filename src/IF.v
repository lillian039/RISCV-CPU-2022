`include "operaType.v"
//has inner ISQ BTB Decoder
//connect with ROB RS LSB RAM
module IF(
    input   wire                        clk_in,         // system clock signal
    input   wire                        rst_in,         // reset signal
    input   wire                        rdy_in,         // ready signal, pause cpu when low
    
    //rob broadcast
    input   wire                        rob_commit,
    input   wire    [31:0]              rob_pc_commit,
    input   wire    [5:0]               rob_op_commit,
    input   wire    [2:0]               rob_op_type,
    input   wire    [31:0]              rob_result,
    input   wire    [31:0]              rob_pc_result,

    //rob issue
    input   wire                        rob_is_full,
    output  wire                        ins_to_rob,

    //rs issue
    input   wire                        rs_is_full,
    output  wire                        ins_to_rs,

    //lsb issue
    input   wire                        lsb_is_full,
    output  wire                        ins_to_lsb,

    //memory_controller
    input   wire                        is_idle,
    input   wire                        finish_fetch,
    input   wire    [31:0]              instruction_in,
    input   wire    [31:0]              instruction_pc_in,

    output  wire    [31:0]              pc_out,
    output  wire                        fetch_start,

    //isq
    output  wire    [31:0]              instruction_out, // get instruction in isq
    output  wire    [31:0]              isq_pc_out,
    output  wire                        isq_pc_predict,

    //rob
    input  wire                         roll_back_in
);
    wire                isq_is_full;
    wire                pc_predict;
    wire                isq_hault;

    //decoder
    wire     [31:0]      imm;
    wire     [5:0]       op;
    wire     [5:0]       rs1;
    wire     [5:0]       rs2;
    wire     [5:0]       rd;
    wire     [2:0]       op_type;

    assign      fetch_start = !isq_is_full && !isq_hault;

    //decode instruction from ram and then put in in isq
    decoder isq_decoder(
        .op_in                  (instruction_in),

        .imm_out                (imm),
        .op_out                 (op),
        .rs1                    (rs1),
        .rs2                    (rs2),
        .rd                     (rd),
        .op_type                (op_type)
    );

    instruction_queue ISQ(
        .clk_in                 (clk_in),
        .rst_in                 (rst_in),
        .rdy_in                 (rdy_in),

        .roll_back              (roll_back_in),

        .instruction_ready      (finish_fetch),
        .instruction_in         (instruction_in),
        .pc_in                  (instruction_pc_in),
        .pc_predict_in          (pc_predict),

        .rob_is_full            (rob_is_full),
        .ins_to_rob             (ins_to_rob),

        .rs_is_full             (rs_is_full),
        .ins_to_rs              (ins_to_rs),

        .lsb_is_full            (lsb_is_full),
        .ins_to_lsb             (ins_to_lsb),

        .instruction_out        (instruction_out),
        .ins_pc_out             (isq_pc_out),
        .pc_predict_out         (isq_pc_predict),

        .op_type_in             (op_type),
        .is_full                (isq_is_full)       
    );

    branch_target_buffer BTB(
        .clk_in                 (clk_in),
        .rst_in                 (rst_in),
        .rdy_in                 (rdy_in),

        .fetch_new_instruction  (finish_fetch),

        .op_type                (op_type),
        .op_in                  (op),
        .imm                    (imm),

        .pc_out                 (pc_out),
        .pc_predict             (pc_predict),

        .rob_commit             (rob_commit),
        .rob_pc_commit          (rob_pc_commit),
        .rob_op_commit          (rob_op_commit),
        .rob_op_type            (rob_op_type),
        .rob_result             (rob_result),
        .rob_pc_result          (rob_pc_result),
        .roll_back              (roll_back_in),

        .stop_fetching          (isq_hault)
    );


endmodule