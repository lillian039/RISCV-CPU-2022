`include "operaType.v"
module load_store_buffer
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
    input   wire    [2:0]           op_type_in,
     
    output  wire                    is_full_out,
 
    //rs broadcast
    input   wire                    rs_broadcast,
    input   wire    [`ENTRY_RANGE]  rs_entry,
    input   wire    [31:0]          rs_value,

    //rob commit
    input   wire                    rob_commit,
    input   wire    [`ENTRY_RANGE]  rob_entry_commit,
    input   wire    [2:0]           rob_op_type_commit,
    input   wire    [31:0]          rob_result_out,

    //rob
    input   wire    [4:0]           rob_head,

    //lsb broadcast
    output  reg                     lsb_load_broadcast,
    output  reg     [31:0]          load_result,
    output  reg     [`ENTRY_RANGE]  load_entry_out,

    output  reg                     lsb_store_broadcast,
    output  reg     [`ENTRY_RANGE]  store_entry_out,

    //memory_controller
    input   wire                    finish_store,
    output  reg     [31:0]          data_store,
    output  reg                     lsb_store,
    output  reg     [`ADDR_RANGE]   store_address,
    output  reg     [5:0]           op_type_store,
    
    input   wire                    finish_load,
    input   wire    [31:0]          data_load,
    output  reg                     lsb_load,
    output  reg     [`ADDR_RANGE]   load_address,
    output  reg     [5:0]           op_type_load
    
);

    parameter LSB_SIZE=32;

    reg     [3:0]               state               [LSB_SIZE-1:0];
    reg     [31:0]              Vj                  [LSB_SIZE-1:0];
    reg     [31:0]              Vk                  [LSB_SIZE-1:0];  
    reg     [`ENTRY_RANGE]      Qj                  [LSB_SIZE-1:0];     //0 empty
    reg     [`ENTRY_RANGE]      Qk                  [LSB_SIZE-1:0];
    reg     [31:0]              A                   [LSB_SIZE-1:0];
    reg     [2:0]               op_type             [LSB_SIZE-1:0];
    reg     [6:0]               op                  [LSB_SIZE-1:0];
    reg     [`ENTRY_RANGE]      entry               [LSB_SIZE-1:0];
        
    reg     [4:0]               lsb_head;
    reg     [4:0]               lsb_rear;


    assign  is_full_out     = lsb_head == lsb_rear + 1;
    assign  cur_lsb_empty   = lsb_rear;

    integer i;

    always @(posedge clk_in ) begin
        if(rst_in || roll_back)begin//清空
            for(i = 0; i < LSB_SIZE; i = i + 1)begin
                state[i] <= `Empty;
            end
        end

        else if(!rdy_in)begin//低信号 pause
            
        end

        else begin 
            for(i = 0; i < LSB_SIZE; i = i + 1)begin
                if(state[i] == `Waiting && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
                    state[i] <= `Ready;
            end
            //issue
            if (get_instruction && (op_type_in == `SType || op_type_in == `ILoadType))begin
                entry       [cur_lsb_empty] <= entry_in;
                Qj          [cur_lsb_empty] <= Qj_in;
                Qk          [cur_lsb_empty] <= Qk_in;
                A           [cur_lsb_empty] <= imm_in;
                Vj          [cur_lsb_empty] <= Vj_in;
                Vk          [cur_lsb_empty] <= Vk_in;
                op_type     [cur_lsb_empty] <= op_type_in;
                op          [cur_lsb_empty] <= op_in;
                state       [cur_lsb_empty] <= `Waiting;
            end

            //update by broadcast
            if(rs_broadcast)begin
                for(i = 0; i <= LSB_SIZE; i = i + 1)begin
                    if(state[i] == `Waiting)begin
                        if(Qj[i] == rs_entry)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= rs_value;
                        end
                        if(Qk[i] == rs_entry)begin
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= rs_value;
                        end
                    end
                end
            end

            if(lsb_load_broadcast)begin
                for(i = 0; i <= LSB_SIZE; i = i + 1)begin
                    if(state[i] == `Waiting)begin
                        if(Qj[i] == load_result)begin
                            Qj[i] <= `ENTRY_NULL;
                            Vj[i] <= load_result;
                        end
                        if(Qk[i] == load_result)begin
                            Qk[i] <= `ENTRY_NULL;
                            Vk[i] <= load_result;
                        end
                    end
                end
            end


            if(rob_commit)begin
                if(rob_op_type_commit == `SType)begin
                    state[lsb_head] <= `Storing;
                    lsb_store       <= `TRUE;
                    store_address   <= Vj[lsb_head] + A[lsb_head];
                    data_store      <= Vk[lsb_head];
                    op_type_store   <= op_type[lsb_head];
                end
            end

            if(finish_store)begin
                lsb_store   <= `FALSE;
                lsb_head    <= lsb_head + 1;
            end
            else if(finish_load)begin
                lsb_load           <= `FALSE;
                lsb_load_broadcast <= `TRUE;
                load_result        <= data_load;
                load_entry_out     <= entry_in[lsb_head];
                lsb_head           <= lsb_head + 1;
            end
            else begin
                lsb_load_broadcast <= `FALSE;
            end

            //excute ready head
            if(state[lsb_head] == `Ready)begin
                if(op_type[lsb_head] == `ILoadType)begin
                     state[lsb_head]        <= `Loading;
                     lsb_store_broadcast    <= `FALSE;
                     lsb_load               <= `TRUE;
                     load_address           <= Vj[lsb_head] + A[lsb_head];
                end
                else begin
                    state[lsb_head]         <= `WaitingStore;
                    lsb_store_broadcast     <= `TRUE;
                    store_entry_out         <= entry[lsb_head];
                end
            end
            else begin
                lsb_store_broadcast <= `FALSE;
            end

        end
    end


endmodule