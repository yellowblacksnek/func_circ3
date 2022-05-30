from serial import Serial 
import sys
import time

com=sys.argv[1]

# baud=sys.argv[2]
baud = 9600

ser = Serial(com, baud, timeout=1, bytesize=8) 
while 1:
    x=ser.readline().hex()
    if x:
        print(x)
ser.close()

