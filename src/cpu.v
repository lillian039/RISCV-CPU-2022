// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "operaType.v"
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			    dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    //lsb
    wire                    lsb_load;
    wire    [`ADDR_RANGE]   load_address;
    wire    [5:0]           op_type_load;
    wire                    finish_load;
    wire    [31:0]          get_load_data;

    wire                    lsb_store;
    wire    [`ADDR_RANGE]   store_address;
    wire    [5:0]           op_type_store;
    wire                    finish_store;
    wire    [31:0]          get_store_data;

    wire                    lsb_is_full;
    wire                    ins_to_lsb;

    wire                    lsb_load_broadcast;
    wire    [31:0]          lsb_load_result;
    wire    [`ENTRY_RANGE]  lsb_load_entry_out;

    wire                    lsb_store_broadcast;
    wire    [`ENTRY_RANGE]  lsb_store_entry_out;

    //rs
    wire                    rs_is_full;
    wire                    ins_to_rs;

    wire                    rs_broadcast;
    wire    [`ENTRY_RANGE]  rs_entry;
    wire    [31:0]          rs_value;
    wire    [31:0]          rs_pc_result;
    wire                    rs_new_calculate;


    //i fetch
    wire                    fetch_start;
    wire    [31:0]          fetch_pc;
    wire                    finish_fetch;
    wire    [31:0]          fetch_instruct_out;
    wire    [31:0]          fetch_instruct_pc_out;

    //isq
    wire    [31:0]          instruction_isq;
    wire    [31:0]          isq_pc_out;

    //memory controller
    wire                    is_idle;//seems unused?

    //btb
    wire                    roll_back;

    //rob
    wire                    rob_commit;
    wire    [31:0]          rob_pc_commit;
    wire    [5:0]           rob_op_commit;
    wire    [2:0]           rob_op_type;
    wire    [31:0]          rob_result;
    wire    [31:0]          rob_pc_result_commit;
    wire    [`ENTRY_RANGE]  rob_entry_commit;
    wire    [5:0]           rob_des_commit;

    wire                    rob_is_full;
    wire                    ins_to_rob;
    wire    [4:0]           rob_head;
    wire    [`ENTRY_RANGE]  rob_new_entry;

    //decoder
    wire    [31:0]          imm_decoder;
    wire    [5:0]           op_decoder;
    wire    [5:0]           rs1_decoder;
    wire    [5:0]           rs2_decoder;
    wire    [5:0]           rd_decoder;
    wire    [2:0]           op_type_decoder;    

    //reg file
    wire    [`ENTRY_RANGE]  Qj;
    wire    [`ENTRY_RANGE]  Qk;
    wire    [31:0]          Vj;
    wire    [31:0]          Vk;

    memory_controller mem_controller(
      .clk_in               (clk_in),
      .rst_in               (rst_in),
      .rdy_in               (rdy_in),
      .io_buffer_full       (io_buffer_full),

      .roll_back            (roll_back),

      .rw_select            (mem_wr),
      .ram_store_data       (mem_dout),
      .ram_load_data        (mem_din),
      .addr_in              (mem_a),

      .lsb_load             (lsb_load),
      .load_address         (load_address),
      .op_type_load         (op_type_load),
      .get_load_data        (get_load_data),
      .finished_load        (finish_load),


      .lsb_store            (lsb_store),
      .store_address        (store_address),
      .op_type_store        (op_type_store),
      .get_store_data       (get_store_data),
      .finished_store       (finish_store),

      .fetch_start          (fetch_start),
      .pc                   (fetch_pc),
      .finish_fetch         (finish_fetch),
      .instruction_out      (fetch_instruct_out),
      .instruction_pc_out   (fetch_instruct_pc_out),

      .is_idle              (is_idle)
    );    

    IF instruction_fetch(
      .clk_in               (clk_in),
      .rst_in               (rst_in),
      .rdy_in               (rdy_in),

      .rob_commit           (rob_commit),
      .rob_pc_commit        (rob_pc_commit),
      .rob_op_commit        (rob_op_commit),
      .rob_op_type          (rob_op_type),
      .rob_result           (rob_result),
      .rob_pc_result        (rob_pc_result_commit),

      .rob_is_full          (rob_is_full),
      .ins_to_rob           (ins_to_rob),

      .rs_is_full           (rs_is_full),
      .ins_to_rs            (ins_to_rs),

      .lsb_is_full          (lsb_is_full),
      .ins_to_lsb           (ins_to_lsb),

      .is_idle              (is_idle),
      .finish_fetch         (finish_fetch),
      .instruction_in       (fetch_instruct_out),
      .instruction_pc_in    (fetch_instruct_pc_out),

      .pc_out               (fetch_pc),
      .fetch_start          (fetch_start),

      .instruction_out      (instruction_isq),
      .isq_pc_out           (isq_pc_out),

      .roll_back_out        (roll_back)
    );

    decoder decoder(
      .op_in                (instruction_isq),

      .imm_out              (imm_decoder),
      .op_out               (op_decoder),
      .rs1                  (rs1_decoder),
      .rs2                  (rs2_decoder),
      .rd                   (rd_decoder),
      .op_type              (op_type_decoder)
    );

    register regFile(
      .clk                  (clk_in),
      .rst_in               (rst_in),
      .rdy_in               (rdy_in),

      .roll_back            (roll_back),

      .rob_commit           (rob_commit),
      .rob_entry            (rob_entry_commit),
      .rob_des              (rob_des_commit),
      .rob_result           (rob_result),

      .rs_broadcast         (rs_broadcast),
      .rs_entry             (rs_entry),
      .rs_result            (rs_value),

      .lsb_broadcast        (lsb_load_broadcast),
      .lsb_entry            (lsb_load_entry_out),
      .lsb_result           (lsb_load_result),

      .rob_new_entry        (rob_new_entry),
      .new_issue            (ins_to_rob),

      .rs1_in               (rs1_decoder),
      .rs2_in               (rs2_decoder),
      .rd_in                (rd_decoder),

      .Qj                   (Qj),
      .Qk                   (Qk),
      .Vj                   (Vj),
      .Vk                   (Vk)
    );

    load_store_buffer LSB(
      .clk_in               (clk_in),
      .rst_in               (rst_in),
      .rdy_in               (rdy_in),

      .pc_now_in            (isq_pc_out),
      .get_instruction      (ins_to_lsb),
      .instruction_in       (instruction_isq),
      .entry_in             (rob_new_entry),

      .roll_back            (roll_back),

      .Vj_in                (Vj),
      .Vk_in                (Vk),
      .Qj_in                (Qj),
      .Qk_in                (Qk),

      .imm_in               (imm_decoder),
      .op_in                (op_decoder),
      .op_type_in           (op_type_decoder),

      .is_full_out          (lsb_is_full),

      .rs_broadcast         (rs_broadcast),
      .rs_entry             (rs_entry),
      .rs_value             (rs_value),

      .rob_commit           (rob_commit),
      .rob_entry_commit     (rob_entry_commit),
      .rob_op_type_commit   (rob_op_type),
      .rob_result_out       (rob_result),

      .rob_head             (rob_head),

      .lsb_load_broadcast   (lsb_load_broadcast),
      .load_result          (lsb_load_result),
      .load_entry_out       (lsb_load_entry_out),

      .lsb_store_broadcast  (lsb_store_broadcast),
      .store_entry_out      (lsb_store_entry_out),

      .finish_store         (finish_store),
      .data_store           (get_store_data),
      .lsb_store            (lsb_store),
      .store_address        (store_address),
      .op_type_store        (op_type_store),

      .finish_load          (finish_load),
      .data_load            (get_load_data),
      .lsb_load             (lsb_load),
      .load_address         (load_address),
      .op_type_load         (op_type_load)
    );

    wire  [5:0]           rs_op_out;
    wire  [31:0]          rs_instruct_out;
    wire  [31:0]          rs_vj_out;
    wire  [31:0]          rs_vk_out;
    wire  [31:0]          rs_imm_out;
    wire  [31:0]          rs_pc_out;
    wire  [`ENTRY_RANGE]  rs_entry_out;

    wire                      alu_broadcast;
    wire  [`ENTRY_RANGE]      alu_entry;
    wire  [31:0]              alu_value;
    wire  [31:0]              alu_pc_out;


    reservation_station RS(
      .clk_in               (clk_in),
      .rst_in               (rst_in),
      .rdy_in               (rdy_in),

      .pc_now_in            (isq_pc_out),
      .get_instruction      (ins_to_rs),
      .instruction_in       (instruction_isq),
      .entry_in             (rob_new_entry),

      .roll_back            (roll_back),

      .Vj_in                (Vj),
      .Vk_in                (Vk),
      .Qj_in                (Qj),
      .Qk_in                (Qk),

      .imm_in               (imm_decoder),
      .op_in                (op_decoder),
      .rd_in                (rd_decoder),

      .is_full_out          (rs_is_full),

      .new_calculate        (rs_new_calculate),
      .rs_op_out            (rs_op_out),
      .rs_instruct_out      (rs_instruct_out),
      .rs_vj_out            (rs_vj_out),
      .rs_vk_out            (rs_vk_out),
      .rs_imm_out           (rs_imm_out),
      .rs_pc_out            (rs_pc_out),
      .rs_entry_out         (rs_entry_out),

      .lsb_broadcast        (lsb_load_broadcast),
      .lsb_entry            (lsb_load_entry_out),
      .lsb_value            (lsb_load_result),

      .alu_broadcast        (alu_broadcast),
      .alu_entry            (alu_entry),
      .alu_value            (alu_value),
      .alu_pc_out           (alu_pc_out),

      .rob_commit           (rob_commit),
      .rob_entry            (rob_entry_commit),
      .rob_result           (rob_result),

      .rs_broadcast         (rs_broadcast),
      .rs_entry             (rs_entry),
      .rs_result            (rs_value),
      .rs_pc_result         (rs_pc_result)
    );    

    alu rs_alu(
      .new_calculate        (rs_new_calculate),
      .instruction          (rs_instruct_out),
      .op                   (rs_op_out),
      .vj                   (rs_vj_out),
      .vk                   (rs_vk_out),
      .pc                   (rs_pc_out),
      .imm                  (rs_imm_out),
      .entry                (rs_entry_out),

      .alu_broadcast        (alu_broadcast),
      .alu_result           (alu_value),
      .alu_pc_out           (alu_pc_out),
      .alu_entry            (alu_entry)
    );

    reorder_buffer ROB(
      .clk_in               (clk_in),
      .rst_in               (rst_in),
      .rdy_in               (rdy_in),

      .rob_is_full          (rob_is_full),
      .cur_entry            (rob_new_entry),
      .roll_back            (roll_back),

      .finish_store         (finish_store),

      .get_instruction      (ins_to_rob),
      .isq_ins_in           (instruction_isq),
      .isq_pc_in            (isq_pc_out),

      .rd_in                (rd_decoder),
      .op_type_in           (op_type_decoder),
      .op_in                (op_decoder),

      .rob_commit           (rob_commit),
      .rob_pc_commit        (rob_pc_commit),
      .rob_pc_result_commit (rob_pc_result_commit),
      .rob_op_commit        (rob_op_commit),
      .rob_op_type_commit   (rob_op_type),
      .rob_result_out       (rob_result),
      .rob_entry_commit     (rob_entry_commit),
      .rob_des_commit       (rob_des_commit),

      .rs_broadcast         (rs_broadcast),
      .rs_result            (rs_value),
      .rs_pc_in             (rs_pc_result),
      .rs_entry             (rs_entry),

      .lsb_broadcast        (lsb_load_broadcast),
      .lsb_result           (lsb_load_result),
      .lsb_entry            (lsb_load_entry_out),

      .rob_head_out         (rob_head),

      .lsb_store_addressed  (lsb_store_broadcast),
      .lsb_store_entry      (lsb_store_entry_out)

    );



endmodule