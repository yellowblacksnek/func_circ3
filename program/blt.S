.text
start:      mv a0, zero  #счетчик ошибок

test0:      addi a1, zero, 0
            addi a2, zero, 20
            blt a1, a2, test1 # 0   < 20
            addi a0, a0, 1

test1:      addi a1, zero, 20
            addi a2, zero, 30
            blt a1, a2, test2 # 20 < 30
            addi a0, a0, 1

test2:      addi a1, zero, 30
            addi a2, zero, 40
            blt a1, a2, test3 # 30 < 40
            addi a0, a0, 1

test3:      addi a1, zero, -10
            addi a2, zero, 0 
            blt a1, a2, test4 # -10 < 0
            addi a0, a0, 1

test4:      addi a1, zero, -30
            addi a2, zero, -10
            blt a1, a2, test5 # -30 < -10
            addi a0, a0, 1

test5:      addi a1, zero, -10
            addi a2, zero, 20
            blt a1, a2, test6 # -10 < 20
            addi a0, a0, 1

test6:      addi a1, zero, 0
            addi a2, zero, -10
            blt a1, a2, bad_res6 # 0 < -10
            beq zero, zero, test7
bad_res6:   addi a0, a0, 1

test7:      addi a1, zero, 10
            addi a2, zero, 0
            blt a1, a2, bad_res7 # 10 < 0
            beq zero, zero, test8
bad_res7:   addi a0, a0, 1

test8:      addi a1, zero, 0
            addi a2, zero, 0
            blt a1, a2, bad_res8 # 0 < 0
            beq zero, zero, test9
bad_res8:   addi a0, a0, 1

test9:      addi a1, zero, 10
            addi a2, zero, 3
            blt a1, a2, bad_res9 # 10 < 3
            beq zero, zero, test10
bad_res9:   addi a0, a0, 1

test10:     addi a1, zero, -15
            addi a2, zero, -132
            blt a1, a2, bad_res10 # -15 < -132
            beq zero, zero, check
bad_res10:  addi a0, a0, 1
            
            
check:      bne a0, zero, bad_res
end:        wfi
            beq zero, zero, start
bad_res:    ebreak
            beq zero, zero, end

