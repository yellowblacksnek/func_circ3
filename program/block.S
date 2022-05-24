# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#

.text

# start:      mv a0, zero              # t0 = 0
#             mv a1, zero              # t1 = 0
#             addi a1, a1, 20
# counter:    addi a0, a0, 1          # t0 = t0 + 1
#             blt a0, a1, counter  # if t0 == t1 then counter
start:  mv a0, zero  

test0:  addi a1, zero, 0
        addi a2, zero, 0
        mul a0, a1, a2

test1:  addi a1, zero, 1
        addi a2, zero, 1
        mul a0, a1, a2

test2:  addi a1, zero, 255
        addi a2, zero, 255
        mul a0, a1, a2

test3:  addi a1, zero, 27
        addi a2, zero, 16
        mul a0, a1, a2

test4:  addi a1, zero, 28
        addi a2, zero, 17
        mul a0, a1, a2

test5:  addi a1, zero, 0
        addi a2, zero, 64
        mul a0, a1, a2

test6:  addi a1, zero, 125
        addi a2, zero, 0
        mul a0, a1, a2

end:    wfi

