module i_cache#(
)
(
  input     wire                   clk_in,      // system clock
  input     wire                   rst_in,	    // reset signal
  input     wire				           rdy_in,		  // ready signal, pause cpu when low
  input     wire                   get_addr,    // whether isq is full to get 
  input     wire  [31:0]           pc_addr,     // memory address
  output    wire                   miss         // whether hit
  output    wire  [31:0]           instruction, // get new instruction
);
parameter   ICACHESIZE=64;
reg         hit_i_cache;
reg [31:0]  instructions_in_cache   [ICACHESIZE-1:0]; //63个icache的位置 要按什么逻辑做cache 不如直接遍历(感觉64个也不多)  cache的index是什么？
reg         empty                   [ICACHESIZE-1:0]; //是否有值？ 
reg [31:0]  pc_in_cache             [ICACHESIZE-1:0]; //不如暂时拿pc作为index
reg [31:0]  instruction_new;
integer     i;
reg         whether_miss;

assign miss = whether_miss;
assign instruction = instruction_new;

always @(posedge clk_in) begin
    if(rst_in)begin//清空icache
      for (i= 0; i<ICACHESIZE ; i=i+1)begin
        empty[i]=TRUE;
      end

    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
      whether_miss=FALSE;
       for (i= 0; i<ICACHESIZE ; i=i+1)begin
        if(empty[i]==TRUE)begin
          if(get_addr == pc_in_cache[i])begin
            whether_miss<=FALSE;
            instruction_new<=instructions_in_cache[i];
            whether_miss=TRUE;
          end
        end
       end
    end

end

endmodule