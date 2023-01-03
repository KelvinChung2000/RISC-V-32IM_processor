module decode (
    input   logic                           clk,
    input   logic                           reset,

    //pipeline control
    input   logic                           next_ready_i,
    output  logic                           self_ready_o,
    input   logic                           prev_valid_i,
    output  logic                           self_valid_o, 
    
    //contorl unit signal
    input   logic                           stall_i,

    //unit function signal
    input   logic [31:0]                    instr_i,
    input   core_package::machine_mode_e    machine_mode_i,
    input   logic [31:0]                    misa_i,

    output  core_package::opcode_e          opcode_o,
    output  core_package::alu_op_e          alu_op_o,
    output  core_package::instr_type_e      instr_type_o,
    output  logic                           illegal_instr_o,
    output  logic [4:0]                     rd_o,
    output  logic [4:0]                     rs1_o,
    output  logic [4:0]                     rs2_o,
    output  logic [2:0]                     funct3_o,
    output  logic [6:0]                     funct7_o,
    output  logic [31:0]                    imm_o,
    output  logic [3:0]                     fence_pred_o,
    output  logic [3:0]                     fence_succ_o,
    output  core_package::csr_e             csr_o,
    output  logic [31:0]                    shamt_o,
    output  logic [31:0]                    zimm_o

);
    import core_package::*;

    logic illegal_instr = 1'b0;
    opcode_e opcode; 
    alu_op_e alu_op;
    instr_type_e i_type;
    logic [31:0] instr;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;
    logic [31:0] imm;
    logic [3:0] fence_pred;
    logic [3:0] fence_succ;
    csr_e csr_val;
    logic [31:0] shamt;
    logic [31:0] zimm;
    csr_e csr;
    logic illegal_csr;
    logic valid;
    logic prev_valid;

    assign self_ready_o = !stall_i;
    assign illegal_instr_o = illegal_instr || illegal_csr;

    assign opcode = opcode_e'(instr[6:0]);
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign funct7 = instr[31:25];
    assign fence_pred = instr[27:24];
    assign fence_succ = instr[23:20];
    assign shamt = { {27{instr[24]}} ,instr[24:20]} ;
    assign zimm = {27'b0, instr[19:15]};
    assign csr_val = csr_e'(instr[31:20]);


    // get the bit field of the instruction
    always_comb begin : partition
        unique case (opcode)
            OPCODE_LOAD: begin
                imm = { {12{instr[31]}}, instr[31:12] };
                i_type = INSTR_TYPE_I;
            end
            OPCODE_MISC_MEM: begin
                imm = 32'b0;
                i_type = INSTR_TYPE_SYSTEM;
            end
            OPCODE_OP_IMM: begin
                imm = { {20{instr[31]}}, instr[31:20] };
                i_type = INSTR_TYPE_I;
            end
            OPCODE_AUIPC: begin
                imm = {instr[31:12], 12'b0};
                i_type = INSTR_TYPE_U;
            end
            OPCODE_STORE: begin
                imm = { {20{instr[31]}}, instr[31:25], instr[11:7] };
                i_type = INSTR_TYPE_S;
            end
            OPCODE_OP: begin
                imm = 32'b0;
                i_type = INSTR_TYPE_R;
            end
            OPCODE_LUI: begin
                imm = {instr[31:12], 12'b0};
                i_type = INSTR_TYPE_U;
            end
            OPCODE_BRANCH: begin
                imm = { {20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8] };
                i_type = INSTR_TYPE_B;
            end
            OPCODE_JALR: begin
                imm = { {20{instr[31]}}, instr[31:20]};
                i_type = INSTR_TYPE_I;
            end
            OPCODE_JAL: begin
                imm = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
                i_type = INSTR_TYPE_J;
            end
            OPCODE_SYSTEM: begin
                imm = 32'b0;
                i_type = INSTR_TYPE_SYSTEM;
            end
            default: begin
                imm = 32'bx;
                i_type = INSTR_TYPE_UNKNOWN;
            end
        endcase
    end

    always_comb begin : funcitonOutput
        unique case (opcode)
            OPCODE_OP_IMM:  begin
                            unique case (funct3)
                                ADDI:       alu_op = ALU_ADD;
                                SLTI:       alu_op = ALU_SLT;
                                SLTIU:      alu_op = ALU_SLTU;
                                XORI:       alu_op = ALU_XOR;
                                ORI:        alu_op = ALU_OR;
                                ANDI:       alu_op = ALU_AND;
                                SLLI:       alu_op = ALU_SLL;
                                SR_LA_I:    unique  case (funct7)
                                                        7'b0000000: alu_op = ALU_SRL;
                                                        7'b0100000: alu_op = ALU_SRA;
                                                        default: alu_op = ALU_ADD;
                                                    endcase
                            endcase
                            end
            OPCODE_OP:  begin 
                            unique case (funct3)
                                ADD_SUB:    unique case (funct7)
                                                7'b0000000: alu_op = ALU_ADD;
                                                7'b0100000: alu_op = ALU_SUB;
                                                default: alu_op = ALU_ADD;
                                            endcase
                                SLL:        alu_op = ALU_SLL;
                                SLT:        alu_op = ALU_SLT;
                                SLTU:       alu_op = ALU_SLTU;
                                XOR:        alu_op = ALU_XOR;
                                SR_LA:      unique case (funct7)
                                                7'b0000000: alu_op = ALU_SRL;
                                                7'b0100000: alu_op = ALU_SRA;
                                                default: alu_op = ALU_ADD;
                                            endcase
                                OR:         alu_op = ALU_OR;
                                AND:        alu_op = ALU_AND;
                            endcase
                        end

            OPCODE_JALR:alu_op = ALU_JALR;

            default: 
                alu_op = ALU_ADD;
        endcase
    end

    // for illegal instruction
    csr_e csr_enum;
    always_comb begin : illegal_instrustion
        unique case (opcode)
            OPCODE_LOAD: 
                illegal_instr = (funct3 == 3'b011) || 
                                (funct3 == 3'b110) ||
                                (funct3 == 3'b111);
            OPCODE_MISC_MEM: 
                illegal_instr = !((funct3 == 3'b000)        || 
                                  (funct3 == 3'b001) )      ||
                                  (rs1 != 5'b00000)         ||
                                  (instr[31:28] != 4'b0000) ||
                                  (funct3 == FENCE_I && 
                                   fence_pred != 4'b0000 && 
                                   fence_succ != 4'b0000);
            OPCODE_OP_IMM: 
                illegal_instr = (funct3 == SLLI && funct7 != 7'b0000000) || 
                                (funct3 == SR_LA_I && 
                                (funct7 != 7'b0100000 || funct7 != 7'b0000000));
            OPCODE_AUIPC: 
                illegal_instr = 1'b0;
            OPCODE_STORE: 
                illegal_instr = !((funct3 == 3'b000) || 
                                  (funct3 == 3'b001) || 
                                  (funct3 == 3'b010) );
            OPCODE_OP: 
                illegal_instr = (funct7 != 7'b0000000) || 
                                (funct7 != 7'b0100000);
            OPCODE_LUI: 
                illegal_instr = 1'b0;
            OPCODE_BRANCH: 
                illegal_instr = (funct3 == 3'b010) || 
                                (funct3 == 3'b011);
            OPCODE_JALR: 
                illegal_instr = !(funct3 == 3'b000);
            OPCODE_JAL:
                illegal_instr = 1'b0;
            OPCODE_SYSTEM:
                begin
                    illegal_instr = (funct3 == 3'b100)                                          ||
                                    (funct3 == 3'b000 && (csr != 12'b0 || csr == 12'b1))        ||
                                    // !(csr_val inside {csr_enum})                                 ||
                                    (funct3 == CSRRW && csr[11:10] == 2'b11)                    ||
                                    (funct3 == CSRRS && csr[11:10] == 2'b11 && rs1 != 5'b0)     ||
                                    (funct3 == CSRRC && csr[11:10] == 2'b11 && rs1 != 5'b0)     ||
                                    (funct3 == CSRRWI && csr[11:10] == 2'b11)                   ||
                                    (funct3 == CSRRSI && csr[11:10] == 2'b11 && rs1 != 5'b0)    ||
                                    (funct3 == CSRRCI && csr[11:10] == 2'b11 && rs1 != 5'b0)    ||
                                    (machine_mode_i <= csr[9:8]);
                end
            default:
                illegal_instr = 1'b1;
        endcase
    end 

    //illegal csr check
    always_comb begin : csr_check
        if (opcode == OPCODE_SYSTEM)
        unique case (csr)
                cycle   : illegal_csr = 1'b0;
                utime   : illegal_csr = 1'b0;
                instret : illegal_csr = 1'b0;
                cycleh  : illegal_csr = 1'b0;
                timeh   : illegal_csr = 1'b0;
                instreth: illegal_csr = 1'b0;
                sstatus : illegal_csr = 1'b0;
                stvec   : illegal_csr = 1'b0;
                sscratch: illegal_csr = 1'b0;
                sepc    : illegal_csr = 1'b0;
                scause  : illegal_csr = 1'b0;
                stval   : illegal_csr = 1'b0;
                sip     : illegal_csr = 1'b0;
                satp    : illegal_csr = 1'b0;
                scontext: illegal_csr = 1'b0;
                mvenderid: illegal_csr = 1'b0;
                marchid  : illegal_csr = 1'b0;
                mimpid   : illegal_csr = 1'b0;
                mhartid  : illegal_csr = 1'b0;
                mconfigptr: illegal_csr = 1'b0;
                mstatus  : illegal_csr = 1'b0;
                misa     : illegal_csr = 1'b0;
                medeleg  : illegal_csr = 1'b0;
                mideleg  : illegal_csr = 1'b0;
                mie      : illegal_csr = 1'b0;
                mtvec    : illegal_csr = 1'b0;
                mcounteren: illegal_csr = 1'b0;
                mscratch : illegal_csr = 1'b0;
                mepc     : illegal_csr = 1'b0;
                mcause   : illegal_csr = 1'b0;
                mtval    : illegal_csr = 1'b0;
                mip      : illegal_csr = 1'b0;
                menvcfg : illegal_csr = 1'b0;
                menvcfgh  : illegal_csr = 1'b0;
                mseccfg : illegal_csr = 1'b0;
                mseccfgh  : illegal_csr = 1'b0;
                pmpcfg_start: illegal_csr = 1'b0;
                pmpaddr_start: illegal_csr = 1'b0;
                mcycle   : illegal_csr = 1'b0;
                minstret : illegal_csr = 1'b0;
                mcycleh  : illegal_csr = 1'b0;
                minstreth: illegal_csr = 1'b0;
                mcountinhibit: illegal_csr = 1'b0;
                tselect  : illegal_csr = 1'b0;
                tdata1   : illegal_csr = 1'b0;
                tdata2   : illegal_csr = 1'b0;
                tdata3   : illegal_csr = 1'b0;
                mcontext: illegal_csr = 1'b0;
                dcsr     : illegal_csr = 1'b0;
                dpc      : illegal_csr = 1'b0;
                dscratch: illegal_csr = 1'b0;
                dscratch1: illegal_csr = 1'b0;
                default : illegal_csr = 1'b1;
        endcase
        else
            illegal_csr = 1'b0;
    end

    assign valid = !stall_i && prev_valid_i;
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
        begin
            alu_op_o        <= ALU_ADD;
            opcode_o        <= OPCODE_OP;
            rd_o            <= 5'b0;
            funct3_o        <= 3'b0;
            rs1_o           <= 5'b0;
            rs2_o           <= 5'b0;
            funct7_o        <= 7'b0;
            imm_o           <= 32'b0;
            fence_pred_o    <= 4'b0;
            fence_succ_o    <= 4'b0;
            csr_o           <= 12'b0;
            shamt_o         <= 32'b0;
            zimm_o          <= 32'b0;
        end
        else 
        begin
            self_valid_o <= valid;
            instr <= instr_i;
            if (valid && next_ready_i)
            begin
                opcode_o            <= opcode;
                alu_op_o            <= alu_op;
                instr_type_o        <= i_type; 
                rd_o                <= rd;
                funct3_o            <= funct3;
                rs1_o               <= rs1;
                rs2_o               <= rs2;
                funct7_o            <= funct7;
                imm_o               <= imm;
                fence_pred_o        <= fence_pred;
                fence_succ_o        <= fence_succ;
                csr_o               <= csr_val;
                shamt_o             <= shamt;
                zimm_o              <= zimm;
            end
        end
    end

endmodule