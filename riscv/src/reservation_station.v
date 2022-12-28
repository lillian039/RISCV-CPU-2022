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
    input   wire    [`ENTRY_RANGE]  entry_in,

    //predict wrong
    input   wire                    roll_back,
     
    //RegisterFile   
    input   wire    [31:0]          Vj_in,
    input   wire    [31:0]          Vk_in,
    input   wire    [`ENTRY_RANGE]  Qj_in,
    input   wire    [`ENTRY_RANGE]  Qk_in,
     
    //decoder    
    input   wire    [31:0]          imm_in,
    input   wire    [5:0]           op_in,
    input   wire    [5:0]           rd_in,
     
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

    reg                             ready   [RS_SIZE-1:0];

  //  reg     [RS_SIZE-1:0]           rs_empty; //1 empty 0 full
  //  reg     [RS_SIZE-1:0]           rs_ready; //1 ready 0 no

    wire     [`ENTRY_RANGE]          cur_rs_empty;
    wire     [`ENTRY_RANGE]          cur_rs_ready;

    reg      debug_rs;

    assign  is_full_out  = cur_rs_empty == `ENTRY_NULL;

    assign  rs_broadcast    = alu_broadcast;
    assign  rs_entry        = alu_entry;
    assign  rs_result       = alu_value; 
    assign  rs_pc_result    = alu_pc_out;

    integer i;

    always @(posedge clk_in ) begin
        if(rst_in || roll_back)begin//清空
            for(i = 0; i < RS_SIZE; i = i + 1)begin
                state[i] <= `Empty;
                Vj[i] <= 0;
                Vk[i] <= 0;
                Qj[i] <= 0;
                Qk[i] <= 0;
                A [i] <= 0;
                inst[i] <= 0;
                entry[i] <= 0;
                rs_pc[i] <= 0;
                op[i] <= 0;

                ready[i]<=0;
            end

            new_calculate <= 0;
            rs_op_out <= 0;
            rs_instruct_out <= 0;
            rs_vj_out <= 0;
            rs_vk_out <= 0;
            rs_imm_out <= 0;
            rs_pc_out <= 0;
            rs_entry_out <= 0;            
        end

        else if(!rdy_in)begin//低信号 pause

        end

        else 
        //issue part
        begin 
        if (get_instruction)begin
            entry   [cur_rs_empty] <= entry_in;
            op      [cur_rs_empty] <= op_in;
            rs_pc   [cur_rs_empty] <= pc_now_in;
            Qj      [cur_rs_empty] <= Qj_in;
            Qk      [cur_rs_empty] <= Qk_in;
            A       [cur_rs_empty] <= imm_in;
            Vj      [cur_rs_empty] <= Vj_in;
            Vk      [cur_rs_empty] <= Vk_in;
            state   [cur_rs_empty] <= `Waiting;
            inst    [cur_rs_empty] <= instruction_in;

            ready[i] <= 0;
        end

        //update ready
        for(i = 0; i < RS_SIZE; i = i + 1)begin
            if(state[i] == `Waiting && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
            state[i] <= `Ready;
            
            ready[i] <= 1;
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
            new_calculate   <= `TRUE;
            rs_op_out   <= op       [cur_rs_ready];
            if(op[cur_rs_ready] == 6'd25)begin
                debug_rs <= `TRUE;
            end
            else debug_rs <= `FALSE;
            rs_instruct_out <= inst [cur_rs_ready];
            rs_vj_out   <= Vj       [cur_rs_ready];
            rs_vk_out   <= Vk       [cur_rs_ready];
            rs_imm_out  <= A        [cur_rs_ready];
            rs_pc_out   <= rs_pc    [cur_rs_ready];
            rs_entry_out <= entry   [cur_rs_ready];
            state[cur_rs_ready] <= `Empty;

            ready[cur_rs_ready] <= 0;
        end
        else new_calculate <= `FALSE;
        end

    end

    // integer j, k;
    // always @(*)begin
    //     cur_rs_empty = `ENTRY_NULL;
    //     for(j = 0; j < 6'd32; j = j + 1)begin
    //         if(state[j] == `Empty)cur_rs_empty = j;
    //     end

    //     cur_rs_ready = `ENTRY_NULL;
    //     for(k = 0; k < 6'd32; k = k + 1)begin
    //         if(state[k] == `Ready)cur_rs_ready = k;
    //     end
    // end

    assign cur_rs_empty = ~state[ 0] ?  0 :
                             ~state[ 1] ?  1 :
                             ~state[ 2] ?  2 :
                             ~state[ 3] ?  3 :
                             ~state[ 4] ?  4 :
                             ~state[ 5] ?  5 :
                             ~state[ 6] ?  6 :
                             ~state[ 7] ?  7 :
                             ~state[ 8] ?  8 :
                             ~state[ 9] ?  9 :
                             ~state[10] ? 10 :
                             ~state[11] ? 11 :
                             ~state[12] ? 12 :
                             ~state[13] ? 13 :
                             ~state[14] ? 14 :
                             ~state[15] ? 15 :
                             ~state[16] ? 16 :
                             ~state[17] ? 17 :
                             ~state[18] ? 18 :
                             ~state[19] ? 19 :
                             ~state[20] ? 20 :
                             ~state[21] ? 21 :
                             ~state[22] ? 22 :
                             ~state[23] ? 23 :
                             ~state[24] ? 24 :
                             ~state[25] ? 25 :
                             ~state[26] ? 26 :
                             ~state[27] ? 27 :
                             ~state[28] ? 28 :
                             ~state[29] ? 29 :
                             ~state[30] ? 30 :
                             ~state[31] ? 31 :
                             `ENTRY_NULL;

    assign cur_rs_ready = ready[ 0] ?  0 :
                        ready[ 1] ?  1 :
                        ready[ 2] ?  2 :
                        ready[ 3] ?  3 :
                        ready[ 4] ?  4 :
                        ready[ 5] ?  5 :
                        ready[ 6] ?  6 :
                        ready[ 7] ?  7 :
                        ready[ 8] ?  8 :
                        ready[ 9] ?  9 :
                        ready[10] ? 10 :
                        ready[11] ? 11 :
                        ready[12] ? 12 :
                        ready[13] ? 13 :
                        ready[14] ? 14 :
                        ready[15] ? 15 :
                        ready[16] ? 16 :
                        ready[17] ? 17 :
                        ready[18] ? 18 :
                        ready[19] ? 19 :
                        ready[20] ? 20 :
                        ready[21] ? 21 :
                        ready[22] ? 22 :
                        ready[23] ? 23 :
                        ready[24] ? 24 :
                        ready[25] ? 25 :
                        ready[26] ? 26 :
                        ready[27] ? 27 :
                        ready[28] ? 28 :
                        ready[29] ? 29 :
                        ready[30] ? 30 :
                        ready[31] ? 31 :
                        `ENTRY_NULL;
    endmodule