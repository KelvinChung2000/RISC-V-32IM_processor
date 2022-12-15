module ram
#(
    parameter data_width = 32,
    parameter addr_width = 32
)
(
    input logic clk,
    input logic [addr_width:0] addr_a,
    input logic [addr_width:0] addr_b,
    input logic [data_width:0] data,
    input logic read_a_en,
    input logic read_b_en,
    input logic write_en,
    output logic [data_width:0] data_out_a,
    output logic [data_width:0] data_out_b
);

const addressSpace = 2**addr_width;

logic [data_width*ports:0] ram [addressSpace:0];

always @(posedge clk) begin
    if (write_en_a) begin
        ram[addr_a] <= data;
    end
end

always @(posedge clk) begin
    if (read_en_a) begin
        data_out_a <= ram[addr_a];
    end
end

always @(posedge clk) begin
    if (read_en_b) begin
        data_out_b <= ram[addr_b];
    end
end

endmodule