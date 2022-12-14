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
    input   wire                    is_storing,
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
    output  reg     [6:0]           opcode_out,
    output  reg     [31:0]          rs_op_out,   
    output  reg     [31:0]          rs_vj_out,
    output  reg     [31:0]          rs_vk_out,
    output  reg     [31:0]          rs_store_pc_out,
    output  reg     [31:0]          rs_imm_out,
    output  reg     [31:0]          rs_pc_out,
    output  reg     [`ENTRY_RANGE]  rs_des_out,
 
    //CDB 
    input   wire                    lsb_broadcast,
    input   wire    [`ENTRY_RANGE]  lsb_entry,
    input   wire    [31:0]          lsb_value,

    input   wire                    alu_broadcast,
    input   wire    [`ENTRY_RANGE]  alu_entry,
    input   wire    [31:0]          alu_value,
    input   wire    [31:0]          alu_pc_out

);

    parameter RS_SIZE = 32;
    reg     [3:0]                   state   [RS_SIZE-1:0];
    reg     [31:0]                  Vj      [RS_SIZE-1:0];
    reg     [31:0]                  Vk      [RS_SIZE-1:0];  
    reg     [`ENTRY_RANGE]          Qj      [RS_SIZE-1:0];  
    reg     [`ENTRY_RANGE]          Qk      [RS_SIZE-1:0];
    reg     [31:0]                  A       [RS_SIZE-1:0];  //imm 立即数
    reg     [31:0]                  op      [RS_SIZE-1:0];
    reg     [31:0]                  entry   [RS_SIZE-1:0];
    reg     [31:0]                  rs_pc   [RS_SIZE-1:0];
    reg     [6:0]                   op_type [RS_SIZE-1:0];

    reg     [`ENTRY_RANGE]          cur_rs_emtpty;
    reg     [`ENTRY_RANGE]          cur_rs_ready;

    assign is_full_out = cur_rs_emtpty == `ENTRY_NULL;


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
        if (get_instruction && op_type_in != `SType && op_type_in != `ILoadType)begin
            entry   [cur_rs_emtpty] <= entry_in;
            op      [cur_rs_emtpty] <= instruction_in;
            rs_pc   [cur_rs_emtpty] <= pc_now_in;
            Qj      [cur_rs_emtpty] <= Qj_in;
            Qk      [cur_rs_emtpty] <= Qk_in;
            A       [cur_rs_emtpty] <= imm_in;
            Vj      [cur_rs_emtpty] <= Vj_in;
            Vk      [cur_rs_emtpty] <= Vk_in;
            state   [cur_rs_emtpty] <= `Waiting;
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

        //then comes the execute part
       if (cur_rs_ready != `ENTRY_NULL)begin // find waiting
            rs_op_out   <= op       [cur_rs_ready];
            rs_vj_out   <= Vj       [cur_rs_ready];
            rs_vk_out   <= Vk       [cur_rs_ready];
            rs_pc_out   <= rs_pc    [cur_rs_ready];
            rs_imm_out  <= A        [cur_rs_ready];
            state[cur_rs_ready] <= `Empty;
        end
        //todo broadcast
        end

    end

    always @(*)begin
        i = 0;
        while( i < 6'd32 && state[i] != `Empty )begin
            i=i+1;
        end
        cur_rs_emtpty = i;
        i = 0;
        while( i < 6'd32 && state[i] != `Ready )begin
            i=i+1;
        end
        cur_rs_ready = i;
    end
    endmodule