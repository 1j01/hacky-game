#!/usr/bin/python
# based on http://stackoverflow.com/a/14806704/2624876

import sys
import struct

if len(sys.argv) < 2:
	print "Parameter required: exe file to modify"
	sys.exit(-1)

exe = open(sys.argv[1], "r+b")
exe.seek(0x3c)
(PeHeaderOffset,) = struct.unpack("<H", exe.read(2))

exe.seek(PeHeaderOffset)
(PeSignature,) = struct.unpack("<I", exe.read(4))
if PeSignature != 0x4550:
	print "File is missing PE header signature"

exe.seek(PeHeaderOffset + 0x5C)
# Specify GUI mode
exe.write(struct.pack("<H", 0x02))
# Console mode would be 0x03

exe.close()

print "Completed succesfully."
