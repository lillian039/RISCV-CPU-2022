`include "operaType.v"
//control data flow among LSBuffer InstructionQueue any reset signal
//if branch wrong, than clear rob, also need to finish the operation before
//优先级：暂定 store > load > fetch
//has inner i-cache
module memory_controller
#(
    parameter ADDR_WIDTH = 17
)
(
    input   wire                    clk_in,// system clock signal
    input   wire                    rst_in,// reset signal
    input   wire                    rdy_in,// ready signal, pause cpu when low

    input   wire                    io_buffer_full,

    input   wire                    roll_back,
    
    //RAM
    output  reg                     rw_select, // 1 write 0 read
    output  reg    [7:0]            ram_store_data,
    input   wire   [7:0]            ram_load_data,
    output  reg    [`ADDR_RANGE]    addr_in,

    //lsb
    input   wire                    lsb_load,
    input   wire    [`ADDR_RANGE]   load_address,
    input   wire    [5:0]           op_type_load,
    output  wire    [31:0]          get_load_data,
    output  wire                    finished_load,

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
    output  reg     [31:0]          instruction_pc_out,

    output  wire                    is_idle
);

    parameter CACHE_SIZE = 256;

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

    //inner i-cache
    wire                    icache_hit;
    reg     [16:0]          icache_tags     [`ICACHE_RANGE];
    reg                     icache_valid    [`ICACHE_RANGE];
    reg     [31:0]          icache_inst     [`ICACHE_RANGE];
    wire    [31:0]          icache_hit_inst;
    
    //index pc[6:0]
    assign  icache_hit = icache_valid[pc[6:0]] && icache_tags[pc[6:0]] == pc[16:0];
    assign  icache_hit_inst = icache_inst[pc[6:0]];

    reg     controller_is_idle;


    assign  is_idle = controller_is_idle;

    assign  finished_load = load_finish;
    assign  get_load_data = load_data;

    assign  finished_store = store_finish;

    assign  finish_fetch = fetch_finish;
    assign  instruction_out = fetch_instruct;

    integer i;
    // integer logfile;
    // initial begin
    //     logfile = $fopen("mem.log","w");
    // end

    always @(posedge clk_in)  begin
        if(rst_in)begin//清空
            load_cnt <= 0;
            store_cnt <= 0;
            fetch_cnt <= 0;

            is_loading <= `FALSE;
            is_storing <= `FALSE;
            is_fetching <= `FALSE;

            load_finish <= 0;
            store_finish <= 0;
            fetch_finish <= 0;

            addr_record <= 0;

            load_data <= 0;
            load_op <= 0;

            store_data <= 0;
            store_op <= 0;

            fetch_instruct <= 0;

            controller_is_idle <= `TRUE;

            rw_select <= 0;

            for(i = 0; i < CACHE_SIZE; i = i + 1)begin
                icache_tags[i] <= 0;
                icache_valid[i] <= 0;
                icache_inst[i] <= 0;
            end
        end
        else if(!rdy_in)begin//低信号 pause

        end
        else if(roll_back)begin
            load_cnt <= 0;
            store_cnt <= 0;
            fetch_cnt <= 0;

            is_loading <= `FALSE;
            is_storing <= `FALSE;
            is_fetching <= `FALSE;

            load_finish <= 0;
            store_finish <= 0;
            fetch_finish <= 0;

            addr_record <= 0;
            addr_in <= 0;

            load_data <= 0;
            load_op <= 0;

            store_data <= 0;
            store_op <= 0;

            fetch_instruct <= 0;

            controller_is_idle <= `TRUE;

            rw_select <= 0;
        end

        else begin
            if(is_idle)begin
                if(load_finish == `TRUE)begin
                    load_finish <= `FALSE;
                end
                else if(store_finish == `TRUE)begin
                    store_finish <= `FALSE;
                    rw_select <= 0;
                end
                else if(fetch_finish == `TRUE)begin
                    fetch_finish <= `FALSE;
                    if(!icache_hit)begin
                        icache_valid [pc[6:0]] <= `TRUE;
                        icache_inst  [pc[6:0]] <= fetch_instruct;
                        icache_tags  [pc[6:0]] <= pc[16:0];
                    end
                end
                else begin

                if((lsb_store == `TRUE && (store_address[17:16] != 2'b11 || !io_buffer_full)))begin
                    is_storing  <= `TRUE;
                    store_op    <= op_type_store;
                   // addr_in <= store_address;
                    addr_record <= store_address;
                    controller_is_idle <= `FALSE;
                    store_data <= get_store_data;
                    if(op_type_store == `SW)        store_cnt <= 2'b11;//3
                    else if(op_type_store == `SH)   store_cnt <= 2'b01;//1
                    else if(op_type_store == `SB)   store_cnt <= 2'b00;//0
                end

                else if(lsb_store == `TRUE && store_address[17:16] == 2'b11 && io_buffer_full)begin
                    //pause
                end

                else if(lsb_load == `TRUE)begin
                    is_loading  <= `TRUE;
                    load_op     <= op_type_load;
                    controller_is_idle <= `FALSE;
                    addr_in <= load_address;
                    if(op_type_load == `LW) load_cnt <= 3'b100;//4
                    else if(op_type_load == `LH || op_type_load == `LHU) load_cnt <= 3'b010;//2
                    else if(op_type_load == `LB || op_type_load == `LBU) load_cnt <= 3'b001;//1
                end

                else if(fetch_start == `TRUE)begin
                    is_fetching <= `TRUE;
                    controller_is_idle <= `FALSE;
                    addr_in <= pc;
                    fetch_cnt <= 3'b100;//4
                    instruction_pc_out <= pc;
                end
                end

            end

            else begin
            if(is_loading == `TRUE)begin
              //  $fdisplay(logfile,"load: time:%d addr: %08x ",$realtime,addr_in);
                if(load_op == `LW)begin
                if(load_cnt == 3'b100)begin  end
                    else if(load_cnt == 3'b011) load_data[7:0] <= ram_load_data;
                    else if(load_cnt == 3'b010) load_data[15:8] <= ram_load_data;
                    else if(load_cnt == 3'b001) load_data[23:16] <= ram_load_data;
                    else begin
                        load_data[31:24] <= ram_load_data;
                        is_loading <= `FALSE;
                        load_finish <= `TRUE;
                        controller_is_idle <= `TRUE;
                    end
                    load_cnt <= load_cnt - 1; 
                    addr_in <= addr_in + 1;
                end
                else if(load_op == `LH || load_op == `LHU)begin
                    if(load_cnt == 3'b010)begin load_data <= 0; end
                    else if(load_cnt == 3'b001) load_data[7:0] <= ram_load_data;
                    else begin
                        load_data[15:8] <= ram_load_data;
                        if(load_op == `LHU) load_data[31:16] <= {16{ram_load_data[7]}};
                        is_loading <= `FALSE;
                        load_finish <= `TRUE;
                        controller_is_idle <= `TRUE;
                end
                    load_cnt <= load_cnt - 1;
                    addr_in <= addr_in + 1;
                end
                else if(load_op == `LB || load_op == `LBU)begin
                    if(load_cnt == 3'b001)begin 
                        load_cnt <= load_cnt - 1;
                        load_data <= 0;
                    end
                    else begin
                        load_data[7:0] <= ram_load_data;
                        if(load_op == `LBU) load_data[31:8] <= {24{ram_load_data[7]}};
                        is_loading <= `FALSE;
                        load_finish <= `TRUE;
                        controller_is_idle <= `TRUE;
                    end
                    addr_in <= addr_in + 1;
                end
            end

            if(is_storing == `TRUE)begin
                rw_select <= 1;
                if(store_op == `SW)begin
                    if(store_cnt == 2'b11) begin
                        ram_store_data <= store_data[7:0];
                       // $fdisplay(logfile,"sw: clk: %d addr: %08x data: %08x",$realtime,addr_record,store_data);
                    end
                    else if(store_cnt == 2'b10) ram_store_data <= store_data[15:8];
                    else if(store_cnt == 2'b01) ram_store_data <= store_data[23:16];
                    else begin
                        ram_store_data <= store_data[31:24];
                        is_storing <= `FALSE;
                        store_finish <= `TRUE;
                        controller_is_idle <= `TRUE;
                    end
                    addr_in <= addr_record;
                    addr_record <= addr_record + 1;
                    store_cnt <= store_cnt - 1;
                end
                else if(store_op == `SH)begin
                    if(store_cnt == 2'b01) ram_store_data <= store_data[7:0];
                    else begin
                    ram_store_data <= store_data[15:8];
                    is_storing <= `FALSE;
                    store_finish <= `TRUE;
                    controller_is_idle <= `TRUE;
                end
                addr_in <= addr_record;
                addr_record <= addr_record + 1;
                store_cnt <= store_cnt - 1;
                end
                else if(store_op == `SB)begin
                 //   $fdisplay(logfile,"sb: clk: %d addr: %08x data: %08x",$realtime,addr_record,store_data);
                    ram_store_data <= store_data[7:0];
                    addr_in <= addr_record;
                    is_storing <= `FALSE;
                    store_finish <= `TRUE;
                    controller_is_idle <= `TRUE;
                end
            end
            
            if(is_fetching && icache_hit == `FALSE)begin
                if(fetch_cnt == 3'b100)begin  end
                else if(fetch_cnt == 3'b011) fetch_instruct[7:0] <= ram_load_data;
                else if(fetch_cnt == 3'b010) fetch_instruct[15:8] <= ram_load_data;
                else if(fetch_cnt == 3'b001) fetch_instruct[23:16] <= ram_load_data;
                else begin
                    fetch_instruct[31:24] <= ram_load_data;
                    is_fetching <= `FALSE;
                    fetch_finish <= `TRUE;
                    controller_is_idle <= `TRUE;
                end
                fetch_cnt <= fetch_cnt - 1; 
                addr_in <= addr_in + 1;
            end
            else if(is_fetching && icache_hit == `TRUE)begin
                fetch_instruct <= icache_hit_inst;
                is_fetching    <= `FALSE;
                fetch_finish   <= `TRUE;
                controller_is_idle <= `TRUE;
            end

        end
        end
    end   
endmodule

