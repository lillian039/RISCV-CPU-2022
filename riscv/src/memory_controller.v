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
    output  wire                    r_new_in,
    output  reg    [7:0]            d_in,
    input   wire   [7:0]            d_out,
    output  wire   [ADDR_WIDTH-1:0] addr_in,

    //lsb
    input   wire                    lsb_load,
    input   wire    [31:0]          load_address,
    output  wire                    finished_load,
    output  wire    [31:0]          get_load_data,

    input   wire                    lsb_store,
    input   wire    [31:0]          store_adress,
    input   wire    [31:0]          get_store_data,
    output  wire                    finished_store,

    //fetch
    input   wire    [31:0]          pc,
    output  wire                    get_instruction,
    output  wire    [31:0]          instruction_out,

    output  wire                    is_idle
);

    reg             send_addr;
    reg     [1:0]   send_d_in;
    reg     [1:0]   send_d_out;

    reg             is_loading;
    reg             is_storing;
    reg             is_fetching;

    reg     [31:0]  load_data;
    reg     [31:0]  store_data;

    assign  is_idle = !is_loading && !is_storing && !is_fetching;

    always @(posedge clk_in)  begin
        if(rst_in)begin//清空
            is_loading <= `FALSE;
            is_storing <= `FALSE;
            is_fetching <= `FALSE;
        end
        else if(!rdy_in)begin//低信号 pause

        end
        else begin
            if(is_loading == `TRUE)begin
                if(send_d_out == 2'b11) load_data[31:24] <= d_out;
                else if(send_d_out == 2'b10) load_data[23:16] <= d_out;
                else if(send_d_out == 2'b01) load_data[15:8] <= d_out;
                else begin
                    load_data[7:0] <= d_out;
                    is_loading <= `FALSE;
                end
                send_d_in <= send_d_out - 1; 
            end

            if(is_storing == `TRUE)begin
                if(send_d_in == 2'b11) d_in <= store_data[31:24];
                else if(send_d_in == 2'b10) d_in <= store_data[23:16];
                else if(send_d_in == 2'b01) d_in <= store_data[15:8];
                else begin
                    d_in <= store_data[7:0];
                    is_storing <= `FALSE;
                end
            end
            
            if(is_fetching)begin

            end

        end
    end   
endmodule

