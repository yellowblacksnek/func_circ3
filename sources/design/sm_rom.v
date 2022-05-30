/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

module sm_rom
#(
    parameter SIZE = 1024
)
(
    input         clk,
//    input         imRst,
    input  [31:0] wa,
    input  [31:0] ra,
    input         write_e,
    input  [31:0] wd,
    output [31:0] rd
);
//    (* rom_style = "block" *)
    reg [31:0] rom [SIZE-1:0];
    assign rd = rom [ra];

//    reg rst_done;

    initial begin
        $readmemh ("program.mem", rom);
//        rst_done <= 1;
    end
    
//    reg [SIZE-1:0] i;
    always@(posedge clk)
    begin  
        if(write_e) begin 
            rom[wa] <= wd; 
        end
    end

endmodule

module rom_writer 
#(
    parameter SIZE = 1024
)
(
    input               clk,
    input               rstn,
    input               enable,
    input               uart_v,
    input       [ 7:0]  uart_d,
    output reg  [31:0]  im_wa,
    output reg  [31:0]  im_wd,
    output wire         im_we
//    output reg          im_rst
);
    reg         ready = 0;
    reg  [ 1:0] counter = 0;
    reg  [31:0]  im_wd_tmp;
    reg         rst_done = 0;
    reg  [31:0] rst_addr = 0;
    
    assign im_we = ready;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            counter <= 0;   
            im_wa <= 0;
            im_wd <= 0;
            ready <= 0;
//            rst_done <= 0;
        end else begin
            if(enable) begin
//                if(!rst_done) begin 
//                    ready <= 1;
//                    im_wa <= im_wa + 1;
//                    if(im_wa >= SIZE) begin
//                        im_wa <= 0;
//                        rst_done <= 1;
//                        ready <= 0;
//                    end
//                end else begin
                    if(uart_v) begin
                        case (counter)
                            2'b00: begin im_wd[31:24] <= uart_d; ready <= 0; end
                            2'b01: im_wd[23:16] <= uart_d;
                            2'b10: im_wd[15:8]  <= uart_d;
                            2'b11: begin im_wd[7:0]   <= uart_d; ready <= 1; end
                        endcase
                        counter <= counter + 1;
                    end
                    if(ready) begin
                        im_wa <= im_wa + 1;
                        ready <= 0;
                    end
//                end
            end
        end
    end

endmodule
