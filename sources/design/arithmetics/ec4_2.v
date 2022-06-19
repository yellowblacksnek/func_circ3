`timescale 1ns / 1ps

module ec4_2(
        input [3:0] d,
        output reg [1:0] out
    );
    
//    assign out = (
//        (d == 4'bxxx1) ? 2'b00 :
//        (d == 4'bxx10) ? 2'b01 :
//        (d == 4'bx100) ? 2'b10 : 2'b11);
        
//    assign out[0] = d[1] | d[3];
//    assign out[1] = d[2] | d[3];
    
    always @* begin
        if(d[0]==1) begin out <= 2'b00; end
        else if(d[1]==1) begin out <= 2'b01; end
        else if(d[2]==1) begin out <= 2'b10; end
        else if(d[3]==1) begin out <= 2'b11; end
        else begin out <= 2'b00; end
    end
endmodule
