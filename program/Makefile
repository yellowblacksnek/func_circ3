# schoolRISCV program Makefile
#
# Stanislav Zhelnio, 2020
#
RARS = java -jar ./rars1_4.jar
ifeq ($(OS), Windows_NT)
	RM=del
else
	RM=rm
endif

help:
	$(info make help     - show this message (default))
	$(info make blt      - create blt test)
	$(info make block    - create arithmetics block test)
	$(info make clean    - delete generated .data file)

# make program.data - compile to hex memory image using RARS
#  java -jar ./rars1_4.jar nc a dump .text HexText program.hex main.S
#    java -jar ./rars1_4.jar - run rars1_4.jar application using java machine
#    nc                              - copyright notice will not be displayed
#    a                               - assemble only, do not simulate
#    dump .text HexText program.data  - dump segment .text to program.data file in HexText format
.PHONY: clean blt block

counter:
	copy counter.data program.mem
	python hex_to_bin.py program.mem program.bin

blt: blt.S
	$(RARS) nc a dump .text HexText program.mem blt.S
	python hex_to_bin.py program.mem program.bin

block: block.S
	$(RARS) nc a dump .text HexText program.mem block.S
	python hex_to_bin.py program.mem program.bin

gen_block: block_test.py
	python block_test.py
	$(RARS) nc a dump .text HexText program.mem gen_block.S
#	python hex_to_bin.py program.mem program.bin

clean:
	$(RM) program.mem gen_block.S
