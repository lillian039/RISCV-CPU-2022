module register
#(
    parameter REG_NUM = 32;
    parameter ENTRY_SIZE = 4;
)
(
    input wire clk,
    input wire rst,

    input   wire                        write_enable,
    input   wire [ENTRY_SIZE-1 : 0]     write_addr,
    input   wire [31 : 0]               write_data,

    input   wire                        read_enable,   
    input   wire [ENTRY_SIZE-1 : 0]     read_addr,
    output  reg  [31 : 0]               read_data,

    input   wire                        set_reorder;
    input   wire [ENTRY_SIZE-1:0]       set_reorder_number;
    input   wire [ENTRY_SIZE-1:0]       set_reorder_entry;
    );
    
    reg     [31:0]      value      [REG_NUM-1:0];
    reg     [31:0]      reorder    [REG_NUM-1:0];
    reg                 busy       [REG_NUM-1:0];     

    integer i;
//write
always @ (posedge clk) begin
     if(rst_in)begin//清空
        for(i = 0;i < LSB_SIZE;i = i + 1)begin
            busy[i] = 1'b0;
        end
    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin
        if (set_reorder == TRUE)begin
            busy[set_reorder_number] =  TRUE;
            reorder = set_reorder_entry;
        end
    end
end
endmodule