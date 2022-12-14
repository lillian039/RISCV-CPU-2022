`include "operaType.v"
module alu(
    input   wire                clk_in,// system clock signal
    input   wire                rst_in,// reset signal
    input   wire                rdy_in,// ready signal, pause cpu when low

    input   wire                rs_new_calculate,
    input   wire    [6:0]       opcode,
    input   wire    [31:0]      rs_instruction,
    input   wire    [5:0]       rs_op,   
    input   wire    [31:0]      rs_vj,
    input   wire    [31:0]      rs_vk,
    input   wire    [31:0]      rs_pc,
    input   wire    [31:0]      rs_imm,
    input   wire    [`ENTRY_RANGE]  rs_des,
    
    //broadcast
    output  wire                alu_broadcast,
    output  reg     [31:0]      alu_result,
    output  reg     [31:0]      alu_pc_out,
    output  wire    [`ENTRY_RANGE]  alu_entry
    );

    wire            [4:0]     shamp;
    assign shamp = rs_instruction [24:20];

    assign alu_broadcast = rs_new_calculate;
    assign alu_entry = rs_des;

    always @(*) begin
    case (rs_op)
    //B format
    `BEQ:   
    begin 
        if(rs_vj == rs_vk)begin
        alu_result  = 1;
        alu_pc_out  = rs_pc + rs_imm;
        end
        else alu_result  = 0;
    end
    `BNE: 
    begin
        if(rs_vj != rs_vk)begin
        alu_result  = 1;
        alu_pc_out  = rs_pc + rs_imm;
        end
        else alu_result  = 0;
    end
    `BLT:
    begin
        if($signed(rs_vj) < $signed(rs_vk))begin
        alu_result  = 1;
        alu_pc_out  = rs_pc + rs_imm;
        end
        else alu_result  = 0;
    end
    `BGE:
    begin
        if($signed(rs_vj) >= $signed(rs_vk))begin
        alu_result  = 1;
        alu_pc_out  = rs_pc + rs_imm;
        end
        else alu_result  = 0;
    end
     `BLTU:
    begin
        if(rs_vj < rs_vk)begin
        alu_result  = 1;
        alu_pc_out  = rs_pc + rs_imm;
        end
        else alu_result  = 0;
    end
    `BGEU:
    begin
        if(rs_vj >= rs_vk)begin
        alu_result  = 1;
        alu_pc_out  = rs_pc + rs_imm;
        end
        else alu_result  = 0;
    end
    `JAL:
    begin
            alu_result  = rs_pc + 4;
            alu_pc_out  = rs_pc + rs_imm;
    end
    //I format
    `JALR:
    begin
            alu_result  = rs_pc + 4;
            alu_pc_out  = rs_vj + rs_imm;
    end
    `ANDI:  alu_result  = rs_vj + rs_imm;   
    `SLTI:  alu_result  = ($signed(rs_vj) < $signed(rs_imm));
    `SLTIU: alu_result  = (rs_vj < rs_imm);
    `XORI:  alu_result  = (rs_vj ^ rs_imm);
    `ORI:   alu_result  = (rs_vj | rs_imm);
    `ANDI:  alu_result  = (rs_vj & rs_imm);
    `SLLI:  alu_result  = (rs_vj << shamp);
    `SRLI:  alu_result  = (rs_vj >> shamp);
    `SRAI:  alu_result  = (rs_vj >>> shamp);
    //R format
    `ADD:   alu_result  = rs_vj + rs_vk;
    `SUB:   alu_result  = rs_vj - rs_vk;
    `SLL:   alu_result  = (rs_vj << rs_vk);
    `SLT:   alu_result  = ($signed(rs_vj) < $signed(rs_vk));
    `SLTU:  alu_result  = (rs_vj < rs_vk);
    `XOR:   alu_result  = (rs_vj ^ rs_vk);
    `SRL:   alu_result  = (rs_vj >> rs_vk);
    `SRA:   alu_result  = (rs_vj >>> rs_vk);
    `OR:    alu_result  = (rs_vj | rs_vk);
    `AND:   alu_result  = (rs_vj & rs_vk);
    //U format
    `LUI: alu_result  = rs_imm;
    `AUIPC: alu_result  = rs_imm + rs_pc;
    endcase
    end
  
endmodule
