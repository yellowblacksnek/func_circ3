.text

start:      mv a1, zero  
            mv a2, zero         
            addi a1, a1, 5  
            addi a2, a2, 7  
            add a0, a1, a2
            wfi
            beq zero, zero, start