; Name: Jack Scacco
; Assignment: Project6
; Due Date: 11-2-18
; File: keyping.asm

TITLE Keyping Time
.model tiny
.386
.code
	org	100h

EntryPoint:
	jmp	setup

SYSTEM			= 1Ah
SYSTEM_GETTIME		= 02h
DOS 			= 21h
DOS_GETTIME 		= 2Ch
DOS_EXIT 		= 4C00h
BIOS 			= 10h
BIOS_WRITE_COLOR_CHAR	= 09h
BIOS_WRITE_CHAR 	= 0Ah
BIOS_READ_CURSOR	= 03h
BIOS_WRITE_CURSOR	= 02h
BIOS_GETSCRCONTENTS	= 08h
BIOS_SETSCRCONTENTS	= 0Ah
KEYHANDLER		= 09h
TIMERHANDLER		= 08h
TSR			= 3100h
EXIT_TSR		= 4900h
GET_RETURN_CODE		= 4Dh
PSPPOINTER		= 6200h
CMDTAIL			= 80h
KEY_INFO_SEGMENT	= 40h
KEY_INFO_OFFSET		= 17h
COLOR			= 13

; --------------------
;|                    |
;|   	  Data        |
;|    Declarations    |
;|                    |
; --------------------

OldKeyDS	WORD	0
OldKeySS	WORD	0
OldKeySP	WORD	0
OldTimerDS	WORD	0
OldTimerSS	WORD	0
OldTimerSP	WORD	0
MySetupStack	WORD	100 dup(?)
MySetupSP	LABEL	WORD
MyKeyStack	WORD	100 dup(?)
MyKeySP		LABEL	WORD
MyTimerStack	WORD	100 dup(?)
MyTimerSP	LABEL	WORD
CmdLine		BYTE	130 dup(0)

OldKeyboardHandler 	LABEL	DWORD
OldKeyboardOffset	WORD	0
OldKeyboardSegment 	WORD	0
OldTimerHandler 	LABEL	DWORD
OldTimerOffset		WORD	0
OldTimerSegment 	WORD	0
SystemTime		LABEL	WORD
SystemHours		BYTE	0
SystemMinutes		BYTE	0
SystemSeconds		BYTE	0
SystemDLSavings		BYTE	0
OldScreenData		BYTE 	11 	dup(0)
ShouldPrintTime		BYTE	0
ExitSequencePressed	BYTE	0

AlreadyLoadedArray	BYTE	"DANIELLE", 0
AlreadyLoadedflag	BYTE	0

; --------------------
;|                    |
;|    WriteString     |
;|     (et. all)      |
;|                    |
; --------------------

WriteChar PROC
; Writes the character in dl
	push	ax
	push	bx
	push	cx
	pushf

	mov	al, dl			; AL = char to write
	mov	ah, BIOS_WRITE_CHAR	; AH = interrupt
	mov	bh, 0			; BH = video page
	mov	cx, 1			; CX = num. times to write
	int	BIOS			; write the character

	call	AdvanceCursor

	popf
	pop	cx
	pop	bx
	pop	ax
	ret
WriteChar ENDP

WriteColorChar PROC
; Writes the character in dl in a fancy color
	push	ax
	push	bx
	push	cx
	pushf

	mov	al, dl			; AL = char to write
	mov	ah, BIOS_WRITE_COLOR_CHAR	; AH = interrupt
	mov	bh, 0			; BH = video page
	mov	bl, COLOR
	mov	cx, 1			; CX = num. times to write
	int	BIOS			; write the character

	call	AdvanceCursor

	popf
	pop	cx
	pop	bx
	pop	ax
	ret
WriteColorChar ENDP

AdvanceCursor PROC
; Advances the cursor one space forward.
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	mov	bh, 0			; BH = video page
	mov	ah, BIOS_READ_CURSOR	; AH = interrupt
	int	BIOS			; DH = row, DL = column

	inc	DL			; DL = new column
	mov	ah, BIOS_WRITE_CURSOR	; AH = interrupt
	int	BIOS

	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
AdvanceCursor ENDP

WriteString PROC
; Writes the string whose offset is in dx.
	push	dx
	push	si
	pushf

	mov	si, dx
	jmp	cond
top:
	call	WriteChar
	inc	si
cond:
	mov	dl, [si]
	cmp	dl, 0
	ja	top

	popf
	pop	si
	pop	dx
	ret
WriteString ENDP

WriteColorString PROC
; Writes the string whose offset is in dx.
	push	dx
	push	si
	pushf

	mov	si, dx
	jmp	cond
top:
	call	WriteColorChar
	inc	si
cond:
	mov	dl, [si]
	cmp	dl, 0
	ja	top

	popf
	pop	si
	pop	dx
	ret
WriteColorString ENDP

NewLine PROC
; Prints a newline.
; This function is only used in testing.
	push	ax
	push	dx
	pushf

	mov	ah, 02h	; PrintCharacter DOS interrupt
	mov	dl, 13
	int	DOS
	
	mov	dl, 10
	int	DOS

	popf	
	pop	dx
	pop	ax
	ret
NewLine ENDP

; --------------------
;|                    |
;|      HexOut        |
;|     (et. all)      |
;|                    |
; --------------------

hexArray BYTE "0123456789ABCDEF", 0

WriteHexDigit PROC
; Writes the lower hex digit in dl
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	bx, dx
	and	bx, 000Fh
	mov	si, OFFSET hexArray
	mov	al, [si + bx]		; AL = char to write
	mov	ah, BIOS_WRITE_CHAR	; AH = interrupt
	mov	bh, 0			; BH = video page
	mov	cx, 1			; CX = num. times to write
	int	BIOS			; write the character

	call	AdvanceCursor

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
WriteHexDigit ENDP

WriteColorHexDigit PROC
; Writes the lower hex digit in dl
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	mov	bx, dx
	and	bx, 000Fh
	mov	si, OFFSET hexArray
	mov	al, [si + bx]			; AL = char to write
	mov	ah, BIOS_WRITE_COLOR_CHAR	; AH = interrupt
	mov	bh, 0				; BH = video page
	mov	bl, COLOR
	mov	cx, 1				; CX = num. times to write
	int	BIOS				; write the character

	call	AdvanceCursor

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
WriteColorHexDigit ENDP

HexOut PROC
; Expects the value in edx and the length (in bytes) in cx (between 1 and 4)

	push	ax
	push	bx
	push	cx
	push	edx
	push	esi
	pushf

	mov	bx, cx		; Keep track of count here, we need cl for shr
	mov	esi, edx	; Store the original value in esi
	jmp	cond

top:
	mov	cl, bl		; Do math to take care of little-endian
	dec	cl
	mov	al, 8
	mul	cl
	mov	cl, al		; End Math (now cl is the shifting amount)

	mov	edx, esi
	shr	edx, cl
	shr	edx, 4		; Isolate the top nybble
	call	WriteHexDigit	; Write the first hex digit

	mov	edx, esi
	shr	edx, cl		; Little Endian again
	call	WriteHexDigit	; Write the second hex digit

	dec	bx
cond:
	cmp	bx, 0
	ja	top

	popf
	pop	esi
	pop	edx
	pop	cx
	pop	bx
	pop	ax
	ret
HexOut ENDP

ColorHexOut PROC
; Expects the value in edx and the length (in bytes) in cx (between 1 and 4)

	push	ax
	push	bx
	push	cx
	push	edx
	push	esi
	pushf

	mov	bx, cx		; Keep track of count here, we need cl for shr
	mov	esi, edx	; Store the original value in esi
	jmp	cond

top:
	mov	cl, bl		; Do math to take care of little-endian
	dec	cl
	mov	al, 8
	mul	cl
	mov	cl, al		; End Math (now cl is the shifting amount)

	mov	edx, esi
	shr	edx, cl
	shr	edx, 4		; Isolate the top nybble
	call	WriteColorHexDigit	; Write the first hex digit

	mov	edx, esi
	shr	edx, cl		; Little Endian again
	call	WriteColorHexDigit	; Write the second hex digit

	dec	bx
cond:
	cmp	bx, 0
	ja	top

	popf
	pop	esi
	pop	edx
	pop	cx
	pop	bx
	pop	ax
	ret
ColorHexOut ENDP

WriteHexByte PROC
; Prints the hex digits of the byte whose value is in dl.
	push	cx
	pushf

	mov	cx, 1
	call	HexOut
	
	popf
	pop	cx
	ret
WriteHexByte ENDP

WriteColorHexByte PROC
; Prints the hex digits of the byte whose value is in dl.
	push	cx
	pushf

	mov	cx, 1
	call	ColorHexOut
	
	popf
	pop	cx
	ret
WriteColorHexByte ENDP

WriteHexWord PROC
; Prints the hex digits of the word whose value is in dx.
	push	cx
	pushf	

	mov	cx, 2
	call	HexOut
	
	popf
	pop	cx
	ret
WriteHexWord ENDP

WriteHexLong PROC
; Prints the hex digits of the double word whose value isin edx.
	push	cx
	pushf	

	mov	cx, 4
	call	HexOut
	
	popf
	pop	cx
	ret
WriteHexLong ENDP

; --------------------------
;|                          |
;|        Get Time          |
;|                          |
; --------------------------

GetSystemTime PROC
; Retrieves the system time and places it in memory

	push	ax
	push	cx
	push	dx
	pushf

	; CH = hours
	; CL = minutes
	; DH = seconds
	; DL = d.l. savings flag
	mov	ah, SYSTEM_GETTIME
	int	SYSTEM
	mov	SystemHours, ch
	mov	SystemMinutes, cl
	mov	SystemSeconds, dh
	mov	SystemDLSavings, dl

	popf
	pop	dx
	pop	cx
	pop	ax	
	ret
GetSystemTime ENDP

; --------------------------
;|                          |
;|       Print Time         |
;|                          |
; --------------------------
SystemHourLabel BYTE "AM", 0

PrintSystemTime PROC
; Prints the time stored in memory

	push	dx
	pushf
	
	mov	SystemHourLabel, "A"
	mov	SystemHourLabel + 1, "M"
	mov	SystemHourLabel + 2, 0

	mov	dl, SystemHours
	cmp	dl, 12h
	jna	am
	mov	SystemHourLabel, "P"
	cmp	dl, 19h
	ja	special
	sub	dl, 12h
	jmp	am

special:
	cmp	dl, 21h
	ja	special2
	sub	dl, 18h
	jmp	am
	
special2:
	sub	dl, 12h
am:
	call	WriteColorHexByte
	mov	dl, ":"
	call	WriteColorChar

	mov	dl, SystemMinutes
	call	WriteColorHexByte
	mov	dl, ":"
	call	WriteColorChar

	mov	dl, SystemSeconds
	call	WriteColorHexByte

	mov	dx, OFFSET SystemHourLabel
	call	WriteColorString

	popf
	pop	dx
	ret
PrintSystemTime ENDP

; --------------------------
;|                          |
;|     Cursor Routines      |
;|                          |
; --------------------------

GetCursorLoc  PROC
; Gets the cursor location. Puts the coords in dx.
	push	ax
	push	bx
	push	cx
	pushf

	mov	ah, BIOS_READ_CURSOR
	mov	bh, 0
	int	BIOS

	popf
	pop	cx
	pop	bx
	pop	ax
	ret
GetCursorLoc ENDP

SetCursorLoc  PROC
; Restore cursor location. Expects loc in dx
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	mov	ah, BIOS_WRITE_CURSOR
	mov	bh, 0
	int	BIOS

	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
SetCursorLoc ENDP

CursorToTopRight PROC
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	; Set cursor location
	mov	ah, BIOS_WRITE_CURSOR
	mov	bh, 0
	mov	dh, 00
	mov	dl, 70
	int	BIOS
		
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
CursorToTopRight ENDP

; --------------------------
;|                          |
;|      Display Time        |
;|                          |
; --------------------------

DisplayTime PROC
; Moves the cursor to the top right of the screen and prints the time there.
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	call	GetCursorLoc
	push	dx
	call	CursorToTopRight
	call	PrintSystemTime
	pop	dx
	call	SetCursorLoc
	
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
DisplayTime ENDP

; --------------------------
;|                          |
;|    Save Screen Data      |
;|                          |
; --------------------------

StoreScreenData PROC
; Fetches the information on the screen at the spot the time is displayed.

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	pushf	

	call	GetCursorLoc
	push	dx
	call	CursorToTopRight

	mov	di, OFFSET OldScreenData
	mov	cx, 10
top:
	; Get the character at the current location
	mov	ah, BIOS_GETSCRCONTENTS
	mov	bh, 00h
	int	BIOS
	mov	[di], al			; Copy the character over.
	call	AdvanceCursor
	inc	di
	dec	cx
	cmp	cx, 0
	ja	top
	
	pop	dx
	call	SetCursorLoc

	popf
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
StoreScreenData ENDP

; --------------------------
;|                          |
;|    Restore Screen Data   |
;|                          |
; --------------------------

RestoreScreenData PROC
; Restores that which was at the top of the screen before the time was output.

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	call	GetCursorLoc
	push	dx
	call	CursorToTopRight
	mov	dx, OFFSET OldScreenData
	call	WriteString
	pop	dx
	call	SetCursorLoc

	popf	
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
RestoreScreenData ENDP

; --------------------------
;|                          |
;|  	 Check Exit         |
;|    Sequence Pressed      |
;|                          |
; --------------------------

CheckExitSequencePressed PROC
; Checks if control and both shifts are currently pressed.
; Output:
; AL = 0 when it is not pressed
; AL = 1 when it is pressed

	push	dx
	push	es
	push	si
	pushf

	; Load the location of the keyboard information array
	mov	dx, KEY_INFO_SEGMENT
	mov	es, dx
	mov	si, KEY_INFO_OFFSET
	; Fetch the keyboard information array
	mov	dx, ES:[si]
	and	dx, 00000111b
	cmp	dx, 00000111b
	jnz	not_pressed
pressed:
	mov	al, 1
	jmp	done
not_pressed:
	mov	al, 0
done:
	popf	
	pop	si
	pop	es
	pop	dx	
	ret
CheckExitSequencePressed ENDP

; --------------------------
;|                          |
;|     Shifts Pressed       |
;|                          |
; --------------------------

ShiftsPressed PROC
; Checks if both shifts are currently pressed.
; Output:
; AL = 0 when they are not pressed
; AL = 1 when they are pressed

	push	dx
	push	es
	push	si
	pushf

	; Load the location of the keyboard information array
	mov	dx, KEY_INFO_SEGMENT
	mov	es, dx
	mov	si, KEY_INFO_OFFSET
	; Fetch the keyboard information array
	mov	dx, ES:[si]
	and	dx, 00000011b
	cmp	dx, 00000011b
	jnz	not_pressed
pressed:
	mov	al, 1
	jmp	done
not_pressed:
	mov	al, 0
done:
	popf	
	pop	si
	pop	es
	pop	dx	
	ret
ShiftsPressed ENDP

; --------------------------
;|                          |
;| Switch Should Print Time |
;|                          |
; --------------------------

SwitchShouldPrintTime PROC
; Switches the byte that dictates whether or not we print the time.

	pushf

	cmp	ShouldPrintTime, 0
	jz	to_one
to_zero:
	call	RestoreScreenData
	mov	ShouldPrintTime, 0
	jmp	done
to_one:
	call	StoreScreenData
	mov	ShouldPrintTime, 1

done:
	popf
	ret
SwitchShouldPrintTime ENDP

; --------------------------
;|                          |
;|       My Handlers        |
;|                          |
; --------------------------

ControlMessage BYTE "Exit sequence invoked! Terminating program.", 0

MyKeyboardHandler PROC
; This is my keyboard handler! It needs to hook in the old one at the end.
	cli
	mov	CS:OldKeySP, sp
	mov	CS:OldKeySS, ss
	mov	CS:OldKeyDS, ds

	sti
	push	cs
	pop	ds
	push	cs
	pop	ss
	mov	sp, OFFSET MyKeySP
	cli

	push	ax
	push	dx
	pushf

shifts:
	call	ShiftsPressed
	cmp	al, 1
	jnz	done
	call	SwitchShouldPrintTime
	jmp	done

quit:
	mov	ExitSequencePressed, 1
	mov	dx, OFFSET ControlMessage
	call	WriteString
done:
	popf
	pop	dx
	pop	ax
	
	sti
	mov	ss, CS:OldKeySS
	mov	sp, CS:OldKeySP
	mov	ds, CS:OldKeyDS
	jmp	DWORD PTR cs:OldKeyboardHandler
MyKeyboardHandler ENDP

MyTimerHandler PROC
; This is my timer handler! It needs to hook in the old one at the end.
	cli
	mov	CS:OldTimerSS, ss
	mov	CS:OldTimerSP, sp
	mov	CS:OldTimerDS, ds

	sti
	push	cs
	pop	ds
	push	cs
	pop	ss
	mov	sp, OFFSET MyTimerSP
	cli

	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	call	GetSystemTime
	
	cmp	ShouldPrintTime, 1
	jz	pressed

not_pressed:
	call	StoreScreenData
	call	RestoreScreenData
	jmp	done
pressed:
	call	DisplayTime
done:
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	sti
	mov	ss, CS:OldTimerSS
	mov	sp, CS:OldTimerSP
	mov	ds, CS:OldTimerDS
	jmp	DWORD PTR cs:OldTimerHandler
MyTimerHandler ENDP

; --------------------
;|                    |
;|   Show Interrupt   |
;|       Vector	      |
;|                    |
; --------------------

ShowInterruptVector PROC
; Takes a number on the stack an prints out the corresponging data in the IVT.
	push	bp
	mov	bp, sp

	push	cx
	push	dx
	push	es
	push	si

	ivt_number = 4
	mov	si, [bp + ivt_number]
	shl	si, 2			; Set IVT (mul. by 4 b/c width of IVT)
	mov	dx, 0
	mov	es, dx			; Set IVT segment

	mov	edx, ES:[si]
	mov	cl, 16
	shr	edx, 16
	call	WriteHexWord

	mov	dl, ":"
	call	WriteChar

	mov	edx, ES:[si]
	call	WriteHexWord

	pop	si
	pop	es
	pop	dx
	pop	cx
	pop	bp
	ret
ShowInterruptVector ENDP

; --------------------
;|                    |
;|    Get Interrupt   |
;|       Vector	      |
;|                    |
; --------------------

GetInterruptVector PROC
; Expects the following on the stack, sets the IVT based on this info:
; SP -> data_offset
;	ivt_number
;	ret. addr

	data_offset	= 4
	ivt_number	= 6

	push	bp
	mov	bp, sp

	push	cx
	push	dx
	push	di
	push	si
	push	ds
	push	es
	pushf

	; DS = IVT segment
	; SI = IVT num
	mov	si, [bp + ivt_number]
	shl	si, 2
	mov	dx, 0
	mov	ds, dx			; set ds to ivt segment

	; ES = CS
	mov	dx, cs
	mov	es, dx

	; DI = mem location
	mov	di, [bp + data_offset]

	mov	cx, 2
	cld
	cli				; prevent interrupts

	rep	movsw

	sti				; allow for interrupts

	popf
	pop	es
	pop	ds
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bp
	ret
GetInterruptVector ENDP

; --------------------
;|                    |
;|    Set Interrupt   |
;|       Vector	      |
;|                    |
; --------------------

SetInterruptVector PROC
; Expects the following on the stack, sets the IVT based on this info:
; SP -> ivt_offset
;	ivt_segment
;	ivt_number
;	ret. addr

	ivt_offset	= 4
	ivt_segment	= 6
	ivt_number	= 8

	push	bp
	mov	bp, sp

	push	cx
	push	dx
	push	di
	push	si
	push	ds
	push	es
	pushf

	mov	cx, [bp + ivt_segment]
	mov	dx, [bp + ivt_offset]
	push	cx			; push segment for copying
	push	dx			; push offset for copying

	mov	si, sp
	mov	dx, ss
	mov	ds, dx			; set ds to ss for movsw

	mov	dx, 0
	mov	es, dx			; set es to IVT location

	mov	di, [bp + ivt_number]; set di to correct location
	shl	di, 2			; mul. by 4 b/c of IVT width

	mov	cx, 2
	cld
	cli				; prevent interrupts

	rep	movsw

	sti				; allow for interrupts

	pop	dx			; restore stack (partially)
	pop	cx

	popf
	pop	es
	pop	ds
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bp
	ret
SetInterruptVector ENDP

; --------------------
;|                    |
;|   Save Keyboard    |
;|      Handler	      |
;|                    |
; --------------------

SaveKeyboardHandler PROC
; Fetches the keyboard handler and stores it in memory.
	push	cx
	push	dx
	pushf

	mov	cx, OFFSET OldKeyboardHandler
	mov	dx, KEYHANDLER
	push	dx			; Push IVT number
	push	cx			; Push data offset
	call	GetInterruptVector
	add	sp, 4

	popf
	pop	dx
	pop	cx
	ret
SaveKeyboardHandler ENDP

; --------------------
;|                    |
;|     Save Timer     |
;|       Handler      |
;|                    |
; --------------------

SaveTimerHandler PROC
; Fetches the timer handler and stores it in memory.
	push	cx
	push	dx
	pushf

	mov	cx, OFFSET OldTimerHandler
	mov	dx, TIMERHANDLER
	push	dx			; Push IVT number
	push	cx			; Push data offset
	call	GetInterruptVector
	add	sp, 4

	popf
	pop	dx
	pop	cx
	ret
SaveTimerHandler ENDP

; --------------------
;|                    |
;|  Install Keyboard  |
;|      Handler       |
;|                    |
; --------------------

InstallKeyboardHandler PROC
; Uses SetInterruptVector to install my keyboard handler.
	push	ax
	push	bx
	push	cx
	pushf

	mov	ax, KEYHANDLER			; Load the ivt_number.
	mov	bx, cs				; Load the ivt_segment (.code).
	mov	cx, OFFSET MyKeyboardHandler 	; Load the ivt_offset.
	push	ax
	push	bx
	push	cx

	call	SetInterruptVector
	add	sp, 6

	popf
	pop	cx
	pop	bx
	pop	ax
	ret
InstallKeyboardHandler ENDP

; --------------------
;|                    |
;|  Install Timer     |
;|      Handler       |
;|                    |
; --------------------

InstallTimerHandler PROC
; Uses SetInterruptVector to install my timer handler.
	push	ax
	push	bx
	push	cx
	pushf

	mov	ax, TIMERHANDLER			; Load the ivt_number.
	mov	bx, cs					; Load the ivt_segment (.code).
	mov	cx, OFFSET MyTimerHandler	 	; Load the ivt_offset.
	push	ax
	push	bx
	push	cx

	call	setInterruptVector
	add	sp, 6

	popf
	pop	cx
	pop	bx
	pop	ax
	ret
InstallTimerHandler ENDP

; --------------------
;|                    |
;|  Restore Keyboard  |
;|      Handler       |
;|                    |
; --------------------

RestoreKeyboardHandler PROC
; Retrieves the old keyboard vector and sets it in the IVT.
; Takes segment in es.

	push	dx
	push	es
	pushf

	mov	dx, KEYHANDLER
	push	dx
	push	ES:OldKeyboardSegment
	push	ES:OldKeyboardOffset
	call	SetInterruptVector
	add	sp, 6

	popf
	pop	es
	pop	dx
	ret
RestoreKeyboardHandler ENDP

; --------------------
;|                    |
;|    Restore Timer   |
;|       Handler      |
;|                    |
; --------------------

RestoreTimerHandler PROC
; Retrieves the old timer vector and sets it in the IVT

	push	dx
	pushf

	mov	dx, TIMERHANDLER
	push	dx
	push	ES:OldTimerSegment
	push	ES:OldTimerOffset
	call	SetInterruptVector
	add	sp, 6
	popf
	pop	dx
	ret
RestoreTimerHandler ENDP

; --------------------
;|                    |
;|       Wait On      |
;|    Exit Sequence   |
;|                    |
; --------------------
WaitingMessage BYTE "Waiting on exit sequence...", 0

WaitOnExitSequence PROC
; Waits for the CheckExitSequencePressed byte to be set to 1

	push	ax
	push	dx
	pushf	

;	mov	dx, OFFSET WaitingMessage
;	call	WriteString
;	call	NewLine

check:
	cmp	ExitSequencePressed, 1
	jnz	check

	popf
	pop	dx
	pop	ax
	ret
WaitOnExitSequence ENDP

; -------------------
;|                   |
;|  Already Loaded   |
;|     (et. all)     |
;|                   |
; -------------------

AlreadyLoadedMessage BYTE "Already loaded! Terminating.", 0
InstallMessage BYTE "Installing!", 0
UninstallMsg BYTE "Uninstalling!", 0
CannotUninstallMessage BYTE "Cannot uninstall - not loaded.", 0

AlreadyLoaded PROC

	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	si	
	pushf

	call	ClearCmdLineBuffer
	mov	si, OFFSET AlreadyLoadedArray
	call	SaveKeyboardHandler
	mov	es, OldKeyboardSegment
	mov	cx, 8

;Scan the arrays to see if we are loaded already
check_loaded:
	mov	al, [si]
	mov	bl, ES:[si]
	cmp	al, bl
	jnz	not_loaded
	dec	cx
	inc	si
cond:
	cmp	cx, 0
	ja	check_loaded

;If we ARE loaded, check to see if we want to uninstall.
loaded:
	call	GetCmdLine
	call	CleanUpCmdLine
	cmp	CmdLine, "-"
	jnz	do_not_load
	cmp	CmdLine + 1, "u"
	jnz 	do_not_load

	call	ClearCmdLineBuffer	
	mov	dx, OFFSET UninstallMsg
	call	WriteString
	call	ExitTSR
	mov	ax, DOS_EXIT
	int	DOS
	ret

do_not_load:
	call	ClearCmdLineBuffer	
	mov	dx, OFFSET AlreadyLoadedMessage
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
	ret

;If we AREN'T loaded, check to make sure we didn't want to uninstall.
not_loaded:
	call	GetCmdLine
	call	CleanUpCmdLine
	cmp	CmdLine, "-"
	jnz	install
	cmp	CmdLine + 1, "u"
	jz	cannot_uninstall

install:
	call	ClearCmdLineBuffer	
	mov	dx, OFFSET InstallMessage
	call	WriteString

done:
	popf
	pop	si
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax	
	ret

cannot_uninstall:
	call	ClearCmdLineBuffer	
	mov	dx, OFFSET CannotUninstallMessage
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
	ret
AlreadyLoaded ENDP

; -----------------
;|                 |
;|      TSR        |
;|                 |
; -----------------
TerminateStayResident PROC
	push	ax
	push	dx
	pushf

	mov	ax, TSR
	mov	dx, OFFSET EndTSR	; Calculate the # of paragraphs	
	shr	dx, 2			; Divide by 4
	inc	dx			; Add one
	int	DOS

	popf	
	pop	dx
	pop	ax
	ret
TerminateStayResident ENDP

; -----------------
;|                 |
;|     CmdLine     |
;|      Stuff      |
;|                 |
; -----------------

PrintCmdLine PROC
; Prints out the command line.

	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	si
	pushf

	; Print a character to signify the start of input
	mov	dl, "<"
	call	WriteChar		

	mov	ax, PSPPOINTER	; Get the offset of the psp into bx.
	int	DOS
	mov	es, bx
	mov	si, CMDTAIL
	mov	cl, ES:[si]	; Move the length of the cmd tail into cx.
	and 	cx, 00FFh
	inc	si
	jmp	cond

top:
	mov	dl, ES:[si]
	call	WriteChar		
	inc	si
	dec	cx
cond:
	cmp	cx, 0
	ja	top

	; Print a character to signify the end of input
	mov	dl, ">"
	call	WriteChar		
	call	NewLine

	popf
	pop	si
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PrintCmdLine ENDP

PrintCmdLineBuffer PROC
; Prints out the memory location of CmdLine
	
	push	dx
	pushf
	
	mov	dl, "{"
	call	WriteChar
	mov	dx, OFFSET CmdLine
	call	WriteString
	mov	dl, "}"
	call	WriteChar
	call	NewLine

	popf
	pop	dx
	ret
PrintCmdLineBuffer ENDP

ClearCmdLineBuffer PROC
; Clears the command line buffer in memory
	
	push	ax
	push	cx
	push	di
	pushf

	mov	cx, 130
	mov	di, OFFSET CmdLine
top:
	mov	al, 0
	mov	[di], al
	dec	cx
	inc	di
cond:
	cmp	cx, 0
	ja	top

done:
	popf
	pop	di
	pop	cx
	pop	ax
	ret
ClearCmdLineBuffer ENDP

ClearPSPCmdLineBuffer PROC
; Clears the command line buffer in memory
	
	push	ax
	push	cx
	push	di
	pushf

	mov	cx, 128
	mov	di, OFFSET CmdLine
top:
	mov	ax, PSPPOINTER	; Get the offset of the psp into bx.
	int	DOS
	mov	es, bx
	mov	di, CMDTAIL
	mov	al, 0
	mov	[di], al
	dec	cx
	inc	di
cond:
	cmp	cx, 0
	ja	top

done:
	popf
	pop	di
	pop	cx
	pop	ax
	ret
ClearPSPCmdLineBuffer ENDP

GetCmdLine PROC
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
	mov	di, OFFSET CmdLine
	mov	cl, al		; Move into cx the number of bytes to read.
	and	cx, 00FFh
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
	ja	top

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
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
	ret
GetCmdLine ENDP

SetCmdLine PROC
;Sets the first eight bytes of the command line buffer to DANIELLE

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
	mov	si, OFFSET AlreadyLoadedArray
	mov	di, CMDTAIL
	inc	di
	mov	cx, 8		; Move into cx the number of bytes to read.
	jmp	cond

top:
	mov	al, [si]
	mov	ES:[di], al
	inc	si
	inc	di
	dec	cx
cond:
	cmp	cx, 0
	ja	top

	popf	
	pop	es
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

SetCmdLine ENDP

CleanUpCmdLine PROC
; Takes the string in CmdLine and cleans it up to only include printable characters.

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	pushf

	mov	si, OFFSET CmdLine	; We want to start at the same point.
	mov	di, OFFSET CmdLine
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
CleanUpCmdLine ENDP

; -----------------
;|                 |
;|    Exit TSR     |
;|                 |
; -----------------
ExitTSR PROC
;CITE: Nathaniel
;DESC: General idea of this routine
	call	RestoreScreenData
	call	SaveKeyboardHandler
	mov	es, OldKeyboardSegment
	call	RestoreKeyboardHandler
	call	RestoreTimerHandler
	mov	ax, EXIT_TSR
	int	DOS
	ret
ExitTSR ENDP

SetupMessage BYTE "Segments setup. Installing handlers...", 0
HandlerMessage BYTE "Handlers installed; setup complete!", 0

EndTSR	LABEL	BYTE
;-----------------------------------------------------------------------------
;/////////////////////////////////////////////////////////////////////////////
;-----------------------------------------------------------------------------

setup:
	; DS = SS = CS
	mov	ax, cs
	mov	ds, ax
	mov	ss, ax
	mov	sp, OFFSET MySetupSP

	;mov	dx, OFFSET SetupMessage
	;call	WriteString
	;call	NewLine
	
; --------------------
;|                    |
;|    Pseudo-Main     |
;|                    |
; --------------------
main:
	call	AlreadyLoaded
	mov	AlreadyLoadedFlag, 1

	call	SaveKeyboardHandler
	call	SaveTimerHandler
	call	InstallKeyboardHandler
	call	InstallTimerHandler
	
	call	TerminateStayResident	

	ret
EndOfFile LABEL BYTE
END EntryPoint
