//`timescale 100us/10us

module core_tb (input logic clk);
    logic run;
    logic reset;

    logic [31:0] fetch_addr;
    logic fetch_en_o;
    logic [31:0] fetch_data_i;
    logic [31:0] mem_addr_o;
    logic [31:0] mem_data_o;
    logic mem_read_en_o;
    logic mem_write_en_o;
    logic [31:0] mem_data_i;
    logic mem_valid;
    logic mem_write_en;
    logic [31:0] addr_b;
    logic [31:0] data;

    core u_core(
        .clk(clk),
        .run(run),
        .reset(),

        .debug_en(),

        .fetch_addr(fetch_addr),
        .fetch_en_o(fetch_en_o),
        .fetch_data_i(fetch_data_i),
        .mem_addr_o(),
        .mem_data_o(),
        .mem_read_en_o(),
        .mem_write_en_o(),
        .mem_data_i(),
        .mem_valid_i(mem_valid),

        .m_timer_interrupt_i(),
        .m_external_interrupt_i(),
        .m_software_interrupt_i(),

        .s_timer_interrupt_i(),
        .s_external_interrupt_i(),
        .s_software_interrupt_i()
    );

    // ram #(.addr_width(32)) u_ram(
    //     .clk(clk),
    //     .addr_a(fetch_addr),
    //     .addr_b(addr_b),
    //     .data(data),
    //     .read_a_en(fetch_en_o),
    //     .read_b_en(),
    //     .write_en(mem_write_en),
    //     .data_a_out(fetch_data_i),
    //     .data_b_out(),
    //     .valid_o(mem_valid)
    // );

    logic [31:0] ram [1023:0];
    always_ff @(posedge clk ) begin : mem_block
        if (fetch_en_o)
            fetch_data_i <= ram[fetch_addr];
        mem_valid <= 1'b1;
    end

    initial begin
        ram[0] = 32'h3e800093; // addi x1, x0, 0x1000
        ram[4] = 32'h7d008113; // addi x2, x1, 0x2000
        ram[8] = 32'h002081b3; // add x3, x1, x2
        for (int i = 12; i < 1023; i+=4)
            ram[i] = 32'h00000013; // NOP

        $dumpfile("core_tb.vcd");
        $dumpvars(0, core_tb);
        mem_valid = 1'b0;
        @(posedge clk);
        run = 1;
        repeat (15) @(posedge clk);
        $finish;
    end

endmodule