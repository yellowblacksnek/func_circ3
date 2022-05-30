from serial import Serial 
import sys
import binascii
import time

com=sys.argv[1]
filename=sys.argv[2]

# baud=sys.argv[2]
baud = 115200
if filename.endswith(".bin"):
    with Serial(com, baud, timeout=0, bytesize=8) as ser: 
        with open(filename, "rb") as f:
            while (byte := f.read(1)):
                print(byte.hex())
                ser.write(byte)
else:
    with Serial(com, baud, timeout=0, bytesize=8) as ser: 
        with open(filename, "rb") as f:
            for line in f.readlines():
                bytes = binascii.unhexlify(line.rstrip())
                print(bytes.hex())
                ser.write(bytes)
                # for byte in :
                #     print(byte.hex())
                #     ser.write(byte)
# data = bytes.fromhex(f.read())
# for char in f.read():
#         print(char.encode())
#         ser.write(char.encode())
# ser.close()
        # time.sleep(0.1)
# for line in f:
#     for char in line.strip():
#         ser.write(char.encode())

