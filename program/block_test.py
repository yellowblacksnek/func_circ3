import math
import numpy

f = open("gen_block.S", "w")
i = 0
data = ".text\n\n"
for a in range(0, 7):
    for b in range(0, 16):
        cb_a = pow(a,3)
        sq_b = pow(b,2)
        data += "{:<10} ".format("test" + str(i) + ":")
        data += "addi a1, zero, {}\n".format(cb_a)
        data += "{:<10} addi a2, zero, {}\n".format("", sq_b)
        data += "{:<10} addi a3, zero, {}\n".format("", a+b)
        data += "{:<10} mul a0, a1, a2\n".format("")
        if a==6 and b==15:
            data += "{:<10} beq a0, a3, end\n".format("", i+1)
            data += "{:<10} ebreak\n\n".format("")
        else:
            data += "{:<10} beq a0, a3, test{}\n".format("", i+1)
            data += "{:<10} ebreak\n\n".format("")
        i += 1

data += "{:<10} wfi".format("end:")

# print(data)

f.write(data)
f.close()