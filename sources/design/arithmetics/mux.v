`timescale 1ns / 1ps

module mux4_1
(
    input      [16:0] d0,
    input      [16:0] d1,
    input      [16:0] d2,
    input      [16:0] d3,
    input      [1:0]  addr,
    output reg [16:0] q
);
    always @* begin
        case(addr)
        2'b00: q = d0;
        2'b01: q = d1;
        2'b10: q = d2;
        2'b11: q = d3;
        endcase
    end
endmodule