module instruction_queue(
    input  wire                   clk_in,   // system clock
    input  wire  [31:0]                 instruction_in,    // 32 width instruction
    output wire [31:0]                  instruction_out,
    output wire             is_full,     // whether instrutcion queue is full
);

endmodule