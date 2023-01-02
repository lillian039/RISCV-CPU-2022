`include "operaType.v"
module register
#(
    parameter REG_NUM = 32,
    parameter ENTRY_SIZE = 4
)
(
    input   wire                        clk,
    input   wire                        rst_in,
    input   wire                        rdy_in,

    //predict wrong
    input   wire                        roll_back,
    //rob signal    
    //commit part
    input   wire                        rob_commit,
    input   wire    [`ENTRY_RANGE]      rob_entry,
    input   wire    [`ENTRY_RANGE]      rob_des,
    input   wire    [31:0]              rob_result,

    //rs broadcast
    input   wire                        rs_broadcast,
    input   wire    [`ENTRY_RANGE]      rs_entry,
    input   wire    [31:0]              rs_result,

    //lsb broadcast
    input   wire                        lsb_broadcast,
    input   wire    [`ENTRY_RANGE]      lsb_entry,
    input   wire    [31:0]              lsb_result,

    //issue part
    input   wire    [`ENTRY_RANGE]      rob_new_entry,
    input   wire                        new_issue,

    //decoder
    input   wire    [5:0]               rs1_in,
    input   wire    [5:0]               rs2_in,
    input   wire    [5:0]               rd_in,

    //rs
    output  wire    [`ENTRY_RANGE]      Qj,
    output  wire    [`ENTRY_RANGE]      Qk,
    output  wire    [31:0]              Vj,
    output  wire    [31:0]              Vk
);
    
    reg     [31:0]      value      [REG_NUM-1:0];
    reg     [31:0]      reorder    [REG_NUM-1:0];
    reg                 busy       [REG_NUM-1:0];     

    integer i;

    assign Qj = rs1_in == `NULL ? `ENTRY_NULL : busy[rs1_in] ? reorder[rs1_in] : `ENTRY_NULL;
    assign Qk = rs2_in == `NULL ? `ENTRY_NULL : busy[rs2_in] ? reorder[rs2_in] : `ENTRY_NULL;
    assign Vj = rs1_in == `NULL ?  0 : busy[rs1_in] ? 31'd0  : value[rs1_in];
    assign Vk = rs2_in == `NULL ?  0 : busy[rs2_in] ? 31'd0  : value[rs2_in];

    wire    [`ENTRY_RANGE]  debug_0_reorder = reorder[0];
    wire    [31:0]          debug_0_value = value[0];

    wire    [31:0]          debug_1_value = value[1];

    wire    [31:0]          debug_2_value = value[2];



    wire   [`ENTRY_RANGE]  debug_11_reorder = reorder[11];
    wire   [31:0]          debug_11_value   = value[11];

    wire   [`ENTRY_RANGE]  debug_15_reorder = reorder[15];
    wire   [31:0]          debug_15_value   = value[15];

    // integer logfile;
    // initial begin
    //     logfile = $fopen("reg.log","w");
    // end

    always @ (posedge clk) begin
        if(rst_in == `TRUE)begin//清空
            for(i = 0; i < REG_NUM; i = i + 1)begin
                busy[i]     <= `FALSE;
                reorder[i]  <= `ENTRY_NULL;
                value[i]    <= 0;
            end
        end
        else if(!rdy_in)begin//低信号 pause

        end
        else if(roll_back == `TRUE)begin
            // if(rob_commit)begin
            //   $fdisplay(logfile,"clk: %d reg[12]: %08x reg[15]: %08x reg[16]: %08x",$realtime,value[12],value[15],value[16]);
            // end
            for(i = 0; i < REG_NUM; i = i + 1)begin
                busy[i]     <= `FALSE;
                reorder[i]  <= `ENTRY_NULL;
                if(i == rob_des && rob_des != `ENTRY_NULL && rob_des != 0)begin
                    value[i] <= rob_result;
                end
            end
        end

        else begin
        if (new_issue && rd_in != `NULL && rd_in != 0)begin
            // if(rob_new_entry == 32'h0000001d)begin
            //     $fdisplay(logfile,"clk: %d!!!",$realtime);
            // end
            reorder[rd_in] <= rob_new_entry;
            busy   [rd_in] <= `TRUE;
        end

        //if(rob_commit)$fdisplay(logfile,"clk: %d reg[12]: %08x reg[15]: %08x reg[16]: %08x",$realtime,value[12],value[15],value[16]);
        if (rob_commit && rob_des != `NULL && rob_des != 0 )begin
            value[rob_des] <= rob_result;
            if(reorder[rob_des] == rob_entry)begin
                busy [rob_des] <= `FALSE;
                reorder [rob_des] <= `ENTRY_NULL;
            end
        end
        end
        
    end

endmodule