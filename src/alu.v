`include "operaType.v"
module alu(
    input   wire                    new_calculate,
    input   wire    [31:0]          instruction,
    input   wire    [5:0]           op,  //64 
    input   wire    [31:0]          vj,
    input   wire    [31:0]          vk,
    input   wire    [31:0]          pc,
    input   wire    [31:0]          imm,
    input   wire    [`ENTRY_RANGE]  entry,
    
    //broadcast
    output  wire                    alu_broadcast,
    output  reg     [31:0]          alu_result,
    output  reg     [31:0]          alu_pc_out,
    output  wire    [`ENTRY_RANGE]  alu_entry
    );

    wire            [4:0]     shamp;
    assign shamp = instruction [24:20];

    assign alu_broadcast = new_calculate;
    assign alu_entry = entry;

    always @(*) begin
   // $display("alu");
    case (op)
    //B format
    `BEQ:   
    begin 
        if(vj == vk)begin
            alu_result  = 1;
            alu_pc_out  = pc + imm;
        end
        else begin
            alu_result  = 0;
            alu_pc_out = pc + 4;
        end
    end
    `BNE: 
    begin
        if(vj != vk)begin
            alu_result  = 1;
            alu_pc_out  = pc + imm;
        end
        else begin
            alu_result  = 0;
            alu_pc_out = pc + 4;
        end
    end
    `BLT:
    begin
        if($signed(vj) < $signed(vk))begin
            alu_result  = 1;
            alu_pc_out  = pc + imm;
        end
        else begin
            alu_result  = 0;
            alu_pc_out = pc + 4;
        end
    end
    `BGE:
    begin
        if($signed(vj) >= $signed(vk))begin
            alu_result  = 1;
            alu_pc_out  = pc + imm;
        end
        else begin
            alu_result  = 0;
            alu_pc_out = pc + 4;
        end
    end
     `BLTU:
    begin
        if(vj < vk)begin
            alu_result  = 1;
            alu_pc_out  = pc + imm;
        end
        else begin
            alu_result  = 0;
            alu_pc_out = pc + 4;
        end
    end
    `BGEU:
    begin
        if(vj >= vk)begin
            alu_result  = 1;
            alu_pc_out  = pc + imm;
        end
        else begin
            alu_result  = 0;
            alu_pc_out = pc + 4;
        end
    end
    `JAL:
    begin
            alu_result  = pc + 4;
            alu_pc_out  = pc + imm;
    end
    //I format
    `JALR:
    begin
            alu_result  = pc + 4;
            alu_pc_out  = vj + imm;
    end
    `ADDI:  alu_result  = vj + imm;   
    `SLTI:  alu_result  = ($signed(vj) < $signed(imm));
    `SLTIU: alu_result  = (vj < imm);
    `XORI:  alu_result  = (vj ^ imm);
    `ORI:   alu_result  = (vj | imm);
    `ANDI:  alu_result  = (vj & imm);
    `SLLI:  alu_result  = (vj << shamp);
    `SRLI:  alu_result  = (vj >> shamp);
    `SRAI:  alu_result  = (vj >>> shamp);
    //R format
    `ADD:   alu_result  = vj + vk;
    `SUB:   alu_result  = vj - vk;
    `SLL:   alu_result  = (vj << vk);
    `SLT:   alu_result  = ($signed(vj) < $signed(vk));
    `SLTU:  alu_result  = (vj < vk);
    `XOR:   alu_result  = (vj ^ vk);
    `SRL:   alu_result  = (vj >> vk);
    `SRA:   alu_result  = (vj >>> vk);
    `OR:    alu_result  = (vj | vk);
    `AND:   alu_result  = (vj & vk);
    //U format
    `LUI: alu_result  = imm;
    `AUIPC: 
    begin 
        alu_result  = imm + pc;
        alu_pc_out = imm + pc;
    end
    default:begin
        $display("!!! clk: %d op: %08x",$realtime,op);
    end
    endcase
    end
  
endmodule
