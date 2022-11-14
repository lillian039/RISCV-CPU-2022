`define    stronglyNotTaken     2'b00;
`define    weaklyNotTaken       2'b01;
`define    weaklyTaken          2'b10;
`define    stronglyTaken        2'b11;

module branch_target_buffer(
    input   wire            clk_in,                 //  system clock signal
    input   wire            rst_in,                 //  reset signal
    input   wire            rdy_in,                 //  ready signal, pause cpu when low
    input   wire            judge_btb,              //  whether jump
    input   wire            change_state,           //  whether change state
    input   wire            result,                 //change pc result
    input   wire    [31:0]  judge_jump_pc_in,       //whether pc need jump
    input   wire    [31:0]  change_state_pc_in,     //change pc state
    output  wire            jump_out,         
);
parameter   BTBSIZE=64;
parameter prime=337;
reg [3:0]   btb_single  [BTBSIZE-1:0];

integer i;
integer hash_idx_jump;
integer hash_idx_change;
reg     whether_jump;
assign  jump_out=whether_jump;
always @(posedge clk_in) begin
    if (rst_in)begin//清空btb
    for(i=0;i<BTBSIZE;i=i+1)begin
        btb_single[i]=weaklyNotTaken;
    end
    end
    else if(!rdy_in)begin//低信号或没有需要判断的jump  pause
    end
    else begin
    if (judge_btb)begin 
        hash_idx_jump=(judge_jump_pc_in*prime)%BTBSIZE;
        if(btb_single[hash_idx_jump]==weaklyTaken||btb_single[hash_idx_jump]==stronglyTaken)whether_jump=TRUE;
        else whether_jump=FALSE;
    end
    if (change_state)begin
        hash_idx_change=(change_state_pc_in*prime)%BTBSIZE;
        if(result==TRUE && btb_single[hash_idx_change]!=stronglyTaken) btb_single[hash_idx_change] = btb_single[hash_idx_change]+1;
        else if(result==FALSE && btb_single[hash_idx_change]!=stronglyNotTaken) btb_single[hash_idx_change] = btb_single[hash_idx_change]-1;
    end

    end

end
endmodule
