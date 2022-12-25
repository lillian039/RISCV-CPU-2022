//define 不能加分号！！！！
`define    LUI      6'd0        //Load From Immediate
`define    AUIPC    6'd1        //Add Upper Immediate to PC
`define    JAL      6'd2        //Jump & Link
`define    JALR     6'd3        //Jump & Link Register
`define    BEQ      6'd4        //Branch Equal
`define    BNE      6'd5        //Branch Not Equal
`define    BLT      6'd6        //Branch Less Than
`define    BGE      6'd7        //Branch Greater than or Equal
`define    BLTU     6'd8        //Branch Less Than Unsigned
`define    BGEU     6'd9        //Branch >  Unsigned
`define    LB       6'd10       // Load Byte
`define    LH       6'd11 
`define    LW       6'd12 
`define    LBU      6'd13 
`define    LHU      6'd14 
`define    SB       6'd15 
`define    SH       6'd16 
`define    SW       6'd17 
`define    ADDI     6'd18 
`define    SLTI     6'd19 
`define    SLTIU    6'd20 
`define    XORI     6'd21 
`define    ORI      6'd22 
`define    ANDI     6'd23 
`define    SLLI     6'd24 
`define    SRLI     6'd25
`define    SRAI     6'd26 
`define    ADD      6'd27 
`define    SUB      6'd28 
`define    SLL      6'd29 
`define    SLT      6'd30 
`define    SLTU     6'd31 
`define    XOR      6'd32 
`define    SRL      6'd33 
`define    SRA      6'd34 
`define    OR       6'd35 
`define    AND      6'd36 
`define    NOP      6'd37       //no operation(R[0]=R[0])

//boolen
`define    TRUE     1'b1
`define    FALSE    1'b0

//load & store buffer
`define    LOAD     7'b0000011 
`define    STORE    7'b0100011

// 8 state
`define     Empty               3'b000 
`define     Waiting             3'b001 
`define     Ready               3'b010 
`define     Addressed           3'b011 
`define     WaitingStore        3'b100 
`define     Storing             3'b101 
`define     Loading             3'b110 
`define     WaitingBroadcast    3'b111 

// 6 type
`define     IType               3'b000 
`define     SType               3'b001 
`define     BType               3'b010 
`define     UType               3'b011 
`define     JType               3'b100 
`define     RType               3'b101 
`define     ILoadType           3'b110

//for record whether Qj Qk has value
`define     ENTRY_RANGE         5:0  //32 0:4
`define     ENTRY_NULL          6'd32
`define     NULL                6'd32

`define     ROB_SIZE            6'd32

`define     ADDR_RANGE          31:0 
`define     ICACHE_RANGE        127:0