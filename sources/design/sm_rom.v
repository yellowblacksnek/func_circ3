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
    input         imRst,
    input  [31:0] aw,
    input  [31:0] ar,
    input         write_e,
    input  [31:0] wd,
    output [31:0] rd
);
    reg [31:0] rom [SIZE - 1:0];
    assign rd = rom [ar];

    initial begin
        $readmemh ("program.data", rom);
    end
    
    integer i;
    always@(posedge clk or posedge imRst)
    begin
    if (imRst) 
      begin
        for (i=0; i<SIZE - 1; i=i+1) rom[i] <= 32'b0;
      end
    else begin
        if(write_e) begin 
//            $display("writing instr %h", wd);
            rom[aw] <= wd; 
        end
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
    output reg  [31:0]  wa,
    output reg  [31:0]  wd,
    output wire         we,
    output reg          imRst = 0
);
    reg         ready = 0;
    reg  [ 1:0] counter = 0;
    
    wire imRstLatched;
    sm_active_latch im_rst_latch(clk, rstn, imRst, imRstLatched);
    
    assign we = ready;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
//            cur_a <= 0;
//            cur_d <= 0;
            counter <= 0;   
            wa <= 0;
            wd <= 0;
            imRst <= 0;
//            we <= 0;
        end else begin
            if(enable) begin
                if(!imRstLatched) imRst <= 1;
                else imRst <= 0;
                
                if(uart_v) begin
                    case (counter)
                        0: begin wd[31:24] <= uart_d; ready <= 0; end
                        1: wd[23:16] <= uart_d;
                        2: wd[15:8]  <= uart_d;
                        3: begin wd[7:0]   <= uart_d; ready <= 1; end
                    endcase
                    counter <= counter + 1;
                end
                if(ready & !imRst) begin
//                    $display("write instr %h", wd);
                    wa <= wa + 1;
                    ready <= 0;
                end
            end
        end
    end

endmodule
