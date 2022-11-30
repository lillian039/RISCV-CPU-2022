module load_store_buffer
#(
    parameter LOAD_TIME = 3;
)
(
    input   wire                    clk_in,// system clock signal
    input   wire                    rst_in,// reset signal
    input   wire                    rdy_in,// ready signal, pause cpu when low
    
    input   wire                    pc_now_in,
    input   wire                    is_storing,
    input   wire                    getInstruct;
    input   wire  [31:0]            instruction_in,
    input   wire  [LOAD_TIME-1:0]   loading,
    output  wire  [31:0]            instruction_out,
    output  wire                    is_full_out
);
parameter LSB_SIZE=32;
reg [3:0]       state    [LSB_SIZE-1:0];
reg [31:0]      Vj       [LSB_SIZE-1:0];
reg [31:0]      Vk       [LSB_SIZE-1:0];  
reg [31:0]      Qj       [LSB_SIZE-1:0];     //0 empty
reg [31:0]      Qk       [LSB_SIZE-1:0];
reg [31:0]      A        [LSB_SIZE-1:0];
reg [31:0]      Op       [LSB_SIZE-1:0];
reg [31:0]      result   [LSB_SIZE-1:0];
reg [31:0]      des      [LSB_SIZE-1:0];
reg [31:0]      rs_clock [LSB_SIZE-1:0];
reg [31:0]      address  [LSB_SIZE-1:0];

integer i;
reg     [6:0]       opcode;
reg     [4:0]       rs1;
reg     [4:0]       rs2;
reg     [4:0]       rd;
assign instruction_in [6:0] = opcode;
rs1 = op[19:15];
rs2 = op[24:20];

always @(posedge clk ) begin
    if(rst_in)begin//清空
        for(i = 0;i < LSB_SIZE;i = i + 1)begin
            state[i]=Empty;
        end
    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 

        //issue part
        if( getInstruct )begin
        i=0;
        while(!(state[i]==Empty))begin
            i=i+1;
        end
        des[i] <= entry_in;
        state[i] <= Waiting;
        op[i] <= instruction_in;
        rs_pc[i] <= pc_now_in;
        Qj[i] <= 0;
        Qk[i] <= 0;
        if (opcode == 7'b010011)begin      //STORE
            A[i][11:5] <= op[31:25];
            A[i][4:0] <= op[11:7];
            if(op[31] == 1'b1) A[i][31:12] <= ~A[i][31:12];
            else A[i][31:20] <= 0;
            //signed extend
        end
        else if (opcode == 7'b0000011) begin  //LOAD
            A [i] <= 0;
            A[i][11:0] <= op [31:20];
            if(op[31] == 1'b1) A[i][31:20] <= ~A[i][31:20];
            else A[i][31:20] <= 0; 
        end
        if(register_busy[rs1])begin
            if(rob_ready[register_reorder[rs1]-1]) Vj[i] <= rob_value[register_reorder[rs1]-1]; // h 得是 1 base 的
            else Qj[i] <= register_reorder[rs1];
        end
        else Vj[i] <= register_value[rs1];
        if (opcode == 7'b010011)begin
            if(register_busy[rs1])
            begin
            if(rob_ready[register_reorder[rs2]-1]) Vk[i] <= rob_value[register_reorder[rs2]-1]; // h 得是 1 base 的
            else Qk[i] <= register_reorder[rs2];
            end
            else Vj[i] <= register_value[rs1];

        end

        //execute part
        //be very complicated
        if(loading!=1'b1)begin

        end

    end
    end

end

endmodule