; Jack Scacco
; Date: 9-30-18
; Assignment: HexDump
; File: hexdump.asm

TITLE let's get hex-tic
INCLUDE cs240.inc
.386

DOSEXIT 	= 4C00h
DOS 		= 21h
PSPPOINTER	= 6200h
CMDTAIL		= 80h
OPENF 		= 3D00h
CLOSEF 		= 3E00h
READF 		= 3F00h
CARRIAGERET	= 0Dh
PRINTCHR	= 02h

.data
fileName BYTE 127 dup(0)
fileHandle WORD ?
destArray BYTE 20 dup(0)
prevArray BYTE 20 dup(0)
myOffset DWORD 0
repeatSet BYTE 0

.code

GetCmdTail PROC
; Reads the command line starting from the space after the program name
; and places that string in fileName. Doesn't work for lengths > 100.

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	push	es
	pushf
	
	; CITE: www.fysnet.net/cmndline.htm
	; DESC: Hints/guidelines for reading from the command line.
	mov	ax, PSPPOINTER	; Get the offset of the psp into bx.
	int	DOS
	mov	es, bx
	mov	si, CMDTAIL
	mov	al, ES:[si]
	cmp	al, 127
	jg	tooLargeError
	mov	di, OFFSET fileName
	mov	cx, si		; Move into cs the number of bytes to read.
	inc	si		; Move to the actual command tail at 81h.
	jmp	cond

top:
	mov	al, ES:[si]
	mov	[di], al
	inc	si
	inc	di
	dec	cx
cond:
	cmp	cx, 0
	jne	top

	popf	
	pop	es
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

tooLargeError:
.data
tooLargeMsg BYTE "Please enter less than 100 characters.", 0
.code
	mov	dx, OFFSET tooLargeMsg
	mov	cx, 38
	call	AsciiOut
	mov	ax, DOSEXIT
	int	DOS
	ret
GetCmdTail ENDP

CleanUpFileName PROC
; Takes the string in fileName and cleans it up to only include printable characters.

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	pushf

	mov	si, OFFSET fileName	; We want to start at the same point.
	mov	di, OFFSET fileName
	mov	cx, 127			; This is the max length we can read.
	mov	bx, 0000h		; We will use this as a flag for when
					; to stop.
top:
	mov	al, [si]
	inc	si			
	dec	cx
	cmp	al, 21h			; 21 is the lowest we will print.
	jl	omit
	cmp	al, 7Ah
	jg	omit

use:
	mov	bx, -1			; Set out flag bc we started copying.
	mov	[di], al		; Copy the value we want 
	inc	di
	jmp	cond

omit:	
	cmp	bx, -1
	je	done

cond:
	cmp	cx, 0
	jne	top
	jmp	bottom

done:
	mov	al, 00h
	mov	[di], al
	
bottom:
	popf	
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
CleanUpFileName ENDP
OpenFile PROC
; Opens the file whose name is in fileName and places its handle in fileHandle.
; If the file name is not found, print an error message and end the program.

	push	ax
	push	dx
	pushf

	mov	ax, OPENF
	mov	dx, OFFSET fileName
	int	DOS

	cmp	ax, 02h		; 02h is the error value for no file.
	je	filenotfound

	mov	fileHandle, ax
	
	popf
	pop	dx
	pop	ax
	ret

filenotfound:
.data
noFileMsg BYTE "File not found!", 0
.code
	mov	dx, OFFSET noFileMsg
	mov	cx, 15		; Length of message
	call	AsciiOut	; Print Message
	popf			; Restore state
	pop	dx
	mov	ax, DOSEXIT	; Exit DOS
	int	DOS
	ret
OpenFile ENDP

CloseFile PROC
; Closes the file whose handle is in fileHandle

	push	ax
	push	bx
	pushf	

	mov	ax, CLOSEF
	mov	bx, fileHandle
	int	DOS

	popf
	pop	bx
	pop	ax
	ret
CloseFile ENDP

ReadBytes PROC
; Reads sixteen bytes from the file whose handle is in fileHandle and 
; sets destArray equal to the bytes.
; Does not preserve ax (bc it's the num. read), nor does it update offset.

	push	bx
	push	cx
	pushf

	mov	ax, READF
	mov	bx, fileHandle
	mov	cx, 16
	mov	dx, OFFSET destArray
	int	DOS

	popf
	pop	cx
	pop	bx
	ret
ReadBytes ENDP

PrintHexDigit PROC
; Prints out the lowest byte in dx.
.data
HexArray BYTE "0123456789abcdef", 0
.code
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	bx, dx
	mov	si, OFFSET HexArray
	and	bx, 000Fh

	mov	dl, [si + bx]
	mov	ah, PRINTCHR
	int	DOS

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PrintHexDigit ENDP

PrintDestArray PROC
; Expects the length in cx.
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	dx, OFFSET destArray
	mov	si, 0		; Store how many we have printed.
	mov	ax, cx		; Store the length in ax.
	mov	bx, dx		; Move the offset to bx.
	jmp	cond

top:
	mov	dl, [bx]
	and	dl, 0F0h	; Isolate the top nybble
	mov	cx, 4
shrtop:
	shr	dl, 1
	loop	shrtop		; Now dl is just the top nybble.
	call	PrintHexDigit	; Write the top nybble
	mov	dl, [bx]
	call	PrintHexDigit	; Write the lower nybble

	inc	bx
	dec	ax
	inc	si

	call	PrintSpace
	cmp	si, 8
	jne 	cond
	call	PrintSpace

cond:
	cmp	ax, 0
	jg	top

bottom:
	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PrintDestArray ENDP

OffsetOut PROC
; Prints out myOffset, which has a fixed length of four.
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	mov	ax, 4			; Store the length in ax.
	mov	bx, OFFSET myOffset	; Move the offset to bx.
	add	bx, 3			; We need to read backwards b/c endian
	jmp	cond


top:
	mov	dl, [bx]
	and	dl, 0F0h	; Isolate the top nybble
	mov	cx, 4
shrtop:
	shr	dl, 1
	loop	shrtop		; Now dl is just the top nybble.
	call	PrintHexDigit	; Write the top nybble
	mov	dl, [bx]
	call	PrintHexDigit	; Write the lower nybble

	dec	bx
	dec	ax

cond:
	cmp	ax, 0
	jg	top

bottom:
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
OffsetOut ENDP

PrintSpace PROC
; Prints out " ".
	push	ax
	push	dx
	pushf

	mov	ah, PRINTCHR
	mov	dl, " "
	int	DOS

	popf
	pop	dx
	pop	ax	
	ret
PrintSpace ENDP

AsciiOut PROC
; Takes an offset in dx and a length in cx. Prints out that many chars.
; Prints "." for unprintable characters.

	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	mov	bx, dx		; Move the offset into bx.
	jmp	cond		; Jump to comparison.

top:
	mov	dl, [bx]	; Load the character.
	cmp	dl, 32		; Check if it is printable.
	jl	unprintable
	cmp	dl, 127
	jg	unprintable
	jmp	printc		; If it is, print it.

unprintable:
	mov	dl, "."		; If it isn't print "."

printc:
	mov	ah, PRINTCHR
	int	DOS
	
	inc	bx		; Move the pointer one byte over.
	dec	cx		; Decrement our length counter.

cond:
	cmp	cx, 0
	jne	top

	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
AsciiOut ENDP

PrintFormattedAscii PROC
; Prints the ASCII characters associated with the values in destArray.
; Places pipes around the characters. Takes a length in cx.

	push	ax
	push	dx
	pushf

	mov	ah, PRINTCHR
	mov	dl, "|"
	int 	DOS
	
	mov	dx, OFFSET destArray
	call	AsciiOut

	mov	ah, PRINTCHR
	mov	dl, "|"
	int 	DOS

	popf
	pop	dx
	pop	ax
	ret
PrintFormattedAscii ENDP

PrintNewLine PROC
	push	ax
	push	dx
	pushf

	mov	ah, PRINTCHR
	mov	dl, 13
	int	DOS
	
	mov	dl, 10
	int	DOS

	popf	
	pop	dx
	pop	ax
	ret
PrintNewLine ENDP

PrintStar PROC
	push	ax
	push	dx
	pushf

	mov	ah, PRINTCHR
	mov	dl, "*"
	int	DOS

	popf	
	pop	dx
	pop	ax
	ret
PrintStar ENDP

AlignSpaces PROC
; Prints out enough spaces to align the final line of ASCII values with the previous 
; ASCII values. Expects the most recent number of bytes read to be in ax.

	push	ax
	push	bx
	push	cx
	push	dx
	pushf	

	mov	bx, 0
	cmp	ax, 8
	jl	rest
	inc	bx
rest:
	mov	cx, 3		; Multiply ax by 3 (two hex digits and a space)
	mul	cx
	mov	cx, 50		; 50 is the number of spaces (offset to ascii).
	sub	cx, bx		; bx is 1 if we have printed out the double
	sub 	cx,ax		; spaces.

top:
	call	PrintSpace
	loop	top

	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
AlignSpaces ENDP

CmpArrays PROC
; This compares the two arrays, destArray and prevArray. It sets ax to the 
; number of differences.

	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	ax, 0
	mov	cx, 20
	
	mov	bx, OFFSET destArray
	mov	si, OFFSET prevArray

top:
	mov	dl, [bx]
	mov	dh, [si]
	cmp	dl, dh
	je 	cond
	inc	ax

cond:
	dec	cx
	inc	bx
	inc	si
	cmp	cx, 0
	jne	top

bottom:
	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx	
	ret
CmpArrays ENDP

DestToPrev PROC
; Set prevArray to the current destArray. Overwrites the current prevArray.
	push	bx
	push	cx
	push	di
	push	si
	pushf

	mov	si, OFFSET destArray
	mov	di, OFFSET prevArray
	mov	cx, 20

top:
	mov	bl, [si]
	mov	[di], bl	
	dec	cx
	inc	si
	inc	di

cond:
	cmp	cx, 0
	jne	top

	popf
	pop	si	
	pop	di
	pop	cx
	pop	bx	
	ret
DestToPrev ENDP

ProcessFile PROC
; This does all the things!
	push	eax
	push	bx
	push	cx
	push	dx
	pushf

checkempty:
	call	ReadBytes
	cmp	ax, 0	
	mov	cx, ax
	je	emptyfile

top:
	mov	repeatSet, 0		; Reset repeat counter
	call	OffsetOut
	call	PrintSpace
	call	PrintSpace
	call	PrintDestArray
	call	PrintSpace
	call	PrintFormattedAscii
	call	PrintNewLine
	and	ecx, 0000FFFFh
	add 	myOffset, ecx
	jmp	cond

sameline:
	add	myOffset, ecx
	cmp	repeatSet, 1 	; Don't print a star if we have just repeated.
	je	nostar
	call	PrintStar
	call	PrintNewLine
nostar:
	mov	repeatSet, 1

cond:
	call	DestToPrev
	call	ReadBytes
	mov	cx, ax		; Move the number of bytes read into cx
	cmp	ax, 0		; since the printer functions need the length.
	je	bottom
	cmp	ax, 16
	jl	endcase
	call	CmpArrays
	cmp	ax, 0
	je	sameline
	jmp	top

endcase:
	call	OffsetOut
	call	PrintSpace
	call	PrintSpace
	call	PrintDestArray
	call	AlignSpaces
	call	PrintFormattedAscii
	and	eax, 0000FFFFh		; Clear the top of eax.
	add 	myOffset, eax
	call	PrintNewLine

bottom:
	call	OffsetOut
	call	PrintNewLine
	
emptyfile:
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	eax
	ret

ProcessFile ENDP

; The general algorithm for my program is as follows: 
; First, read in the name of the file from the command line by reading
; in the number of bytes specified in offset 80h. Then, clean it up by 
; removing any leading spaces/unprintable characters and placing a 00h
; in the byte after the last alphanumeric character. Once we have 
; the file name, open the file and begin processing it, 16 bytes at a time.
; First, though, check if the file is empty so nothing is printed out.
; If the file is not empty, tell the computer to read in 16 bytes and compare
; the number of bytes actually read (found in AX), to 16. If it is less than
; 16, finish up printing out that information and then stop. If it is equal
; to 16, then print that information and recur. Of course, there are a few
; edge cases to check for when processing the file. The most critical helper
; functions are PrintDestArray (a modified HexOut), PrintFormattedAscii (a 
; modified PrintString), and OffsetOut. I keep track of the important info
; In global .data declarations. Perhaps keeping track of things on the stack
; would have been a better idea, but it isn't necessary in this case
; because the program can only be called from the cmd line and each variable
; is reset (they can't be messed up by multiple calls to hexdump).
main PROC
	mov	ax, @data
	mov	ds, ax

	call	GetCmdTail
	call	CleanUpFileName
	call	OpenFile
	call	ProcessFile
	call	CloseFile

	mov	ax, DOSEXIT
	int	DOS
	ret
main ENDP
END main
