package core_package;

typedef enum logic [3:0] {
    fetch,
    decode,
    execute,
    memory,
    WB,
    stall,
    flush
} state;

typedef enum logic [6:0] {
        OPCODE_LOAD     = 7'b00000_11,
        OPCODE_MISC_MEM = 7'b00011_11,
        OPCODE_OP_IMM   = 7'b00100_11,
        OPCODE_AUIPC    = 7'b00101_11,
        OPCODE_STORE    = 7'b01000_11,
        OPCODE_OP       = 7'b01100_11,
        OPCODE_LUI      = 7'b01101_11,
        OPCODE_BRANCH   = 7'b11000_11,
        OPCODE_JALR     = 7'b11001_11,
        OPCODE_JAL      = 7'b11011_11,
        OPCODE_SYSTEM   = 7'b11100_11
    } opcode_e;

typedef enum {
        INST_TYPE_R,
        INST_TYPE_I,
        INST_TYPE_S,
        INST_TYPE_B,
        INST_TYPE_U,
        INST_TYPE_J,
        INST_TYPE_SYSTEM,
        INST_TYPE_UNKNOWN
} inst_type_e;

typedef enum {
        ALU_ADD,
        ALU_SUB,

        ALU_XOR,
        ALU_OR,
        ALU_AND,

        ALU_SLL,
        ALU_SLT,
        ALU_SLTU,

        ALU_SRA,
        ALU_SRL,

        ALU_JALR,

        ALU_EQ,
        ALU_NE,
        ALU_LT,
        ALU_LTU,
        ALU_GE,
        ALU_GEU

    } alu_op_e;

typedef enum logic[2:0] {
    LB  = 3'b000,
    LH  = 3'b001,
    LW  = 3'b010,
    LBU = 3'b100,
    LHU = 3'b101
} load_funct3_e;

typedef enum logic[2:0] {
    FENCE = 3'b000,
    FENCE_I = 3'b001
} misc_mem_funct3_e;

typedef enum logic[2:0] {
    ADDI = 3'b000,
    SLTI = 3'b010,
    SLTIU = 3'b011,
    XORI = 3'b100,
    ORI = 3'b110,
    ANDI = 3'b111,
    SLLI = 3'b001,
    SR_LA_I = 3'b101
} op_imm_funct3_e;

typedef enum logic[2:0] {
    SB = 3'b000,
    SH = 3'b001,
    SW = 3'b010
} store_funct3_e;

typedef enum logic[2:0] {
    ADD_SUB = 3'b000,
    SLL = 3'b001,
    SLT = 3'b010,
    SLTU = 3'b011,
    XOR = 3'b100,
    SR_LA = 3'b101,
    OR = 3'b110,
    AND = 3'b111
} op_funct3_e;

typedef enum logic[2:0] {
    BEQ = 3'b000,
    BNE = 3'b001,
    BLT = 3'b100,
    BGE = 3'b101,
    BLTU = 3'b110,
    BGEU = 3'b111
} branch_funct3_e;

typedef enum logic[2:0] {
    ECALL_EBREAK = 3'b000,
    CSRRW = 3'b001,
    CSRRS = 3'b010,
    CSRRC = 3'b011,
    CSRRWI = 3'b101,
    CSRRSI = 3'b110,
    CSRRCI = 3'b111
} system_funct3_e;

typedef enum logic [2:0] {
    MUL = 3'b000,
    MULH = 3'b001,
    MULHSU = 3'b010,
    MULHU = 3'b011,
    DIV = 3'b100,
    DIVU = 3'b101,
    REM = 3'b110,
    REMU = 3'b111
} md_funct3_e;


typedef enum logic [1:0]{
    user_mode = 2'b00,
    supervisor_mode = 2'b01,
    hypervisor_mode = 2'b10,
    machine_mode = 2'b11
} machine_mode_e;

typedef enum logic [11:0] {
    //Unprivileged Counter/Timers
    URO_cycle = 12'hC00,
    URO_time = 12'hC01,
    URO_instret = 12'hC02,

    URO_cycleh = 12'hC80,
    URO_timeh = 12'hC81,
    URO_instreth = 12'hC82,

    //Supervisor Trap Setup
    SRW_sstatus = 12'h100,
    SRW_sie = 12'h104,
    SRW_stvec = 12'h105,
    SRW_scounteren = 12'h106,

    //Supervisor Configuration
    SRW_senvcfg = 12'h10A,

    //Supervisor Trap Handling
    SRW_sscratch = 12'h140,
    SRW_sepc = 12'h141,
    SRW_scause = 12'h142,
    SRW_stval = 12'h143,
    SRW_sip = 12'h144,

    //Supervisor Protection and Translation
    SRW_satp = 12'h180,

    //Debug/Trace Registers 
    SRW_scontext = 12'h5A8,

    //Hypervisor trap setup
    HRW_hstatus = 12'h600,
    HRW_hedeleg = 12'h602,
    HRW_hideleg = 12'h603,
    HRW_hie = 12'h604,
    HRW_hcounteren = 12'h606,
    HRW_hgeie = 12'h607,

    //Hypervisor trap handling
    HRW_htval = 12'h643,
    HRW_hip = 12'h644,
    HRW_hvip = 12'h645,
    HRW_htinst = 12'h64A,
    HRO_hgeip = 12'hE12,

    //Hypervisor Configuration
    HRW_henvcfg = 12'h60A,
    HRW_henvcfgh = 12'h61A,

    //Hypervisor Protection and Translation
    HRW_hgatp = 12'h680,

    //Hypervisor Debug/Trace Registers
    HRW_hcontext = 12'h6A8,

    //Hypervisor Counter/Timers Virtualization Registers
    HRW_htimedelta = 12'h605,
    HRW_htimedeltah = 12'h615,

    //Virtrual Supervisor Registers
    HRW_vsstatus = 12'h200,
    HRW_vsie = 12'h204,
    HRW_vstvec = 12'h205,
    HRW_vsscratch = 12'h240,
    HRW_vsepc = 12'h241,
    HRW_vscause = 12'h242,
    HRW_vstval = 12'h243,
    HRW_vsip = 12'h244,
    HRW_vsatp = 12'h280,

    //Machine Information Registers
    MRO_mvenderid = 12'hF11,
    MRO_marchid = 12'hF12,
    MRO_mimpid = 12'hF13,
    MRO_mhartid = 12'hF14,
    MRO_mconfigptr = 12'hF15,

    //Machine Trap Setup
    MRW_mstatus = 12'h300,
    MRW_misa = 12'h301,
    MRW_medeleg = 12'h302,
    MRW_mideleg = 12'h303,
    MRW_mie = 12'h304,
    MRW_mtvec = 12'h305,
    MRW_mcounteren = 12'h306,
    MRW_mstatush = 12'h310,

    //Machine Trap Handling
    MRW_mscratch = 12'h340,
    MRW_mepc = 12'h341,
    MRW_mcause = 12'h342,
    MRW_mtval = 12'h343,
    MRW_mip = 12'h344,
    MRW_mtinst = 12'h34A,
    MRW_mtval2 = 12'h34B,

    //Machine Configuration
    MRW_menvcfg = 12'h30A,
    MRW_menvcfgh = 12'h31A,
    MRW_mseccfg = 12'h747,
    MRW_msecfgh = 12'h757,

    //Machine Memory Protection
    MRW_pmpcfg_start = 12'h3A0,
    MRW_pmpaddr_start = 12'h3B0,

    //Machine Counter/Timers
    MRW_mcycle = 12'hB00,
    MRW_minstret = 12'hB02,
    MRW_mcycleh = 12'hB80,
    MRW_minstreth = 12'hB81,

    //Machine Counter Setup
    MRW_mcountinhibit = 12'h120,

    //Degug/Trace Registers
    MRW_tselect = 12'h7A0,
    MRW_tdata1 = 12'h7A1,
    MRW_tdata2 = 12'h7A2,
    MRW_tdata3 = 12'h7A3,
    MRW_mcontext = 12'h7A8,

    //Debug Mdoe Registers
    DRW_dcsr = 12'h7B0,
    DRW_dpc = 12'h7B1,
    DRW_dscratch = 12'h7B2,
    DRW_dscratch1 = 12'h7B3,

    SRET = 12'b000_00010,
    MRET = 12'b000_00010,
    WFI  = 12'b000_00101,
} csr_e;

typedef enum logic [1:0] { 
    off = 2'b00,
    nondirty_claen_someOn = 2'b01,
    nonDirty_someClean = 2'b10,
    come_dirty = 2'b11
} csr_mstatus_XS_e;

typedef enum logic [1:0] { 
    off = 2'b00,
    initial = 2'b01,
    claen = 2'b10,
    dirty = 2'b11
} csr_mstatus_FS_e;

typedef enum logic [1:0] { 
    off = 2'b00,
    initial = 2'b01,
    claen = 2'b10,
    dirty = 2'b11
} csr_mstatus_VS_e;


typedef enum { 
    SD=31,
    TSR=22,
    TW=21,
    TVM=20,
    MXR=19,     //make executable readable
    SUM=18,
    MPRV=17,    //effective privilege mode (affect load/store behavior)
    MPP1=12,    //machine level previous privilege mode
    MPP0=11,
    SPP=8,      //supervisor previous privilege mode
    MPIE=7,     //machine level previous interrupt enable
    UBE=6
    SPIE=5,     //supervisor level previous interrupt enable
    MIE=3,      //global machine level interrupt enable
    SIE=1       //global supervisor level interrupt enable
} mstatus_field_e;

typedef enum { 
    MBE=5,      //machine memory endianess (0:little, 1:big)
    SBE=4       //supervisor memory endianess (0:little, 1:big)
 } mstatush_field_e;

typedef enum { 
    MEIP = 11,  //machine level external interrupt pending
    SEIP = 9,   //supervisor external interrupt pending
    MTIP = 7,   //machine timer interrupt pending
    STIP = 5,   //supervisor timer interrupt pending
    MSIP = 3,   //machine software interrupt pending
    SSIP = 1    //supervisor software interrupt pending
} mip_field_e;


typedef enum { 
    MEIE = 11,  //machine level external interrupt enable
    SEIE = 9,   //supervisor external interrupt enable
    MTIE = 7,   //machine timer interrupt enable
    STIE = 5,   //supervisor timer interrupt enable
    MSIE = 3,   //machine software interrupt enable
    SSIE = 1    //supervisor software interrupt enable
} mie_field_e;

typedef enum logic [7:0]{
    supervisor_software_interrupt = 1,
    machine_soft_interrupt = 3,
    supervisor_timer_interrupt = 5,
    machine_timer_interrupt = 7,
    supervisor_external_interrupt = 9,
    machine_external_interrupt = 11
} mcause_interrupt_e;

typedef enum logic [7:0] {
    instruction_address_missaligmened = 0,
    instruction_access_fault = 1,
    illegal_instruction = 2,
    breakpoint = 3,
    load_address_misaligned = 4,
    load_access_fault = 5,
    store_address_misaligned = 6,
    store_access_fault = 7,
    environment_call_from_u_mode = 8,
    environment_call_from_s_mode = 9,
    environment_call_from_m_mode = 11,
    instruction_page_fault = 12,
    load_page_fault = 13,
    store_page_fault = 15
} mcause_nonInterrupt_e;

typedef enum logic [1:0] {
    Direct = 0,
    Vectored = 1
} mtvec_mode_e;

typedef enum {
    CY=0,
    TM=1,
    IR=2,
    HPM3=3
} mcounteren_field_e;

endpackage