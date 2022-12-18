`include "operaType.v"
module reservation_station
#(
    parameter REG_SIZE = 32,
    parameter ROB_SIZE = 32
)
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
         
    //to alu     
    output  reg                     new_calculate,
    output  reg     [5:0]           rs_op_out,
    output  reg     [31:0]          rs_instruct_out,   
    output  reg     [31:0]          rs_vj_out,
    output  reg     [31:0]          rs_vk_out,
    output  reg     [31:0]          rs_imm_out,
    output  reg     [31:0]          rs_pc_out,
    output  reg     [`ENTRY_RANGE]  rs_entry_out,
 
    //CDB 
    input   wire                    lsb_broadcast,
    input   wire    [`ENTRY_RANGE]  lsb_entry,
    input   wire    [31:0]          lsb_value,

    input   wire                    alu_broadcast,
    input   wire    [`ENTRY_RANGE]  alu_entry,
    input   wire    [31:0]          alu_value,
    input   wire    [31:0]          alu_pc_out,

    //broadcast
    output  wire                    rs_broadcast,
    output  wire    [`ENTRY_RANGE]  rs_entry,
    output  wire    [31:0]          rs_result,
    output  wire    [31:0]          rs_pc_result          

);

    parameter RS_SIZE = 32;
    reg     [3:0]                   state   [RS_SIZE-1:0];
    reg     [31:0]                  Vj      [RS_SIZE-1:0];
    reg     [31:0]                  Vk      [RS_SIZE-1:0];  
    reg     [`ENTRY_RANGE]          Qj      [RS_SIZE-1:0];  
    reg     [`ENTRY_RANGE]          Qk      [RS_SIZE-1:0];
    reg     [31:0]                  A       [RS_SIZE-1:0];  //imm 立即数
    reg     [31:0]                  inst    [RS_SIZE-1:0];
    reg     [31:0]                  entry   [RS_SIZE-1:0];
    reg     [31:0]                  rs_pc   [RS_SIZE-1:0];
    reg     [5:0]                   op      [RS_SIZE-1:0];

    reg     [`ENTRY_RANGE]          cur_rs_empty;
    reg     [`ENTRY_RANGE]          cur_rs_ready;

    assign  is_full_out  = cur_rs_empty == `ENTRY_NULL;

    assign  rs_broadcast = alu_broadcast;
    assign  rs_entry     = alu_entry;
    assign  rs_result    = alu_value; 
    assign  rs_pc_result   = alu_pc_out;

    integer i;

    always @(posedge clk_in ) begin
        if(rst_in || roll_back)begin//清空
            for(i = 0; i < RS_SIZE; i = i + 1)begin
                state[i] <= `Empty;
            end
        end

        else if(!rdy_in)begin//低信号 pause

        end

        else 
        //issue part
        begin 
        if (get_instruction)begin
            entry   [cur_rs_empty] <= entry_in;
            op      [cur_rs_empty] <= op_type_in;
            rs_pc   [cur_rs_empty] <= pc_now_in;
            Qj      [cur_rs_empty] <= Qj_in;
            Qk      [cur_rs_empty] <= Qk_in;
            A       [cur_rs_empty] <= imm_in;
            Vj      [cur_rs_empty] <= Vj_in;
            Vk      [cur_rs_empty] <= Vk_in;
            state   [cur_rs_empty] <= `Waiting;
            inst    [cur_rs_empty] <= instruction_in;
        end

        //update ready
        for(i = 0; i < RS_SIZE; i = i + 1)begin
            if(state[i] == `Waiting && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
            state[i] <= `Ready;
        end

        //broadcast part
        if (alu_broadcast) begin
            for(i = 0; i < RS_SIZE; i = i + 1)begin
                if (state[i] == `Waiting)begin
                    if (Qj[i] == alu_entry) begin
                        Qj[i] <= `ENTRY_NULL;
                        Vj[i] <= alu_value;
                    end
                    if (Qk[i] == alu_entry) begin
                        Qk[i] <= `ENTRY_NULL;
                        Vk[i] <= alu_value;
                    end
                end
                end
        end

        if(lsb_broadcast) begin
            for(i = 0; i < RS_SIZE; i = i + 1)begin
                if (state[i] == `Waiting)begin
                    if (Qj[i] == lsb_entry) begin
                        Qj[i] <= `ENTRY_NULL;
                        Vj[i] <= lsb_value;
                    end
                    if (Qk[i] == lsb_entry) begin
                        Qk[i] <= `ENTRY_NULL;
                        Vk[i] <= lsb_value;
                    end
                end
                end
        end

        //then comes the execute part
       if (cur_rs_ready != `ENTRY_NULL)begin // find waiting
            rs_op_out   <= op       [cur_rs_ready];
            rs_vj_out   <= Vj       [cur_rs_ready];
            rs_vk_out   <= Vk       [cur_rs_ready];
            rs_pc_out   <= rs_pc    [cur_rs_ready];
            rs_imm_out  <= A        [cur_rs_ready];
            rs_instruct_out <= inst [cur_rs_ready];
            state[cur_rs_ready] <= `Empty;
            new_calculate   <= `TRUE;
        end
        else new_calculate <= `FALSE;
        //todo broadcast
        end

    end

    always @(*)begin
        for(i = 0; i < RS_SIZE; i = i + 1)begin
            if(state[i] == `Waiting && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
                state[i] = `Ready;
        end
        i = 0;
        while( i < 6'd32 && state[i] != `Empty )begin
            i = i + 1;
        end
        cur_rs_empty = i;
        i = 0;
        while( i < 6'd32 && state[i] != `Ready )begin
            i = i + 1;
        end
        cur_rs_ready = i;
    end
    endmodule