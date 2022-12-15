module decode (
    input logic clk,
    input logic reset,
    input logic stall_i,
    input logic flush_i,
    input logic next_ready_i,
    output logic valid_o,
    output logic ready_o,
    
    input logic [31:0] instr,
    input core_package::machine_mode_e machine_mode_i,

    output core_package::opcode_e opcode_o,
    output core_package::alu_op_e alu_op_o,
    output core_package:: inst_type_e i_type_o,
    output logic illegal_instr_o,
    output logic [4:0] rd_o,
    output logic [2:0] funct3_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output logic [31:0] imm_o,
    output logic [3:0] fence_pred_o,
    output logic [3:0] fence_succ_o,
    output logic [11:0] csr_o,
    output logic [4:0] shamt_o,
    output logic [4:0] zimm_o
);
    import core_package::*;

    logic illegal_instr = 1'b0;
    logic [6:0] opcode; 
    alu_op_e alu_op;
    inst_type_e i_type;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;
    logic [31:0] imm;
    logic [3:0] fence_pred;
    logic [3:0] fence_succ;
    logic [31:0] csr_val;
    logic [4:0] shamt;
    logic [4:0] zimm;
    csr_e csr;

    assign opcode = instr[6:0];
    assign ready_o = ~stall_i & ~flush & ~reset & ~illegal_instr;

    // get the bit field of the instruction
    always_comb begin : partition
        unique case (opcode)
            OPCODE_LOAD: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                imm = { {12{instr[31]}}, instr[31:12] };
                i_type = INST_TYPE_I;
            end
            OPCODE_MISC_MEM: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                fence_pred = instr[27:24];
                fence_succ = instr[23:20];
                i_type = INST_TYPE_SYSTEM;
            end
            OPCODE_OP_IMM: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                funct7 = instr[31:25];
                shamt = instr[24:20];
                imm = { {20{instr[31]}}, instr[31:20] };
                i_type = INST_TYPE_I;
            end
            OPCODE_AUIPC: begin
                rd = instr[11:7];
                imm = {instr[31:12], 12'b0};
                i_type = INST_TYPE_U;
            end
            OPCODE_STORE: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm = { {20{instr[31]}}, instr[31:25], instr[11:7] };
                i_type = INST_TYPE_S;
            end
            OPCODE_OP: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                funct7 = instr[31:25];
                i_type = INST_TYPE_R;
            end
            OPCODE_LUI: begin
                rd = instr[11:7];
                imm = {instr[31:12], 12'b0};
                i_type = INST_TYPE_U;
            end
            OPCODE_BRANCH: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8] };
                i_type = INST_TYPE_B;
            end
            OPCODE_JALR: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                imm = { {20{instr[31]}}, instr[31], instr[19:20], instr[30:25], instr[24:21] };
                i_type = INST_TYPE_I;
            end
            OPCODE_JAL: begin
                rd = instr[11:7];
                imm = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21] };
                i_type = INST_TYPE_J;
            end
            OPCODE_SYSTEM: begin
                rd = instr[11:7];
                funct3 = instr[14:12];
                rs1 = instr[19:15];
                zimm = instr[19:15];
                csr_val = {20'b0 ,instr[31:20]};
                i_type = INST_TYPE_SYSTEM;
            end
            default: begin
                rd = 5'bx;
                funct3 = 3'bx;
                rs1 = 5'bx;
                rs2 = 5'bx;
                funct7 = 7'bx;
                imm = 32'bx;
                fence_pred = 4'bx;
                fence_succ = 4'bx;
                csr = 12'bx;
                shamt = 5'bx;
                zimm = 5'bx;
                i_type = INST_TYPE_UNKNOWN;
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
                ALU_opcode = ALU_ADD;
        endcase
    end

    // for illegal instruction
    always_comb begin : illegal_instrustion
        unique case (opcode)
            OPCODE_LOAD: 
                illegal_instr = (funct3 == 3'b011) || 
                                (funct3 == 3'b110) ||
                                (funct3 == 3'b111);
            OPCODE_MISC_MEM: 
                illegal_instr = !((funct3 == 3'b000) || 
                                  (funct3 == 3'b001) ) ||
                                  (rs1 != 5'b00000) ||
                                  (instr[31:28] != 4'b0000) ||
                                  (funct3 == FENCE_I && 
                                   fence_pred != 4'b0000 && 
                                   fence_succ != 4'b0000);
            OPCODE_OP_IMM: 
                illegal_instr = (funct7 != 7'b0000000) || 
                                (funct7 != 7'b0100000);
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
                    illegal_instr = (funct3 == 3'b100) ||
                                    (funct3 == 3'b000 && (csr != 11'b0 || csr == 11'b1)) ||
                                    !$cast(csr, csr_val) ||
                                    (funct3 == CSRRW && csr[11:10] == 2'b11) ||
                                    (funct3 == CSRRS && csr[11:10] == 2'b11 && rs1 != 4'b0) ||
                                    (funct3 == CSRRC && csr[11:10] == 2'b11 && rs1 != 4'b0) ||
                                    (funct3 == CSRRWI && csr[11:10] == 2'b11) ||
                                    (funct3 == CSRRSI && csr[11:10] == 2'b11 && rs1 != 4'b0) ||
                                    (funct3 == CSRRCI && csr[11:10] == 2'b11 && rs1 != 4'b0) ||
                                    (machine_mode_i <= csr[9:8]);
                end
            default:
                illegal_instr = 1'b1;
        endcase
    end 

    always_ff @(posedge clk, posedge reset) begin
        if (reset)
        begin
            illegal_instr <= 1'b0;
            alu_opcode_o <= alu_opcode.ALU_ADD;
            rd_o <= 5'b0;
            funct3_o <= 3'b0;
            rs1_o <= 5'b0;
            rs2_o <= 5'b0;
            funct7_o <= 7'b0;
            imm_o <= 32'b0;
            fence_pred_o <= 4'b0;
            fence_succ_o <= 4'b0;
            csr_o <= 12'b0;
            shamt_o <= 5'b0;
            zimm_o <= 5'b0;
            valid_o <= 5'b0;
        end
        else 
        begin
            if (next_ready_i)
            begin
                illegal_instr_o <= illegal_instr;
                alu_opcode_o <= alu_opcode;
                rd_o <= rd;
                funct3_o <= funct3;
                rs1_o <= rs1;
                rs2_o <= rs2;
                funct7_o <= funct7;
                imm_o <= imm;
                fence_pred_o <= fence_pred;
                fence_succ_o <= fence_succ;
                csr_o <= csr;
                shamt_o <= shamt;
                zimm_o <= zimm;
                valid_o <= !flush && !stall && !illegal_instr;
            end
            else
            begin
                illegal_instr_o <= illegal_instr_o;
                alu_opcode_o <= alu_opcode_o;
                rd_o <= rd_o;
                funct3_o <= funct3_o;
                rs1_o <= rs1_o;
                rs2_o <= rs2_o;
                funct7_o <= funct7_o;
                imm_o <= imm_o;
                fence_pred_o <= fence_pred_o;
                fence_succ_o <= fence_succ_o;
                csr_o <= csr_o;
                shamt_o <= shamt_o;
                zimm_o <= zimm_o;
                valid_o <= valid_o;
            end
              
        end
    end

endmodule