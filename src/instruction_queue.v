`include "operaType.v"
module instruction_queue(
    input   wire            clk_in,             // system clock signal
    input   wire            rst_in,             // reset signal
    input   wire            rdy_in,             // ready signal, pause cpu when low

    //BTB
    input   wire            roll_back,

    input   wire            instruction_ready,  //whether icache/mem get the instruction
    input   wire    [31:0]  instruction_in,     // 32 width instruction
    input   wire    [31:0]  pc_in,

    //ROB
    input   wire            rob_is_full,
    output  reg             ins_to_rob,   

    //RS
    input   wire            rs_is_full,
    output  reg             ins_to_rs,   

    //LSB
    input   wire            lsb_is_full,
    output  reg             ins_to_lsb,   

    output  wire    [31:0]  instruction_out,
    output  wire    [31:0]  ins_pc_out,

    //decoder
    input   wire    [2:0]   op_type_in,   

    output  wire            is_full             // whether instrutcion queue is full
);

    reg     [31:0]  instruction_isq     [31:0]; //size 32
    reg     [31:0]  pc_isq              [31:0];
    reg     [2:0]   op_type_isq         [31:0];

    reg     [4:0]   isq_head;                   //q_head 0-31
    reg     [4:0]   isq_rear;                   //q_rear 0-31

    wire            isq_is_empty = isq_head == isq_rear;
    wire    [2:0]   op_type_head    = op_type_isq[isq_head];

    wire    [4:0]   full_flag = isq_rear + 1;

    assign  is_full         = isq_head == full_flag;
    assign  instruction_out = instruction_isq[isq_head];
    assign  ins_pc_out      = pc_isq[isq_head];


    integer i;

    always @(posedge clk_in) begin
        if(rst_in || roll_back)begin//清空isq
            isq_head    <= 0;
            isq_rear    <= 0;

            ins_to_lsb  <= 0;
            ins_to_rs   <= 0;
            ins_to_rob  <= 0;

            for( i = 0; i < 32; i = i + 1)begin
                instruction_isq[i] <= 32'b0;
                pc_isq[i] <= 32'b0;
                op_type_isq[i] <= 32'b0;
            end
        end
        else if(!rdy_in)begin//低信号 pause

        end

        else begin 
            if(instruction_ready == `TRUE)begin
                instruction_isq [isq_rear] <= instruction_in;
                pc_isq          [isq_rear] <= pc_in;
                op_type_isq     [isq_rear] <= op_type_in;
                isq_rear <= isq_rear + 1;
            end
            
            if(!isq_is_empty)begin

            if(ins_to_rob)begin
                isq_head <= isq_head + 1;
                ins_to_rob <= `FALSE;
                ins_to_lsb <= `FALSE;
                ins_to_rs  <= `FALSE;
            end
            else begin
            //to load store buffer
                if(op_type_head == `SType || op_type_head == `ILoadType)begin
                    if (rob_is_full == `FALSE && lsb_is_full == `FALSE)begin
                        ins_to_rob <= `TRUE;
                        ins_to_lsb <= `TRUE;
                        ins_to_rs  <= `FALSE;
                    end
                    else begin
                        ins_to_rob <= `FALSE;
                        ins_to_lsb <= `FALSE;
                        ins_to_rs  <= `FALSE;
                    end
                end
                else begin
                    if (rob_is_full == `FALSE && rs_is_full == `FALSE)begin
                        ins_to_rob <= `TRUE;
                        ins_to_lsb <= `FALSE;
                        ins_to_rs  <= `TRUE;
                    end
                    else begin
                        ins_to_rob <= `FALSE;
                        ins_to_lsb <= `FALSE;
                        ins_to_rs  <= `FALSE;
                    end
                end
            end
            end
            else  begin
                ins_to_rob <= `FALSE;
                ins_to_lsb <= `FALSE;
                ins_to_rs  <= `FALSE;
            end
        end

    end
endmodule