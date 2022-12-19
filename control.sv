module control 
    (
        input   logic                       clk,
        input   logic                       reset,

        input   core_package::inst_type_e   inst_type_i,
        input   logic                       branched_i,
        input   logic                       illegal_instr_i,

        input   logic[31:0]                 mstatus,
        input   logic[31:0]                 mstatush,

        //new pc output after any pc change
        input   logic [31:0]                new_pc_i,
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

        output  logic                       fetch_stall,
        output  logic                       decode_stall,
        output  logic                       execute_stall,
        output  logic                       memory_stall,
        output  logic                       wb_stall,
        output  logic                       reg_rd_stall,
        output  logic                       eg_wr_stall
    );
    import core_package::*;

    logic handle_m_iterrupt;
    logic handle_s_iterrupt;
    logic [31:0] pc = 32'b0;
    logic [31:0] trap_pc;

    assign handle_m_iterrupt = mstatus[MIE] && |(mie & mip);
    assign handle_trap = handle_m_iterrupt || handle_s_iterrupt;

    assign pc_o = (branched_i)  ? new_pc_i : 
                  (handle_trap) ? trap_pc  :
                                  pc       ;  


    always_ff @(posedge clk) 
    begin : control
        if (pc_i == 32'h0 || branched_i) begin
            stall_fetch <= 1'b1;
        end
        else begin
            stall_fetch <= 1'b0;
            pc <= pc_i + 4;
        end

        if (illegal_instr_i) begin
            flush <= 1'b1;
            exception_pc_o <= pc_i -4;
            trap_cause_o <= {1'b0, 25'b0, illegal_instruction};
            trap_value_o <= instr_i;
        end

        if (inst_type_i == INST_TYPE_SYSTEM)
        begin
            stall_decode <= 1'b1;
            stall_fetch <= 1'b1;
        end

        if (global_m_interrupt_en_i && handle_m_iterrupt) begin
            if (mie_i[MEIE] && mip_i[MEIP] && !mideleg_i[MEIE]) begin
                trap_cause_o <= {1'b1, 25'b0, external_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    trap_pc <= trap_base_addr_i + 4*machine_external_interrupt;
                else
                    trap_pc <= trap_base_addr_i;
            end
            else if (mie[MTIE] && mip[MTIP] && !mideleg_i[MTIE]) begin
                trap_cause_o <= {1'b1, 25'b0, timer_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    trap_pc <= trap_base_addr_i + 4*machine_timer_interrupt;
                else 
                    trap_pc <= trap_base_addr_i;
            end
            else if (mie[MSIE] && mip[MSIP] && !mideleg_i[MTIE]) begin
                trap_cause_o <= {1'b1, 25'b0, software_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    trap_pc <= trap_base_addr_i + 4*machine_software_interrupt;
                else 
                    trap_pc <= trap_base_addr_i;
            end
        end

    end

endmodule