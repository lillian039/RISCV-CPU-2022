`include "operaType.v"
//control data flow among LSBuffer InstructionQueue any reset signal
//if branch wrong, than clear rob, also need to finish the operation before
//优先级：暂定 store > load > fetch
module memory_controller
#(
    parameter ADDR_WIDTH = 17
)
(
    input   wire                    clk_in,// system clock signal
    input   wire                    rst_in,// reset signal
    input   wire                    rdy_in,// ready signal, pause cpu when low
    
    //RAM
    output  wire                    rw_select,
    output  reg    [7:0]            ram_store_data,
    input   wire   [7:0]            ram_load_data,
    output  wire   [ADDR_WIDTH-1:0] addr_in,
    output  wire                    chip_enable,

    //lsb
    input   wire                    lsb_load,
    input   wire    [`ADDR_RANGE]   load_address,
    input   wire    [5:0]           op_type_load,
    output  wire                    finished_load,
    output  wire    [31:0]          get_load_data,

    input   wire                    lsb_store,
    input   wire    [`ADDR_RANGE]   store_address,
    input   wire    [5:0]           op_type_store,
    input   wire    [31:0]          get_store_data,
    output  wire                    finished_store,

    //fetch
    input   wire                    fetch_start,
    input   wire    [31:0]          pc,
    output  wire                    finish_fetch,
    output  wire    [31:0]          instruction_out,

    output  wire                    is_idle
);

    reg     [1:0]           store_cnt;
    reg     [2:0]           load_cnt;
    reg     [2:0]           fetch_cnt;

    reg                     is_loading;
    reg                     is_storing;
    reg                     is_fetching;

    reg                     load_finish;
    reg                     store_finish;
    reg                     fetch_finish;

    reg     [`ADDR_RANGE]   addr_record;

    reg     [31:0]          load_data;
    reg     [5:0]           load_op;
    
    reg     [31:0]          store_data;
    reg     [5:0]           store_op;

    reg     [31:0]          fetch_instruct;

    assign  is_idle = !is_loading && !is_storing && !is_fetching;
    assign  rw_select = is_storing ?  0 : 1; //1 read 0 write
    assign  chip_enable = is_storing || is_loading || is_fetching;
    assign  addr_in = addr_record;

    assign  finished_load = load_finish;
    assign  get_load_data = load_data;

    assign  finished_store = store_finish;

    assign  finish_fetch = fetch_finish;
    assign  instruction_out = fetch_instruct;

    always @(*)begin
        if(store_op == `TRUE && is_idle)begin
            is_storing  = `TRUE;
            store_op    = op_type_store;
            addr_record  = store_address;
            if(op_type_store == `SW)        store_cnt = 2'b11;//3
            else if(op_type_store == `SH)   store_cnt = 2'b01;//1
            else if(op_type_store == `SB)   store_cnt = 2'b00;//0
        end

        else if(lsb_load == `TRUE && is_idle)begin
            is_loading  = `TRUE;
            load_op     = op_type_load;
            addr_record   = load_address;
            if(op_type_load == `LW) load_cnt = 3'b100;//4
            else if(op_type_load == `LH || op_type_load == `LHU) load_cnt = 3'b010;//2
            else if(op_type_load == `LB || op_type_load == `LBU) load_cnt = 3'b001;//1
        end

        else if(fetch_start == `TRUE && is_idle)begin
            is_fetching = `TRUE;
            addr_record = pc[16:0];
            fetch_cnt = 3'b100;//4
        end

    end

    always @(posedge clk_in)  begin
        if(rst_in)begin//清空
            is_loading <= `FALSE;
            is_storing <= `FALSE;
            is_fetching <= `FALSE;
        end
        else if(!rdy_in)begin//低信号 pause

        end
        else begin
            if(load_finish == `TRUE)begin
                load_finish <= `FALSE;
            end
            if(store_finish == `TRUE)begin
                store_finish <= `FALSE;
            end
            if(fetch_finish == `TRUE)begin
                fetch_finish <= `FALSE;
            end
            if(is_loading == `TRUE)begin
                if(load_op == `LW)begin
                if(load_cnt == 3'b100)begin  end
                    else if(load_cnt == 3'b011) load_data[7:0] <= ram_load_data;
                    else if(load_cnt == 3'b010) load_data[15:8] <= ram_load_data;
                    else if(load_cnt == 3'b001) load_data[23:16] <= ram_load_data;
                    else begin
                        load_data[31:24] <= ram_load_data;
                        is_loading <= `FALSE;
                        load_finish <= `TRUE;
                    end
                    load_cnt <= load_cnt - 1; 
                    addr_record <= addr_record + 1;
                end
                else if(load_op == `LH || load_op == `LHU)begin
                    if(load_cnt == 3'b010)begin load_data <= 0; end
                    else if(load_cnt == 3'b001) load_data[7:0] <= ram_load_data;
                    else begin
                        load_data[15:8] <= ram_load_data;
                        if(load_op == `LHU) load_data[31:16] <= {16{ram_load_data[7]}};
                        is_loading <= `FALSE;
                        load_finish <= `TRUE;
                end
                load_cnt <= load_cnt - 1;
                addr_record <= addr_record + 1;
                end
                else if(load_op == `LB || load_op == `LBU)begin
                    if(load_cnt == 3'b001)begin 
                        load_cnt <= load_cnt - 1;
                        load_data <= 0;
                    end
                    else begin
                        load_data[7:0] <= ram_load_data;
                        if(load_op == `LBU) load_data[31:8] <= {32{ram_load_data[7]}};
                        is_loading <= `FALSE;
                        load_finish <= `TRUE;
                    end
                end
            end

            if(is_storing == `TRUE)begin
                if(store_op == `SW)begin
                    if(store_cnt == 2'b11) ram_store_data <= store_data[7:0];
                    else if(store_cnt == 2'b10) ram_store_data <= store_data[15:8];
                    else if(store_cnt == 2'b01) ram_store_data <= store_data[23:16];
                    else begin
                    ram_store_data <= store_data[31:14];
                    is_storing <= `FALSE;
                    store_finish <= `TRUE;
                end
                addr_record <= addr_record + 1;
                store_cnt <= store_cnt - 1;
                end
                else if(store_op == `SH)begin
                    if(store_cnt == 2'b01) ram_store_data <= store_data[7:0];
                    else begin
                    ram_store_data <= store_data[15:8];
                    is_storing <= `FALSE;
                    store_finish <= `TRUE;
                end
                addr_record <= addr_record + 1;
                store_cnt <= store_cnt - 1;
                end
                else if(store_op == `SB)begin
                    ram_store_data <= store_data[7:0];
                    is_storing <= `FALSE;
                    store_finish <= `TRUE;
                end
            end
            
            if(is_fetching)begin
                if(fetch_cnt == 3'b100)begin  end
                else if(fetch_cnt == 3'b011) fetch_instruct[7:0] <= ram_load_data;
                else if(fetch_cnt == 3'b010) fetch_instruct[15:8] <= ram_load_data;
                else if(fetch_cnt == 3'b001) fetch_instruct[23:16] <= ram_load_data;
                else begin
                    fetch_instruct[31:24] <= ram_load_data;
                    is_fetching <= `FALSE;
                    fetch_finish <= `TRUE;
                end
                load_cnt <= load_cnt - 1; 
                addr_record <= addr_record + 1;
            end

        end
    end   
endmodule

