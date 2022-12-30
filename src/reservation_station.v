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

    wire     [31:0]            debug_state_0 = state[0];
    wire     [`ENTRY_RANGE]    debug_Qj_0 = Qj[0];
    wire     [`ENTRY_RANGE]    debug_Qk_0 = Qk[0];

    wire     [31:0]            debug_state_1 = state[1];
    wire     [`ENTRY_RANGE]    debug_Qj_1 = Qj[1];
    wire     [`ENTRY_RANGE]    debug_Qk_1 = Qk[1];

    wire     [31:0]            debug_state_2 = state[2];
    wire     [`ENTRY_RANGE]    debug_Qj_2 = Qj[2];
    wire     [`ENTRY_RANGE]    debug_Qk_2 = Qk[2];

    wire     [31:0]            debug_state_3 = state[3];
    wire     [`ENTRY_RANGE]    debug_Qj_3 = Qj[3];
    wire     [`ENTRY_RANGE]    debug_Qk_3 = Qk[3];

    wire     [31:0]            debug_state_4 = state[4];
    wire     [`ENTRY_RANGE]    debug_Qj_4 = Qj[4];
    wire     [`ENTRY_RANGE]    debug_Qk_4 = Qk[4];

    wire     [31:0]            debug_state_5 = state[5];
    wire     [`ENTRY_RANGE]    debug_Qj_5 = Qj[5];
    wire     [`ENTRY_RANGE]    debug_Qk_5 = Qk[5];

    wire     [31:0]            debug_state_6 = state[6];
    wire     [`ENTRY_RANGE]    debug_Qj_6 = Qj[6];
    wire     [`ENTRY_RANGE]    debug_Qk_6 = Qk[6];

    wire     [31:0]            debug_state_7 = state[7];
    wire     [`ENTRY_RANGE]    debug_Qj_7 = Qj[7];
    wire     [`ENTRY_RANGE]    debug_Qk_7 = Qk[7];




  //  reg     [RS_SIZE-1:0]           rs_empty; //1 empty 0 full
  //  reg     [RS_SIZE-1:0]           rs_ready; //1 ready 0 no

    reg     [`ENTRY_RANGE]          cur_rs_empty;
    reg     [`ENTRY_RANGE]          cur_rs_ready;

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
            A       [cur_rs_empty] <= imm_in;
            state   [cur_rs_empty] <= `Waiting;
            inst    [cur_rs_empty] <= instruction_in;

            if(instruction_in == 32'hfed79ae3)begin
                if(alu_broadcast && (alu_entry == Qj_in || alu_entry == Qk_in) || lsb_broadcast && (lsb_entry == Qj_in || lsb_entry == Qk_in))$display("...");
                $display("%08x %08x",Qj_in,Qk_in);
            end

            if(alu_broadcast && alu_entry == Qj_in)begin
                Qj[cur_rs_empty] <= `ENTRY_NULL;
                Vj[cur_rs_empty] <= alu_value;
            end
            else if(lsb_broadcast && lsb_entry == Qj_in)begin
                Qj[cur_rs_empty] <= `ENTRY_NULL;
                Vj[cur_rs_empty] <= lsb_value;
            end
            else begin
                Qj[cur_rs_empty] <= Qj_in;
                Vj[cur_rs_empty] <= Vj_in;
            end

            if(alu_broadcast && alu_entry == Qk_in)begin
                Qk[cur_rs_empty] <= `ENTRY_NULL;
                Vk[cur_rs_empty] <= alu_value;
            end
            else if(lsb_broadcast && lsb_entry == Qk_in)begin
                Qk[cur_rs_empty] <= `ENTRY_NULL;
                Vk[cur_rs_empty] <= lsb_value;
            end
            else begin
                Qk[cur_rs_empty] <= Qk_in;
                Vk[cur_rs_empty] <= Vk_in;
            end

        end

        //update ready
        for(i = 0; i < RS_SIZE; i = i + 1)begin
            if(state[i] == `Waiting && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
            state[i] <= `Ready;
        end



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
            if(entry[cur_rs_ready] == `ENTRY_NULL)begin
                $display("bbb");
                $display("broadcast: %08x",entry[cur_rs_ready]);
            end
            rs_instruct_out <= inst [cur_rs_ready];
            rs_vj_out   <= Vj       [cur_rs_ready];
            rs_vk_out   <= Vk       [cur_rs_ready];
            rs_imm_out  <= A        [cur_rs_ready];
            rs_pc_out   <= rs_pc    [cur_rs_ready];
            rs_entry_out <= entry   [cur_rs_ready];
            state[cur_rs_ready] <= `Empty;
        end
        else new_calculate <= `FALSE;
        end

    end

    integer j, k;
    always @(*)begin
       // $display("rs: %d\n",clk_in);
        cur_rs_empty = `ENTRY_NULL;
        for(j = 0; j < RS_SIZE; j = j + 1)begin
            if(state[j] == `Empty)cur_rs_empty = j;
        end

        cur_rs_ready = `ENTRY_NULL;
        for(k = 0; k < RS_SIZE; k = k + 1)begin
            if(state[k] == `Ready)cur_rs_ready = k;
        end
    end
    endmodule