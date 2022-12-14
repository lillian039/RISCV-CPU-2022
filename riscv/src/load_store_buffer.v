`include "operaType.v"
module load_store_buffer
(
    input   wire                    clk_in,// system clock signal
    input   wire                    rst_in,// reset signal
    input   wire                    rdy_in,// ready signal, pause cpu when low

    input   wire    [31:0]          pc_now_in,
    input   wire                    get_instruction,
    input   wire    [31:0]          instruction_in,
    input   wire    [31:0]          entry_in,

    //predict wrong
    input   wire                    roll_back,
     
    //RegisterFile   
    input   wire    [31:0]          Vj_in,
    input   wire    [31:0]          Vk_in,
    input   wire    [31:0]          Qj_in,
    input   wire    [31:0]          Qk_in,
     
    //decoder    
    input   wire    [31:0]          imm_in,
    input   wire    [5:0]           op_type_in,
    input   wire    [4:0]           rd_in,
     
    output  wire                    is_full_out,
         
    //to lsb alu    
    output  reg     [6:0]           opcode_out,
    output  reg     [31:0]          rs_op_out,   
    output  reg     [31:0]          rs_vj_out,
    output  reg     [31:0]          rs_vk_out,
    output  reg     [31:0]          rs_store_pc_out,
    output  reg     [31:0]          rs_imm_out,
    output  reg     [31:0]          rs_pc_out,
    output  reg     [`ENTRY_RANGE]  rs_des_out,
 
    //rs broadcast
    input   wire                    rs_broadcast,
    input   wire    [`ENTRY_RANGE]  rs_entry,
    input   wire    [31:0]          rs_value,

    //lsb broadcast
    input   wire                    alu_broadcast,
    input   wire    [`ENTRY_RANGE]  alu_entry,
    input   wire    [31:0]          alu_value,
    input   wire    [31:0]          alu_pc_out,

    //rob commit
    input   wire                    rob_commit,
    input   wire    [31:0]          rob_op_commit,
    input   wire    [2:0]           rob_op_type_commit,
    input   wire    [31:0]          rob_result_out
);

    parameter LSB_SIZE=32;
    reg [3:0]               state    [LSB_SIZE-1:0];
    reg [31:0]              Vj       [LSB_SIZE-1:0];
    reg [31:0]              Vk       [LSB_SIZE-1:0];  
    reg [31:0]              Qj       [LSB_SIZE-1:0];     //0 empty
    reg [31:0]              Qk       [LSB_SIZE-1:0];
    reg [31:0]              A        [LSB_SIZE-1:0];
    reg [31:0]              op       [LSB_SIZE-1:0];
    reg [`ENTRY_RANGE]      entry    [LSB_SIZE-1:0];
    reg [31:0]              result   [LSB_SIZE-1:0];
    reg [31:0]              des      [LSB_SIZE-1:0];
    reg [31:0]              rs_clock [LSB_SIZE-1:0];
    reg [31:0]              address  [LSB_SIZE-1:0];

    reg     [`ENTRY_RANGE]          cur_lsb_empty;
    reg     [`ENTRY_RANGE]          cur_lsb_ready;

    integer i;


    always @(posedge clk_in ) begin
        if(rst_in)begin//清空
            for(i = 0;i < LSB_SIZE;i = i + 1)begin
                state[i] <= `Empty;
            end
        end

        else if(!rdy_in)begin//低信号 pause
            if (get_instruction && (op_type_in == `SType || op_type_in == `ILoadType))begin
                entry   [cur_lsb_empty] <= entry_in;
                op      [cur_lsb_empty] <= instruction_in;
                Qj      [cur_lsb_empty] <= Qj_in;
                Qk      [cur_lsb_empty] <= Qk_in;
                A       [cur_lsb_empty] <= imm_in;
                Vj      [cur_lsb_empty] <= Vj_in;
                Vk      [cur_lsb_empty] <= Vk_in;
                state   [cur_lsb_empty] <= `Waiting;
            end
        end

        else begin 

        end
        end

    

endmodule