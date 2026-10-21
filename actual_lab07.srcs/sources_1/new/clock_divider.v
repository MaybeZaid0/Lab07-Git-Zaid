`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 

// Module Name: clock_divider
// Project Name: Counter
// Target Devices: Baasys 3
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_divider (
    input wire clk_in,    
    input wire rst,       
    output reg clk_out
);

    reg [25:0] count = 0; 
  
// localparam MAX_COUNT = 2;            // Commented out for hardware implementation
localparam MAX_COUNT = 50_000_000 - 1;  // 1 Hz slow clock for Basys 3 board

    always @(posedge clk_in) begin
        if (rst) begin
            count <= 0;
            clk_out <= 0;
        end 
        else if (count == MAX_COUNT) begin
            count <= 0;
            clk_out <= ~clk_out; 
        end 
        else begin
            count <= count + 1;
        end
    end

endmodule
