module IF(
     input wire clk_in,// system clock signal
    input wire rst_in,// reset signal
    input wire rdy_in,// ready signal, pause cpu when low
);

reg [31:0] instruction_fetch_new;
reg [31:0] instruction_isq_top;
reg isq_is_full;
reg isq_has_data;
reg [31:0]pc_reg;



instruction_queue ISQ(
    .clk_in (clk_in),
    .rst_in (rst_in),
    .rdy_in (rdy_in),
    .instruction_in (instruction_fech_new),
    .instruction_out (instruction_isq_top),
    .is_full(isq_is_full),
    .has_data(isq_has_data)
    );



endmodule