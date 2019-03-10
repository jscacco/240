	.attempting to find out what formats the
	.SIC/XE assembler will read in bytes

	start	1000
	byte	1
lab:	byte	3
	byte	20
.the following is a hex based multiple byte initialization
	byte	x'123'
	byte	c'abcde'
	end
