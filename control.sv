module control 
    (
        input   logic                       clk,
        input   logic                       reset,

        input   core_package::instr_type_e  instr_type_i,
        input   core_package::opcode_e      opcode_i,
        input   logic                       branched_i,
        input   logic                       illegal_instr_i,
        input   logic                       decode_completed_i,
        input   logic                       ex_completed_i,
        input   logic[31:0]                 instr_i,
        output  core_package::machine_mode_e machine_mode_o,

        input   logic[31:0]                 mstatus,
        input   logic[31:0]                 mstatush,

        input   logic                       mem_valid_i,

        //forwarding signals 
        input   logic                       rd_en,
        input   logic [4:0]                 rs1_i,
        input   logic [4:0]                 rs2_i,
        input   logic [4:0]                 rd_i,
        input   logic [31:0]                exe_end_value_i,
        input   logic [31:0]                mem_end_value_i,    
        output  logic                       fwd_en_rs1_o,
        output  logic                       fwd_en_rs2_o,
        output  logic [31:0]                fwd_data_rs1_o,
        output  logic [31:0]                fwd_data_rs2_o,

        //new pc output after any pc change
        input   logic [31:0]                fetch_pc_i,
        input   logic [31:0]                ex_pc_i,
        output  logic [31:0]                pc_o,

        //trap
        input   logic [31:0]                trap_base_addr_i,
        input   logic [1:0]                 trap_mode_i,
        output  logic [31:0]                trap_cause_o,
        output  logic [31:0]                trap_value_o,

        //machine interrupt
        input   logic                       global_m_interrupt_en_i,
        input   logic [31:0]                mie_i,
        input   logic [31:0]                mip_i,
        input   logic [31:0]                mideleg_i,
        
        //software interrupt
        input   logic                       global_s_interrupt_en_i,

        //stall signals
        output  logic                       fetch_stall,
        output  logic                       decode_stall,
        output  logic                       execute_stall,
        output  logic                       memory_stall,
        output  logic                       wb_stall,
        output  logic                       reg_rd_stall,
        output  logic                       reg_wr_stall
    );
    import core_package::*;

    logic handle_m_iterrupt;
    logic handle_s_iterrupt;
    logic handle_trap;
    logic [31:0] pc = 32'b0;
    logic [31:0] trap_pc;
    logic [1:0] reg_valid [31:0] = '{default: 0};
    logic [1:0] inPipeline [31:0] = '{default: 0};
    logic [4:0] ex_rd, mem_rd, wb_rd;
    machine_mode_e machine_mode = m_mode;
    logic first_cycle = 1'b1;
    logic [4:0] rs1, rs2;

    assign handle_m_iterrupt = mstatus[MIE] && |(mie_i & mip_i);
    assign handle_trap = handle_m_iterrupt || handle_s_iterrupt;
    assign pc = (branched_i) ?  ex_pc_i : 
                (handle_trap) ? trap_pc: 
                                fetch_pc_i;
    
    assign machine_mode_o = machine_mode;
    assign fwd_en_rs1_o = (inPipeline[rs1_i] != 2'b00);
    assign fwd_en_rs2_o = (inPipeline[rs2_i] != 2'b00);
    assign fwd_data_rs1_o = (inPipeline[rs1_i] == 2'b10) ? mem_end_value_i : exe_end_value_i;
    assign fwd_data_rs2_o = (inPipeline[rs2_i] == 2'b10) ? mem_end_value_i : exe_end_value_i;
    always_ff @(posedge clk ) begin : forwarding
        if (rd_i != 0)
        begin
            inPipeline[rd_i] <= 2'b11;
        
            if (opcode_i == OPCODE_LOAD || opcode_i == OPCODE_STORE)
                reg_valid[rd_i] <= 2'b10;
            else if (opcode_i == OPCODE_OP || opcode_i == OPCODE_OP_IMM)
                reg_valid[rd_i] <= 2'b01;
            else
                reg_valid[rd_i] <= 2'b00;
        end

        if (reg_valid[ex_rd] != 2'b00)
            reg_valid[ex_rd] <= reg_valid[ex_rd] - 2'b1;

        if (reg_valid[mem_rd] != 2'b00)
            reg_valid[mem_rd] <= reg_valid[mem_rd] - 2'b1;

        if (inPipeline[ex_rd] != 2'b00)
            inPipeline[ex_rd] <=inPipeline[ex_rd] - 2'b1;

        if (inPipeline[mem_rd] != 2'b00)
            inPipeline[mem_rd] <=inPipeline[mem_rd] - 2'b1;

        if (inPipeline[wb_rd] != 2'b00)
            inPipeline[wb_rd] <=inPipeline[wb_rd] - 2'b1;

        ex_rd <= rd_i;
        mem_rd <= ex_rd;
        wb_rd <= mem_rd;

        execute_stall <= reg_valid[rs1] != 2'b00 || reg_valid[rs2] != 2'b00; 
    end

    always_ff @(posedge clk) 
    begin : control
        pc_o <= pc;
        if (illegal_instr_i && pc != 32'b0) begin
            trap_pc <= ex_pc_i - 32'(4);
            trap_cause_o <= {1'b0, 23'b0, illegal_instruction};
            trap_value_o <= instr_i;
        end

        if (instr_type_i == INSTR_TYPE_SYSTEM && ex_completed_i)
        begin
            decode_stall <= 1'b1;
            fetch_stall <= 1'b1;
        end
        else
        begin
            decode_stall <= 1'b0;
            fetch_stall <= 1'b0;
        end

        if (global_m_interrupt_en_i && handle_m_iterrupt) begin
            if (mie_i[MEIE] && mip_i[MEIP] && !mideleg_i[MEIE]) begin
                trap_cause_o <= {1'b1, 23'b0, m_e_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    trap_pc <= trap_base_addr_i + 4*m_e_interrupt;
                else
                    trap_pc <= trap_base_addr_i;
            end
            else if (mie[MTIE] && mip[MTIP] && !mideleg_i[MTIE]) begin
                trap_cause_o <= {1'b1, 23'b0, m_t_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    trap_pc <= trap_base_addr_i + 4*m_t_interrupt;
                else 
                    trap_pc <= trap_base_addr_i;
            end
            else if (mie[MSIE] && mip[MSIP] && !mideleg_i[MTIE]) begin
                trap_cause_o <= {1'b1, 23'b0, m_s_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    trap_pc <= trap_base_addr_i + 4*m_s_interrupt;
                else 
                    trap_pc <= trap_base_addr_i;
            end
        end

    end

endmodule