`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2026 09:52:38 PM
// Design Name: 
// Module Name: rf_alu_fsm_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module rf_alu_fsm_tb;
    reg clk;
    reg rst;
    
    reg [4:0] rs1, rs2, rd;
    reg we;
    wire [31:0] readData1, readData2;
    
    reg [3:0] alu_ctrl;
    wire [31:0] alu_result;
    wire alu_zero;

    reg use_alu_result;
    reg [31:0] manual_writeData;
    wire [31:0] writeData = use_alu_result ? alu_result : manual_writeData;

    localparam IDLE = 2'b00;
    localparam READ_REGISTERS = 2'b01;
    localparam ALU_OPERATION = 2'b10;
    localparam WRITE_REGISTERS = 2'b11;
    
    reg [1:0] state, next_state;
    reg [3:0] step;

    registerfile rf (
        .clk(clk), .rst(rst),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .writeData(writeData), .we(we),
        .readData1(readData1), .readData2(readData2)
    );

    alu alu_inst (
        .A(readData1), .B(readData2),
        .ALUControl(alu_ctrl),
        .ALUResult(alu_result),
        .Zero(alu_zero)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            step <= 0;
        end else begin
            state <= next_state;
            if (state == WRITE_REGISTERS) begin
                step <= step + 1; // Advance the sequence loop
            end
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (!rst) next_state = READ_REGISTERS;
            READ_REGISTERS: next_state = ALU_OPERATION;
            ALU_OPERATION: next_state = WRITE_REGISTERS;
            WRITE_REGISTERS: if (step < 12) next_state = READ_REGISTERS; else next_state = IDLE;
        endcase
    end

    always @(*) begin
        rs1 = 0; rs2 = 0; rd = 0; we = 0; 
        manual_writeData = 0; alu_ctrl = 4'b1001; use_alu_result = 0;

        case (step)
            0,1,2:   begin end
            3,4,5,6,7: begin rs1 = 1; rs2 = 2; end 
            8,9:       begin rs1 = 1; rs2 = 3; end 
            10:        begin rs1 = 1; rs2 = 1; end 
            12:        begin rs1 = 12; end 
        endcase

        if (state == ALU_OPERATION || state == WRITE_REGISTERS) begin
            case (step)
                3: alu_ctrl = 4'b0010; // ADD 
                4: alu_ctrl = 4'b0110; // SUB 
                5: alu_ctrl = 4'b0000; // AND 
                6: alu_ctrl = 4'b0001; // OR  
                7: alu_ctrl = 4'b0011; // XOR 
                8: alu_ctrl = 4'b0100; // SLL 
                9: alu_ctrl = 4'b0101; // SRL 
                10: alu_ctrl = 4'b0110; // SUB for BEQ flag calculation
            endcase
        end

        if (state == WRITE_REGISTERS) begin
            we = 1;
            case (step)
                0: begin rd = 1; manual_writeData = 32'h10101010; end 
                1: begin rd = 2; manual_writeData = 32'h01010101; end
                2: begin rd = 3; manual_writeData = 32'h00000005; end
                3: begin rd = 4; use_alu_result = 1; end // Save ADD
                4: begin rd = 5; use_alu_result = 1; end // Save SUB
                5: begin rd = 6; use_alu_result = 1; end // Save AND
                6: begin rd = 7; use_alu_result = 1; end // Save OR
                7: begin rd = 8; use_alu_result = 1; end // Save XOR
                8: begin rd = 9; use_alu_result = 1; end // Save SLL
                9: begin rd = 10; use_alu_result = 1; end // Save SRL
                10: begin 
                    rd = 11; 
                    manual_writeData = {31'b0, alu_zero}; // Save BEQ Flag
                end
                11: begin 
                    rd = 12; manual_writeData = 32'hFEEDFACE; // RAW setup
                end
                12: we = 0;
            endcase
        end
    end

    initial begin
        rst = 1;
        #15;
        rst = 0;
        
        wait (step == 13 && state == IDLE);
        $display("Integrated sequence completed using custom ALU.");
        #20 $finish;
    end
endmodule