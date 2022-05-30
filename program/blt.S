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
start:      mv a0, zero  

test0:      addi a1, a0, 0
            addi a2, a0, 20
            blt a1, a2, test1 # 0   < 20
            ebreak

test1:      addi a1, a0, 20
            addi a2, a0, 30
            blt a1, a2, test2 # 20 < 30
            ebreak

test2:      addi a1, a0, 30
            addi a2, a0, 40
            blt a1, a2, test3 # 30 < 40
            ebreak

test3:      addi a1, a0, -10
            addi a2, a0, 0 
            blt a1, a2, test4 # -10 < 0
            ebreak

test4:      addi a1, a0, -30
            addi a2, a0, -10
            blt a1, a2, test5 # -30 < -10
            ebreak

test5:      addi a1, a0, -10
            addi a2, a0, 20
            blt a1, a2, test6 # -10 < 20
            ebreak

test6:      addi a1, a0, 0
            addi a2, a0, -10
            blt a1, a2, bad_res # 0 < -10

test7:      addi a1, a0, 10
            addi a2, a0, 0
            blt a1, a2, bad_res # 10 < 0

test8:      addi a1, a0, 0
            addi a2, a0, 0
            blt a1, a2, bad_res # 0 < 0

test9:      addi a1, a0, 10
            addi a2, a0, 3
            blt a1, a2, bad_res # 10 < 3

test10:     addi a1, a0, -15
            addi a2, a0, -132
            blt a1, a2, bad_res # -15 < -132
            
            beq zero, zero, end
bad_res:    ebreak
end:        beq zero, zero, start

