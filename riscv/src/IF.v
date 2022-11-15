module IF(
    parameter ADDR_WIDTH = 17
    input   wire                        clk_in,         // system clock signal
    input   wire                        rst_in,         // reset signal
    input   wire                        rdy_in,         // ready signal, pause cpu when low
    input   wire    [7:0]               instruction_ram,// instruction get in ram 位宽为8 要分三次传送
    input   wire                        memory_ready,   // get instruction from ram
    output  wire                        get_memory,     // icache_miss
    output  wire    [ADDR_WIDTH-1:0]    pc_ram,         // get instruction in ram 
);

reg     [31:0]      pc_reg;

reg     [3:0]       memory_send_times;  //受位宽限制，要分4次送数据
reg                 addr_send_times;    //受位宽限制，要分2次送地址

reg     [31:0]      instruction_fetch_new;
reg                 cache_miss;


assign pc_ram = pc_reg;
assign get_memory = cache_miss;

wire    [31:0]      isq_instruction_out;
wire                isq_is_full;
wire                isq_is_sending;
wire                rob_is_full;
reg                 instruction_ready;

wire                if_run_btb_jump;                //是否启动判断btb要不要jump
wire                if_run_btb_judge_change_state;  //是否启动判断btb要不要change state
wire                btb_jump_result;                //旧的 pc 的真实判断结果
wire    [31:0]      btb_jump_des;                   //新pc预测要jump到哪
wire    [31:0]      btb_change_state_des;           //旧pc的地址
wire                whether_jump_result;            //预测pc是否要跳转

i_cache icache(
    .clk_in             (clk_in),
    .rst_in             (rst_in),
    .rdy_in             (rdy_in),
    .get_addr           (pc_reg),
    .miss               (cache_miss),
    .instruction        (instruction_fetch_new),
);



instruction_queue ISQ(
    .clk_in             (clk_in),
    .rst_in             (rst_in),
    .rdy_in             (rdy_in),
    .instruction_ready  (instruction_ready),
    .instruction_in     (instruction_fetch_new),
    .rob_is_full        (rob_is_full),
    .instruction_out    (isq_instruction_out),
    .is_full            (isq_is_full),
    .is_sending         (isq_is_sending)
);

branch_target_buffer BTB(
    .clk_in             (clk_in),
    .rst_in             (rst_in),
    .rdy_in             (rdy_in),
    .judge_btb          (if_run_btb_jump),
    .change_state       (if_run_btb_judge_change_state),
    .result             (btb_jump_result),
    .judge_jump_pc_in   (btb_jump_des),
    .change_state_pc_in (btb_change_state_des),
    .jump_out           (whether_jump_result),
);

always @(posedge clk_in) begin
    if(rst_in)begin//清空

    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
        if(cache_miss == TRUE)begin
            instruction_ready=FALSE;
        end
        if (whether_jump == TRUE)begin
            pc_reg=btb_jump_des;
        end
        else pc_reg <= pc_reg + 4;
    end

end


endmodule