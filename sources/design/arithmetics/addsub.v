`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2022 11:04:41
// Design Name: 
// Module Name: addsub
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


module addsub(
        input [16:0] i0,
        input [16:0] i1,
        input [16:0] i2,
        input [1:0] addr,
        output reg [7:0] out
    );
    always @* begin
        case(addr)
            0: 
                begin
                    if(i0[16]) begin out = i0[15:8] + i0[7:0]; end
                    else begin out = i0[15:8] - i0[7:0]; end
                end
            1: 
                begin
                    if(i1[16]) begin out = i1[15:8] + i1[7:0]; end
                    else begin out = i1[15:8] - i1[7:0]; end
                end
            2:
                begin
                    if(i2[16]) begin out = i2[15:8] + i2[7:0]; end
                    else begin out = i2[15:8] - i2[7:0]; end
                end
            default: begin out = 0; end
        endcase
    end
endmodule

//module addsub(
//        input [7:0] a_i,
//        input [7:0] b_i,
//        input mode,
//        output [7:0] out
//    );
//    assign out = mode ? a_i+b_i : a_i-b_i;
//endmodule
