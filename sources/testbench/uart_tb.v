`timescale 1 ns / 100 ps

`include "sr_cpu.vh"

`ifndef SIMULATION_CYCLES
    `define SIMULATION_CYCLES 120
`endif

`define EBREAK 32'b00000000000100000000000001110011
`define WFI 32'b00010000010100000000000001110011

module uart_tb;

    // simulation options
    parameter Tt     = 10;
    parameter c_CLOCK_PERIOD_NS = 10;
    parameter c_CLKS_PER_BIT    = 870;
    parameter c_BIT_PERIOD      = 8600;

    reg         clk;
    reg         rst_n;
    reg  [ 4:0] regAddr = 5'b0;
    wire [31:0] regData;
    wire        cpuClk;
    
    reg resetMem;
    wire resetMemBusy;
    
    reg         uartSerial = 1;
    reg         romWrite = 0;
//    reg   [7:0] dataByte;
    
    //simulation debug output
    integer cycle; initial cycle = 0;
    integer errors; initial errors = 0;
    reg stop; initial stop = 0;
    reg [31:0] prev; initial prev = 0;
    integer cur_cycles; initial cur_cycles = 0;
    // ***** DUT start ************************
    wire [31:0] romData;
    sm_top sm_top
    (
        .clkIn     ( clk        ),
        .rst_n     ( rst_n      ),
        .uart_in ( uartSerial ),
        .romWrite_i( romWrite   ),
        .resetMem ( resetMem   ),
        .romData    ( romData   ),
        .clkDevide ( 4'b0011       ),
        .clkEnable ( 1'b1       ),
        .clk       ( cpuClk     ),
        .romAddr   ( regAddr    ),
        .regAddr   ( regAddr    ),
        .regData   ( regData    ),
        .resetMemBusy (resetMemBusy)
    );

    defparam sm_top.sm_clk_divider.bypass = 1;

    // ***** DUT  end  ************************

`ifdef ICARUS
    //iverilog memory dump init workaround
    initial $dumpvars;
    genvar k;
    for (k = 0; k < 32; k = k + 1) begin
        initial $dumpvars(0, sm_top.sm_cpu.rf.rf[k]);
    end
`endif

    // simulation init
    initial begin
        clk = 0;
        forever clk = #(Tt/2) ~clk;
    end

    initial begin
        rst_n   = 0;
        repeat (4)  @(posedge clk);
        rst_n   = 1;
    end

    task disasmInstr;

        reg [ 6:0] cmdOp;
        reg [ 4:0] rd;
        reg [ 2:0] cmdF3;
        reg [ 4:0] rs1;
        reg [ 4:0] rs2;
        reg [ 6:0] cmdF7;
        reg [31:0] immI;
        reg signed [31:0] immB;
        reg [31:0] immU;

    begin
        cmdOp = sm_top.sm_cpu.cmdOp;
        rd    = sm_top.sm_cpu.rd;
        cmdF3 = sm_top.sm_cpu.cmdF3;
        rs1   = sm_top.sm_cpu.rs1;
        rs2   = sm_top.sm_cpu.rs2;
        cmdF7 = sm_top.sm_cpu.cmdF7;
        immI  = sm_top.sm_cpu.immI;
        immB  = sm_top.sm_cpu.immB;
        immU  = sm_top.sm_cpu.immU;
        
        if(prev == sm_top.sm_cpu.pc & prev != 0) begin
            cur_cycles = cur_cycles + 1;
        end
        else begin
            if (cur_cycles > 1) begin
                $write("took %1d cycles\n", cur_cycles);
            end

            prev = sm_top.sm_cpu.pc; cur_cycles = 1;
            
            $write ("%5d  pc = %2h instr = %h   a0 = %1d", 
                      cycle, sm_top.sm_cpu.pc, sm_top.sm_cpu.instr, sm_top.sm_cpu.rf.rf[10]);
            $write("   ");
    
            if(sm_top.sm_cpu.instr == `EBREAK) begin
                $write ("ebreak");
                errors = errors + 1;
            end
            else if(sm_top.sm_cpu.instr == `WFI) begin
                $write ("wfi");
                stop = 1;
            end
            else begin
                casez( { cmdF7, cmdF3, cmdOp } )
                    default :                                $write ("new/unknown");
                    { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : $write ("add   $%1d, $%1d, $%1d", rd, rs1, rs2);
                    { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : $write ("or    $%1d, $%1d, $%1d", rd, rs1, rs2);
                    { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : $write ("srl   $%1d, $%1d, $%1d", rd, rs1, rs2);
                    { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : $write ("sltu  $%1d, $%1d, $%1d", rd, rs1, rs2);
                    { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : $write ("sub   $%1d, $%1d, $%1d", rd, rs1, rs2);
        
                    { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : $write ("addi  $%1d, $%1d, 0x%8h (%1d)",rd, rs1, immI, $signed(immI));
                    { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : $write ("lui   $%1d, 0x%8h",      rd, immU);
        
                    { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : $write ("beq   $%1d, $%1d, 0x%8h (%1d)", rs1, rs2, immB, immB);
                    { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : $write ("bne   $%1d, $%1d, 0x%8h (%1d)", rs1, rs2, immB, immB);
                    { `RVF7_ANY,  `RVF3_BLT,  `RVOP_BLT  } : $write ("blt   $%1d, $%1d, 0x%8h (%1d)", rs1, rs2, immB, immB); //BLT
                    
                    { `RVF7_MUL,  `RVF3_MUL,  `RVOP_MUL  } : $write ("custom   $%1d, $%1d, $%1d", rd, rs1, rs2);
                endcase
            end
            $write("\n");
        end
    end
    endtask
    
    task UART_WRITE_BYTE;
    input [7:0] byte;
    integer     ii;
    begin
       
      // Send Start Bit
      uartSerial <= 1'b0;
      #(c_BIT_PERIOD);
//      #1000;
       
       
      // Send Data Byte
      for (ii=0; ii<8; ii=ii+1)
        begin
          uartSerial <= byte[ii];
          #(c_BIT_PERIOD);
        end
       
      // Send Stop Bit
      uartSerial <= 1'b1;
      #(c_BIT_PERIOD);
     end
  endtask
  
    task UART_WRITE_INSTR;
        input [31:0] instr;
        integer i;
        begin
            @(posedge clk);
            for(i=0; i<4; i=i+1) begin
                case (i)
                    0: begin UART_WRITE_BYTE(instr[31:24]); @(posedge clk); end
                    1: begin UART_WRITE_BYTE(instr[23:16]); @(posedge clk); end
                    2: begin UART_WRITE_BYTE(instr[15:8]); @(posedge clk); end
                    3: begin UART_WRITE_BYTE(instr[7:0]); @(posedge clk); end
                endcase
            end
        end
    endtask

    integer j = 0;
    integer rst_counts = 0;
    reg [31:0] NEW_MEM [15:0];
    always @ (posedge clk)
    begin
        disasmInstr();
        
        cycle = cycle + 1;
//        if (cycle > `SIMULATION_CYCLES | stop)
        
        if(cycle > 20) begin
            romWrite = 1;
            resetMem = 1;
            repeat (1) @(posedge clk);
            romWrite = 0;
            repeat (4) @(posedge clk);
            resetMem = 0;
            
            $readmemh ("f.data", NEW_MEM);
            
            for (j=0; j<16; j = j+1) begin
                UART_WRITE_INSTR(NEW_MEM[j]);
                regAddr = j;
            end
            
            @(posedge clk);
            rst_n = 0;
            repeat (2) @(posedge clk);
            rst_n = 1;
            cycle = 0;
            disasmInstr();
            cycle = cycle + 1;
            rst_counts = rst_counts + 1;
        end
        if(rst_counts > 2) stop = 1;
        if(stop) begin
            cycle = 0;
            if(stop) $display ("Stopped"); else $display ("Timeout");
            $display ("Amount of errors: %1d", errors);
            $stop;
        end
    end

endmodule
