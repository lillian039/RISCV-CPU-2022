`include "operaType.v"
module decoder(
    input   wire    [31:0]      op_in,

    output  reg     [31:0]      imm_out,
    output  reg     [5:0]       op_out,
    output  reg     [5:0]       rs1,
    output  reg     [5:0]       rs2,
    output  reg     [5:0]       rd,
    output  reg     [2:0]       op_type
);
    wire        [2:0]       func3 = op_in [14:12];
    wire        [6:0]       func7 = op_in [31:25];
    reg         [6:0]       opcode;

    wire        [31:0]      immI = {{20{op_in[31]}}, op_in[31:20]};
    wire        [31:0]      immS = {{20{op_in[31]}}, op_in[31:25], op_in[11:7]};
    wire        [31:0]      immB = {{20{op_in[31]}}, op_in[7], op_in[30:25], op_in[11:8], 1'b0};
    wire        [31:0]      immU = {op_in[31:12], 12'b0};
    wire        [31:0]      immJ = {{12{op_in[31]}}, op_in[19:12], op_in[20], op_in[30:21], 1'b0};

//组合逻辑 及时响应
    always @(*)begin

        rs1 = {1'b0,op_in [19:15]};
        rs2 = {1'b0,op_in [24:20]};
        rd  = {1'b0,op_in [11:7]};

        opcode = op_in[6:0];

        case(opcode)
        7'b0010011,7'b1100111: 
        begin
            op_type = `IType;
            rs2 = `NULL;
            imm_out = immI;
            case(opcode)
            7'b1100111: begin op_out = `JALR; end
            7'b0010011: begin
                case (func3)
                3'b000: op_out = `ADDI; 
                3'b001: op_out = `SLLI;
                3'b010: op_out = `SLTI; 
                3'b011: op_out = `SLTIU; 
                3'b100: op_out = `XORI; 
                3'b110: op_out = `ORI; 
                3'b111: op_out = `ANDI; 
                3'b101: begin 
                    case (func7)
                    7'b0000000: op_out = `SRLI;
                    7'b0100000: op_out = `SRAI; 
                    endcase
                end
                endcase
            end
            endcase
        end
        `LOAD: begin
            op_type =  `ILoadType;
            imm_out = immI;
            rs2 = `NULL;
            case (func3)
            3'b000: op_out = `LB;
            3'b001: op_out = `LH;
            3'b010: op_out = `LW;
            3'b100: op_out = `LBU;
            3'b101: op_out = `LHU;
            endcase
        end
        7'b0100011: 
        begin
            op_type = `SType;
            rd = `NULL;
            imm_out = immS;
            case(func3)
            3'b000: op_out = `SB; 
            3'b001: op_out = `SH;
            3'b010: op_out = `SW; 
            endcase
        end
        7'b1100011:
        begin
            if(op_in == 32'h00b72623)begin
                $display("???");
            end
            op_type = `BType;
            imm_out = immB;
            rd = `NULL;
            case(func3)
            3'b000: begin op_out = `BEQ; end
            3'b001: begin op_out = `BNE; end
            3'b100: begin op_out = `BLT; end
            3'b101: begin op_out = `BGE; end
            3'b110: begin op_out = `BLTU; end
            3'b111: begin op_out = `BGEU; end
            endcase
        end
        7'b0110111, 7'b0010111:begin
            op_type = `UType;
            rs2 = `NULL;
            imm_out = immU;
            case(opcode)
            7'b0110111: begin op_out = `LUI; end
            7'b0010111: begin op_out = `AUIPC; end
            endcase
        end
        7'b1101111:
        begin
            op_type = `JType;
            rs2 = `NULL;
            imm_out = immJ;
            op_out =  `JAL;
        end
        7'b0110011:
        begin
            op_type = `RType;
            imm_out = 32'b0;
            case (func3)
            3'b000:begin
                case (func7)
                7'b0000000: op_out = `ADD;
                7'b0100000: op_out = `SUB;
                endcase
            end
            3'b001: op_out = `SLL;
            3'b010: op_out = `SLT;
            3'b011: op_out = `SLTU;
            3'b100: op_out = `XOR;
            3'b101: begin
                case (func7)
                7'b0000000: op_out = `SRL;
                7'b0100000: op_out = `SRA;
                endcase
            end
            3'b110: op_out = `OR;
            3'b111: op_out = `AND;
            endcase
        end
        default: begin
            rs1 = `NULL;
            rs2 = `NULL;
            rd = `NULL;
            op_type = 0;
            imm_out = 0;
        end
        endcase

    end
endmodule