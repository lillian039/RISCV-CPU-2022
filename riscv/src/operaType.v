`define    LUI      7'b0110111;//Load From Immediate
`define    AUIPC    7'b0010111;//Add Upper Immediate to PC
`define    JAL      7'b1101111;//Jump & Link
`define    JALR     7'b1100111;//Jump & Link Register
`define    BEQ      3'b000;//Branch Equal
`define    BNE      3'b001;//Branch Not Equal
`define    BLT      3'b100;//Branch Less Than
`define    BGE      3'b101;//Branch Greater than or Equal
`define    BLTU     3'b110;//Branch Less Than Unsigned
`define    BGEU     3'b111;//Branch >  Unsigned
`define    LB       3'b000;// Load Byte
`define    LH       3'b001;
`define    LW       3'b010;
`define    LBU      3'b100;
`define    LHU      3'b101;
`define    SB       3'b000;
`define    SH       3'b001;
`define    SW       3'b010;
`define    ADDI     3'b000;
`define    SLTI     3'b010;
`define    SLTIU    3'b011;
`define    XORI     3'b100;
`define    ORI      3'b110;
`define    ANDI     3'b111;
`define    SLLI     6'b000001;
`define    SRLI     6'b000101;
`define    SRAI     6'b100101;
`define    ADD      6'b000000;
`define    SUB      6'b100000;
`define    SLL      3'b001;
`define    SLT      3'b010;
`define    SLTU     3'b011;
`define    XOR      3'b100;
`define    SRL      6'b000101;
`define    SRA      6'b100101;
`define    OR       3'b110;
`define    AND      3'b111;
`define    LOAD     3'b0000011;
`define    STORE    3'b0100011
`define    TRUE     1'b1
`define    FALSE    1'b0
// 8 state
`define     Empty               3'b000;
`define     Waiting             3'b001;
`define     Finished            3'b010;
`define     Addressed           3'b011;
`define     WaitingStore        3'b100;
`define     Storing             3'b101;
`define     Loading             3'b110;
`define     WaitingBroadcast    3'b111;

// 6 type
`define     IType               3'b000;
`define     SType               3'b001;
`define     BType               3'b010;
`define     UType               3'b011;
`define     JType               3'b100;
`define     RType               3'b101;