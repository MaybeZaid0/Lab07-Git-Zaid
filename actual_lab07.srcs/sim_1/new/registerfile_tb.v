`timescale 1ns / 1ps

module registerfile_tb;
    reg clk;
    reg rst;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] writeData;
    reg we;
    wire [31:0] readData1, readData2;

    registerfile uut (
        .clk(clk), .rst(rst),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .writeData(writeData), .we(we),
        .readData1(readData1), .readData2(readData2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1; we = 0; rs1 = 0; rs2 = 0; rd = 0; writeData = 0;
        #10; rst = 0;

        we = 1; rd = 5'd5; writeData = 32'hDEADBEEF; 
        #10;
        we = 0; rs1 = 5'd5; 
        #10;
        if (readData1 == 32'hDEADBEEF) $display("Pass: x5 wrote successfully.");

        we = 1; rd = 5'd0; writeData = 32'hFFFFFFFF;
        #10;
        we = 0; rs1 = 5'd0;
        #10;
        if (readData1 == 32'h00000000) $display("Pass: x0 is hardwired to 0.");

        we = 1; rd = 5'd6; writeData = 32'hBEEFCAFE;
        #10;
        we = 0; rs1 = 5'd5; rs2 = 5'd6;
        #10;
        if (readData1 == 32'hDEADBEEF && readData2 == 32'hBEEFCAFE) 
            $display("Pass: Simultaneous read successful.");

        we = 1; rd = 5'd5; writeData = 32'h12345678;
        #10;
        we = 0; rs1 = 5'd5;
        #10;
        if (readData1 == 32'h12345678) $display("Pass: Register overwritten successfully.");

        #20 $finish;
    end
endmodule