module control 
    (
        input   logic                       clk,
        input   logic                       reset,

        input   logic [31:0]                pc_i,
        input   logic [31:0]                instr_i,
        input   core_package::inst_type_e   inst_type_i,
        input   logic                       branched_i,
        input   logic[31:0]                 mstatus,
        input   logic[31:0]                 mstatush,
        input   logic                       illegal_instr_i,

        //new pc output after taking trap
        output  logic [31:0]                pc_o,

        //trap
        input   logic [31:0]                trap_base_i,
        input   logic [1:0]                 trap_mode_i,
        output  logic [31:0]                trap_cause_o,
        output  logic [31:0]                trap_value_o,

        // exception
        output  logic [31:0]                exception_pc_o,

        //machine interrupt
        input   logic                       global_m_interrupt_en_i,
        input   logic [31:0]                mie_i,
        input   logic [31:0]                mip_i,
        input   logic [31:0]                mideleg_i,
        
        //software interrupt
        input   logic                       global_s_interrupt_en_i,

        output  logic                       stall_fetch,
        output  logic                       stall_decode,
        output  logic                       stall_execute,
        output  logic                       stall_memory,
        output  logic                       stall_wb,
        output  logic                       flush
    );
    import core_package::*;

    logic handle_m_iterrupt;

    assign handle_m_iterrupt = mstatus[MIE] && |(mie & mip)

    always_ff @(posedge clk) 
    begin : control
        if (pc_i == 32'h0 || branched_i) begin
            stall_fetch <= 1'b1;
        end
        else begin
            stall_fetch <= 1'b0;
        end

        if (illegal_instr) begin
            flush <= 1'b1;
            exception_pc_o <= pc_i -4;
            trap_cause_o <= {1'b0, 25'b0, illegal_instruction};
            trap_value_o <= instr_i;
        end

        if (inst_type_i == INST_TYPE_SYSTEM)
            stall_decode <= 1'b1;

        if (global_m_interrupt_en_i && handle_m_iterrupt) begin
            if (mie_i[MEIE] && mip_i[MEIP] && !mideleg_i[MEIE]) begin
                trap_cause_o <= {1'b1, 25'b0, external_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    pc_o <= trap_base_i + 4*machine_external_interrupt;
                else
                    pc_o <= trap_base_i;
            end
            else if (mie[MTIE] && mip[MTIP] && !mideleg_i[MTIE]) begin
                trap_cause_o <= {1'b1, 25'b0, timer_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    pc_o <= trap_base_i + 4*machine_timer_interrupt;
                else 
                    pc_o <= trap_base_i;
            end
            else if (mie[MSIE] && mip[MSIP] && !mideleg_i[MTIE]) begin
                trap_cause_o <= {1'b1, 25'b0, software_interrupt};
                trap_value_o <= 32'b0;
                if (trap_mode_i == Vectored)
                    pc_o <= trap_base_i + 4*machine_software_interrupt;
                else 
                    pc_o <= trap_base_i;
            end
        end

    end

endmodule