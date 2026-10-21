`timescale 1ns / 1ps

module registerfile (
    input wire clk,
    input wire rst,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] writeData,
    input wire we,
    output wire [31:0] readData1,
    output wire [31:0] readData2
);
    // 32x32 array of registers
    reg [31:0] regs [31:0];
    integer i;

    assign readData1 = (rs1 == 5'b00000) ? 32'b0 : regs[rs1];
    assign readData2 = (rs2 == 5'b00000) ? 32'b0 : regs[rs2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else if (we && rd != 5'b00000) begin
            regs[rd] <= writeData; // Ignored if writing to x0
        end
    end
endmodule