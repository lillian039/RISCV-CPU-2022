module alu(
    input   wire                clk_in,// system clock signal
    input   wire                rst_in,// reset signal
    input   wire                rdy_in,// ready signal, pause cpu when low

    input   wire    [6:0]       opcode,
    input   wire    [31:0]      rs_op,   
    input   wire    [31:0]      rs_vj,
    input   wire    [31:0]      rs_vk,
    input   wire    [31:0]      rs_pc,
    input   wire    [31:0]      rs_imm,
    
    output  wire    [31:0]      rs_result,
    output  wire    [31:0]      rs_pc_out
    );

    wire        [2:0]       func3;
    wire        [6:0]       func7;
    wire        [5:0]       id;
    wire        [24:20]     shamp;
    assign shamp = rs_op [24:0];
    assign func3 = rs_op [14:12];
    assign func7 = rs_op [11:7];
    assign id = func3 + (func7 >> 2);

    always @(posedge clk ) begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else begin
    //B format
    if(opcode == 7'b1100011)begin
        if (func3 == BEQ)begin 
            if(rs_vj == rs_vk)begin
            rs_result <= 1;
            rs_pc_out <= pc + rs_imm;
            end
            else rs_result <= 0;
        end
        else if (func3 == BNE)
        begin
            if(rs_vj != rs_vk)begin
            rs_result <= 1;
            rs_pc_out <= pc + rs_imm;
            end
            else rs_result <= 0;
        end
        else if (func3 == BLT)
        begin
            if(signed'(rs_vj) < signed'(rs_vk))begin
            rs_result <= 1;
            rs_pc_out <= pc + rs_imm;
            end
            else rs_result <= 0;
        end
        else if (func3 == BGE)
        begin
            if(signed'(rs_vj) >= signed'(rs_vk))begin
            rs_result <= 1;
            rs_pc_out <= pc + rs_imm;
            end
            else rs_result <= 0;
        end
        else if (func3 == BLTU)
        begin
            if(rs_vj < rs_vk)begin
            rs_result <= 1;
            rs_pc_out <= pc + rs_imm;
            end
            else rs_result <= 0;
        end
        else if (func3 == BGEU)
        begin
            if(rs_vj >= rs_vk)begin
            rs_result <= 1;
            rs_pc_out <= pc + rs_imm;
            end
            else rs_result <= 0;
        end
    end

    //J format JAL
    else if(opcode == 7'b110111)begin
       rs_result <= rs_pc + 4;
       rs_op <= rs_pc + rs_imm;
    end
    
    //I format
    else if(opcode == 7'b0010011 || op == 7'b1100111)begin
        if(opcode == JALR)begin
            rs_result <= rs_pc + 4;
            rs_pc_out <= rs_vj + rs_imm;
        end
        else if (opcode == 7'b0010011)begin
            if (func3 == ADDI) rs_result <= rs_vj + rs_imm;
            else if (func3 == SLTI) rs_result <= (signed'(rs_vj) < signed' (rs_imm));
            else if (func3 == SLTIU) rs_result <= (rs_vj < rs_imm);
            else if (func3 == XORI) rs_result <= (rs_vj ^ rs_imm);
            else if (func3 == ORI) rs_result <= (rs_vj | rs_imm);
            else if (func3 == ANDI) rs_result <= (rs_vj & rs_imm);
            else if (func3 == SLLI[9:7] && func7 == SLLI[6:0]) rs_result <= (rs_vj << shamp);
            else if (func3 == SRLI[9:7] && func7 == SRLI[6:0]) rs_result <= (rs_vj >> shamp);
            else if (func3 == SRAI[9:7] && func7 == SRAI[6:0]) begin
                rs_result <= (rs_vj > shamp);
                //signed extend how?
            end
        end
        
    end
    //R format
    else if(opcode == 7'b0110011)begin
        if (id == ADD) rs_result <= rs_vj + rs_vk;
        else if (id == SUB) rs_result <= rs_vj - rs_vk;
        else if (id == SLL) rs_result <= (rs_vj << rs_vk);
        else if (id == SLT) rs_result <= (signed'(rs_vj) < signed'(rs_vk));
        else if (id == SLTU) rs_result <= (rs_vj < rs_vk);
        else if (id == XOR) rs_result <= (rs_vj ^ rs_vk);
        else if (id == SRL) rs_result <= (rs_vj >> rs_vk);
        else if (id == SRA) begin
            rs_result <= (rs_vj >> rs_vk);
            //signed extend how?
        end
        else if (id == OR) rs_result <= (rs_vj | rs_vk);
        else if (id == AND) rs_result <= (rs_vj & rs_vk);
    end
    
    //U format
    else if(opcode == 7'b0110111 || opcode == 7'b0010111)begin
        if(opcode == LUI) rs_result <= rs_imm;
        else if(opcode == AUIPC) rs_result <= rs_imm + rs_pc;
    end
    end
        
    end
  
endmodule