.text

start:  mv a0, zero  

        addi a1, zero, 0
        addi a2, zero, 0

        addi a3, zero, 1
        addi a4, zero, 1

        addi a5, zero, 255
        addi a6, zero, 255

        addi s2, zero, 28
        addi s3, zero, 17

test0:  mul a0, a1, a2 #0 = 0
test1:  mul a0, a3, a4 #2 = 2
test2:  mul a0, a5, a6 #21 = 15
test3:  mul a0, s2, s3 #7 = 7

end:    wfi
        wfi
        wfi
        beq zero, zero, start

