import binascii
import sys
src = (sys.argv[1])
dest = (sys.argv[2])

nl = binascii.unhexlify('0D0A')
with open(src) as fd_in, open(dest, "wb") as fd_out:
    for line in fd_in:
        chunk = binascii.unhexlify(line.rstrip())
        fd_out.write(chunk)
        # fd_out.write(nl)
