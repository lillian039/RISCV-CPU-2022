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
    output  wire    [`ENTRY_RANGE]  store_entry_out,

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

    reg [3:0]               state       [LSB_SIZE-1:0];
    reg [31:0]              Vj          [LSB_SIZE-1:0];
    reg [31:0]              Vk          [LSB_SIZE-1:0];  
    reg [`ENTRY_RANGE]      Qj          [LSB_SIZE-1:0];     //0 empty
    reg [`ENTRY_RANGE]      Qk          [LSB_SIZE-1:0];
    reg [31:0]              A           [LSB_SIZE-1:0];
    reg [2:0]               op_type     [LSB_SIZE-1:0];
    reg [6:0]               op          [LSB_SIZE-1:0];
    reg [`ENTRY_RANGE]      entry       [LSB_SIZE-1:0];
    reg [31:0]              result      [LSB_SIZE-1:0];
    reg [31:0]              address     [LSB_SIZE-1:0];

    reg [`ENTRY_RANGE]      closest_pre_store   [LSB_SIZE-1:0];

    reg     [`ENTRY_RANGE]          cur_lsb_empty;
    reg     [`ENTRY_RANGE]          cur_lsb_ready;
    reg     [`ENTRY_RANGE]          cur_storing;
    reg     [`ENTRY_RANGE]          cur_loading;
    reg     [`ENTRY_RANGE]          cur_addressed;

    reg         execute_enable;  

    reg         new_load;

    integer i;
    integer j;


    always @(posedge clk_in ) begin
        if(rst_in || roll_back)begin//清空
            for(i = 0; i < LSB_SIZE; i = i + 1)begin
                state[i] <= `Empty;
            end
        end

        else if(!rdy_in)begin//低信号 pause
            
        end

        else begin 
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
                    for(i = 0; i <= LSB_SIZE; i = i + 1)begin
                        if(entry[i] == rob_entry_commit)begin
                            state[i]      <= `Storing;
                            cur_storing   <= i;
                            lsb_store     <= `TRUE;
                            store_address <= address[i];
                            data_store    <= result [i];
                            op_type_store <= op_type[i];
                        end
                    end
                end
            end

            if(finish_store)begin
                lsb_store          <= `FALSE;
                state[cur_storing] <= `Empty;
           //   cur_storing        <= `ENTRY_NULL;
            end

            if(finish_load)begin
                lsb_load           <= `FALSE;
                state[cur_loading] <= `Empty;
            //   cur_loading        <= `ENTRY_NULL;
                lsb_load_broadcast <= `TRUE;
                load_result        <= data_load;
                load_entry_out     <= entry_in[cur_loading];
            end

            //excute step 1: work out address
            if(cur_lsb_ready != `ENTRY_NULL)begin
                if(op_type[cur_lsb_ready] == `ILoadType)begin
                     state[cur_lsb_ready]  <= `Addressed;
                     lsb_store_broadcast   <= `FALSE;
                     address[cur_lsb_ready] <= Vj[cur_lsb_ready] + A[cur_lsb_ready];
                end
                else begin
                    state[cur_lsb_ready]  <= `WaitingStore;
                    lsb_store_broadcast   <= `TRUE;
                    address[cur_lsb_ready] <= Vj[cur_lsb_ready] + A[cur_lsb_ready];
                    result [cur_lsb_ready] <= Vk[cur_lsb_ready];
                end

            end
            else begin
                lsb_store_broadcast <= `FALSE;
            end

            //excute step 2: find out whether load
            if(execute_enable && cur_storing == `ENTRY_NULL && cur_loading == `ENTRY_NULL && cur_addressed != `ENTRY_NULL)begin
                if(closest_pre_store[cur_addressed] != `ENTRY_NULL)begin
                    lsb_load_broadcast   <= `TRUE;
                    load_result          <= result[closest_pre_store[cur_addressed]];
                    load_entry_out       <= entry[cur_addressed];
                    state[cur_addressed] <= `Empty;
                end
                else begin
                    cur_loading  <= cur_addressed;
                    lsb_load     <= `TRUE;
                    load_address <= address[cur_addressed];
                    op_type_load <= op_type [cur_addressed];
                    state[cur_addressed] <= `Loading;
                    lsb_load_broadcast <= `FALSE;
                end
            end
            //update lsb_load_broadcast
            else begin
                if(!finish_load)lsb_load_broadcast <= `FALSE;
            end
        end
    end

    always @(*)begin
        execute_enable = `TRUE;
        for(i = 0; i < LSB_SIZE; i = i + 1)begin
            if(state[i] == `Waiting || state[i] == `Ready)execute_enable = `FALSE;
        end
        for(i = 0; i < LSB_SIZE; i = i + 1)begin
            if(state[i] == `Waiting && Qj[i] == `ENTRY_NULL && Qk[i] == `ENTRY_NULL)
                state[i] = `Ready;
        end

        i = 0;
        while( i < 6'd32 && state[i] != `Empty )begin
            i = i + 1;
        end
        cur_lsb_empty = i;

        i = 0;
        while( i < 6'd32 && state[i] != `Storing )begin
            i = i + 1;
        end
        cur_storing = i;

        while( i < 6'd32 && state[i] != `Loading )begin
            i = i + 1;
        end
        cur_loading = i;

        while( i < 6'd32 && state[i] != `Addressed )begin
            i = i + 1;
        end
        cur_addressed = i;

        i = 0;
        while( i < 6'd32 && state[i] != `Ready )begin
            i = i + 1;
        end
        cur_lsb_ready = i;
    end

    always @(*)begin
        for(i = 0; i < LSB_SIZE; i = i + 1)begin
            closest_pre_store[i] = `ENTRY_NULL;
            if(state[i] == `Addressed)begin
            for(j = 0; j < LSB_SIZE; j = j + 1)begin
                if(state[j] == `WaitingStore && address[j] == address[i])begin
                    if((entry[j] + `ROB_SIZE - rob_head) % `ROB_SIZE < (entry[i] + `ROB_SIZE - rob_head) % `ROB_SIZE)begin
                        if(closest_pre_store[i] == `ENTRY_NULL)closest_pre_store[i] = j;
                        else begin
                            if((entry[j] + `ROB_SIZE - rob_head) % `ROB_SIZE > (entry[closest_pre_store[i]] + `ROB_SIZE - rob_head) % `ROB_SIZE)
                            closest_pre_store[i] = j;
                        end
                    end
                end
            end
            end
        end
    end
    

endmodule