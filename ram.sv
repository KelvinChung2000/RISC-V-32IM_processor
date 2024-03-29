module ram
#(
    parameter data_width = 32,
    parameter addr_width = 32
)
(
    input logic clk,
    input logic [addr_width-1:0] addr_a,
    input logic [addr_width-1:0] addr_b,
    input logic [data_width-1:0] data,
    input logic read_a_en,
    input logic read_b_en,
    input logic write_en,
    output logic [data_width-1:0] data_a_out,
    output logic [data_width-1:0] data_b_out,
    output logic valid_o
);

logic [data_width-1:0] ram [2**addr_width:0];

always @(posedge clk) begin
    if (write_en) begin
        ram[addr_b] <= data;
    end
end

always @(posedge clk) begin
    if (read_a_en) begin
        data_a_out <= ram[addr_a];
    end
end

always @(posedge clk) begin
    if (read_b_en) begin
        data_b_out <= ram[addr_b];
    end
end

always @(posedge clk) begin
    valid_o <= read_a_en || read_b_en;
end

endmodule