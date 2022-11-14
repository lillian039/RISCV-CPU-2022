module i_cache#(
  parameter ADDR_WIDTH = 17
)
(
  input     wire                   clk_in,      // system clock
  input     wire                   rst_in,	    // reset signal
  input     wire				           rdy_in,		// ready signal, pause cpu when low
  input     wire                   get_addr,    //whether isq is full to get 
  input     wire  [ADDR_WIDTH-1:0] a_in,        // memory address
  input     wire  [ 7:0]           d_in,        // data input
  output    wire  [ 7:0]           d_out ,      // data output
  output    wire                   hit          //whether hit
);
parameter   ICACHESIZE=64;
reg         hit_i_cache;
reg [31:0]  instructions_in_cache   [ICACHESIZE-1:0]; //63个icache的位置 要按什么逻辑做cache 不如直接遍历(感觉64个也不多)
reg         empty                   [ICACHESIZE-1:0]; //是否有值？ 

always @(posedge clk_in) begin
    if(rst_in)begin//清空isq

    end

    else if(!rdy_in)begin//低信号 pause

    end

    else begin 
       
    end

end

endmodule