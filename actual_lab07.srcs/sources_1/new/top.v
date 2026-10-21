`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2026 10:23:13 PM
// Design Name: 
// Module Name: top
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

module top_rf_alu (
    input  wire clk,       
    input  wire btnC,      
    input  wire btnU,      
    input  wire [15:0] sw, 
    output wire [15:0] led
);

    wire clk_slow;
    wire rst;
    wire step_pulse;
    wire [3:0] sw_clean;

    localparam INIT_X1 = 3'b000;
    localparam INIT_X2 = 3'b001;
    localparam MANUAL_OP = 3'b010;
    reg [2:0] state, next_state;

    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] writeData;
    reg         we;
    wire [31:0] readData1, readData2;

    reg  [3:0]  alu_ctrl;
    wire [31:0] alu_result;
    wire        alu_zero;

    wire [15:0] result_leds;
    wire        zero_led;

    clock_divider u_clock (
        .clk_in(clk),
        .rst(rst),
        .clk_out(clk_slow)
    );

    debouncer u_reset_db (
        .clk(clk),
        .pbin(btnC),
        .pbout(rst)
    );

    button_pulse u_step_pulse (
        .clk(clk),
        .btn_raw(btnU),
        .pulse(step_pulse)
    );

    switch_interface u_sw_sync (
        .clk(clk),
        .sw_raw(sw[3:0]),
        .sw_sync(sw_clean)
    );

    registerfile u_rf (
        .clk(clk),
        .rst(rst),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .writeData(writeData), .we(we),
        .readData1(readData1), .readData2(readData2)
    );

    alu u_alu (
        .A(readData1),
        .B(readData2),
        .ALUControl(alu_ctrl),
        .ALUResult(alu_result),
        .Zero(alu_zero)
    );

    led_interface u_leds (
        .alu_result(alu_result),
        .zero(alu_zero),
        .display_enable(1'b1),
        .led_result(result_leds),
        .led_zero(zero_led)
    );
    
    assign led[13:0] = result_leds[13:0];
    assign led[14] = zero_led;
    assign led[15] = we;

    always @(posedge clk) begin
        if (rst) begin
            state <= INIT_X1;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            INIT_X1: if (step_pulse) next_state = INIT_X2;
            INIT_X2: if (step_pulse) next_state = MANUAL_OP;
            MANUAL_OP: next_state = MANUAL_OP; // Stay in manual mode
            default: next_state = INIT_X1;
        endcase
    end

    always @(*) begin
        rs1 = 5'd1; // Default read x1
        rs2 = 5'd2; // Default read x2
        rd  = 5'd0;
        we  = 1'b0;
        writeData = 32'b0;
        alu_ctrl = 4'b1001; // PASS A

        case (state)
            INIT_X1: begin
                rd = 5'd1;
                writeData = 32'd12;
                we = step_pulse; 
            end
            INIT_X2: begin
                rd = 5'd2;
                writeData = 32'd6;
                we = step_pulse; 
            end
            MANUAL_OP: begin
                alu_ctrl = sw_clean;
                rd = sw[8:4];
                writeData = alu_result;
                we = sw[15] & step_pulse; // Only write on a button press while switch 15 is active
            end
        endcase
    end

endmodule