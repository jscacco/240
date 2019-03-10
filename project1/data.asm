; Name: Jack Scacco
; Date: 9-2-18
; Assignment: Project 1
; File: data.asm

TITLE data

INCLUDE cs240.inc
.8086

DOSEXIT = 4C00h
DOS = 21h

.data
memblock	LABEL	BYTE
myBYTE		BYTE	255
mySBYTE		SBYTE	-127
myWORD		WORD	65535
mySWORD		SWORD	-32767
myDWORD		DWORD	4294967295
mySDWORD	SDWORD	-2147483647
myFWORD		FWORD	281474976710655
myQWORD		QWORD	0FFFFFFFFFFFFFFFFh
myTBYTE		TBYTE	07FFFFFFFFFFFFFFFFFFFh
myREAL4		REAL4	3.4E-38
myREAL8		REAL8	2.23E-308
myREAL10	REAL10	3.37E-4932
memend		LABEL	BYTE

.code
main PROC
	mov	ax, @data
	mov	ds, ax
	
	mov	dx, OFFSET memblock
	mov	cx, memend - memblock
	call	DumpMem

	mov	ax, DOSEXIT
	int	DOS
	ret
main ENDP
END main
