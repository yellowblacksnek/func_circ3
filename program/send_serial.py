from serial import Serial 
import sys

com=sys.argv[1]
filename=sys.argv[2]

# baud=sys.argv[2]
baud = 115200

ser = Serial(com, baud, timeout=0) 
f = open(filename, "r")
for line in f:
    for char in line.strip():
        ser.write(char.encode())

