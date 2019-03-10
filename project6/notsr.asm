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
BIOS_WRITE_CHAR 	= 0Ah
BIOS_READ_CURSOR	= 03h
BIOS_WRITE_CURSOR	= 02h
BIOS_GETSCRCONTENTS	= 08h
BIOS_SETSCRCONTENTS	= 0Ah
KEYHANDLER		= 09h
TIMERHANDLER		= 08h

KEY_INFO_SEGMENT	= 40h
KEY_INFO_OFFSET		= 17h

; --------------------
;|                    |
;|   	  Data        |
;|    Declarations    |
;|                    |
; --------------------

OldDS	WORD	0
OldSS	WORD	0
OldSP	WORD	0
MyStack	WORD	100 dup(?)
MySP	LABEL	WORD

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

AlreadyLoadedArray	BYTE	9	dup(0)
AlreadyLoadedKey	BYTE	"DANIELLE", 0
AlreadyLoaded		BYTE	0

; --------------------------
;|                          |
;|          Delay           |
;|                          |
; --------------------------

FetchTime PROC
; Retrieves the system time and places it in cx + dx

	push	ax
	mov	ah, DOS_GETTIME
	int	DOS
	pop	ax
	ret
FetchTime ENDP

SetEndTime PROC
; Expects the millisecond interval to be in si. Sets ax and bx to the
; current time (expected in cx and dx) plus the interval

	pushf
	mov 	ax, cx
	mov	bx, dx

top:
	sub	si, 10
	inc	bl
	call	CarryTime
	cmp	si, 0
	ja	top

	popf
	ret
SetEndTime ENDP

CarryTime PROC
; Expects the time to be in ax and bx. Makes sure nothing is over its limit.
	pushf
centi:
	cmp	bl, 100			; Check if centiseconds is too high.
	jb	done
	inc	bh
	and	bx, 0FF00h		; Set centiseconds to zero.
secs:
	cmp	bh, 60			; Check if seconds is too high
	jb	done
	inc	al
	and	bx, 00FFh		; Set seconds to zero.
mins:
	cmp	al, 60			; Check minutes.
	jb	done
	inc	ah
	and	ax, 0FF00h		; Clear minutes.
hrs:
	cmp	ah, 24
	jb	done
	and	ax, 00FFh
	mov	di, 1

done:
	popf
	ret
CarryTime ENDP

Delay PROC
	call	FetchTime
	push	bp
	mov	bp, sp

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	pushf

	mov	si, [bp + 4]
	mov	di, 0				; clear midnight flag
	call	SetEndTime			; this could set di

top:
	call	FetchTime
	cmp	di, 1
	jb	normalcheck
	cmp	ch, 0
	ja	top

normalcheck:
	cmp	cx, ax
	ja	done
	jb	top
	cmp	dx, bx
	ja	done
	jb	top

done:
	popf
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret
Delay ENDP

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

WriteHexByte PROC
; Prints the hex digits of the byte whose value is in dl.
	push	cx
	mov	cx, 1
	call	HexOut
	pop	cx
	ret
WriteHexByte ENDP

WriteHexWord PROC
; Prints the hex digits of the word whose value is in dx.
	push	cx
	mov	cx, 2
	call	HexOut
	pop	cx
	ret
WriteHexWord ENDP

WriteHexLong PROC
; Prints the hex digits of the double word whose value isin edx.
	push	cx
	mov	cx, 4
	call	HexOut
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
	call	WriteHexByte
	mov	dl, ":"
	call	WriteChar

	mov	dl, SystemMinutes
	call	WriteHexByte
	mov	dl, ":"
	call	WriteChar

	mov	dl, SystemSeconds
	call	WriteHexByte

	mov	dx, OFFSET SystemHourLabel
	call	WriteString

	mov	SystemHourLabel, "A"	; Restore label
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

	mov	ah, BIOS_READ_CURSOR
	mov	bh, 0
	int	BIOS

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

	mov	ah, BIOS_WRITE_CURSOR
	mov	bh, 0
	int	BIOS

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
	mov	ShouldPrintTime, 0
	jmp	done
to_one:
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
	sti
	mov	CS:OldSS, ss
	mov	CS:OldSP, sp
	mov	CS:OldDS, ds

	push	cs
	pop	ds
	push	cs
	pop	ss
	mov	sp, OFFSET MySP
	sub	sp, 50

	push	ax
	pushf

	call	CheckExitSequencePressed
	cmp	al, 1
	jz	quit
	mov	ExitSequencePressed, 0

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
	pop	ax
	
	cli
	mov	ss, CS:OldSS
	mov	sp, CS:OldSP
	mov	ds, CS:OldDS
	jmp	DWORD PTR cs:OldKeyboardHandler
MyKeyboardHandler ENDP

MyTimerHandler PROC
; This is my timer handler! It needs to hook in the old one at the end.
	sti
	mov	CS:OldSS, ss
	mov	CS:OldSP, sp
	mov	CS:OldDS, ds

	cli
	push	cs
	pop	ds
	push	cs
	pop	ss
	mov	sp, OFFSET MySP
	sub	sp, 50
	sti

	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	call	GetSystemTime

	cmp	ShouldPrintTime, 1
	jz	pressed

not_pressed:
	call	RestoreScreenData
	call	StoreScreenData
	jmp	done
pressed:
	call	DisplayTime
done:
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	cli
	mov	ss, CS:OldSS
	mov	sp, CS:OldSP
	mov	ds, CS:OldDS
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

	mov	di, [bp + ivt_number]	; set di to correct location
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
	mov	cx, MyKeyboardHandler	 	; Load the ivt_offset.
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
	mov	bx, cs				; Load the ivt_segment (.code).
	mov	cx, MyTimerHandler	 	; Load the ivt_offset.
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
; Retrieves the old keyboard vector and sets it in the IVT

	push	dx
	pushf

	mov	dx, KEYHANDLER
	push	dx
	push	OldKeyboardSegment
	push	OldKeyboardOffset
	call	SetInterruptVector
	add	sp, 6

	popf
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
	push	OldTimerSegment
	push	OldTimerOffset
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
	pushf	

	mov	dx, OFFSET WaitingMessage
	call	WriteString
	call	NewLine

check:
	cmp	ExitSequencePressed, 1
	jnz	check

	popf	
	pop	ax
	ret
WaitOnExitSequence ENDP

; -------------------
;|                   |
;|  Already Loaded   |
;|     (et. all)     |
;|                   |
; -------------------

UpdateAlreadyLoaded PROC
; This compares the two arrays, AlreadyLoadedArray and AlreadyLoadedKey. 
; It sets the byte AlreadyLoaded to 1 if they are equal and 0 if they are not.

	push	cx
	push	dx
	push	di
	push	si
	pushf

	mov	cx, 8	; Length of the arrays
	mov	AlreadyLoaded, 0

	mov	di, OFFSET AlreadyLoadedArray
	mov	si, OFFSET AlreadyLoadedKey

top:
	mov	dl, [di]
	mov	dh, [si]
	cmp	dl, dh
	jnz	bottom
	dec	cx
	inc	di
	inc	si

cond:
	cmp	cx, 0
	ja	top
	mov	AlreadyLoaded, 1

bottom:
	popf
	pop	si
	pop	di
	pop	dx
	pop	cx
	ret
UpdateAlreadyLoaded ENDP

AlreadyLoadedMessage 	BYTE	 "Already loaded! Terminating.", 0

CheckAlreadyLoaded PROC
; Checks whether we are already loaded. Terminates if we are.

	pushf
	call	UpdateAlreadyLoaded
	cmp	AlreadyLoaded, 1
	jz	quit

done:
	popf
	ret
	
quit:
	mov	dx, OFFSET AlreadyLoadedMessage
	call	WriteString	
	mov	ax, DOS_EXIT
	int	DOS
CheckAlreadyLoaded ENDP

SetAlreadyLoaded PROC
; Set AlreadyLoadedArray to AlreadyLoadedKey.
	push	cx
	push	dx
	push	di
	push	si
	pushf

	mov	si, OFFSET AlreadyLoadedKey
	mov	di, OFFSET AlreadyLoadedArray
	mov	cx, 8

top:
	mov	dl, [si]
	mov	[di], dl
	dec	cx
	inc	si
	inc	di

cond:
	cmp	cx, 0
	ja	top

	popf
	pop	si	
	pop	di
	pop	dx	
	pop	cx
	ret
SetAlreadyLoaded ENDP

SetupMessage BYTE "Segments setup. Installing handlers...", 0
HandlerMessage BYTE "Handlers installed; setup complete!", 0

EndTSR	LABEL	BYTE
;-----------------------------------------------------------------------------
;/////////////////////////////////////////////////////////////////////////////
;-----------------------------------------------------------------------------

setup:
	; DS, SS = CS
	mov	ax, cs
	mov	ds, ax
	mov	ss, ax
	mov	sp, OFFSET MySP

	mov	dx, OFFSET SetupMessage
	call	WriteString
	call	NewLine
	
; --------------------
;|                    |
;|    Pseudo-Main     |
;|                    |
; --------------------
main:
	call	CheckAlreadyLoaded
	call	SetAlreadyLoaded

	call	SaveKeyboardHandler
	call	SaveTimerHandler
	call	InstallKeyboardHandler
	call	InstallTimerHandler

	mov	dx, OFFSET HandlerMessage
	call	WriteString
	call	NewLine

	call	WaitOnExitSequence
	call	RestoreKeyboardHandler
	call	RestoreTimerHandler

	mov	ax, DOS_EXIT
	int 	DOS
END EntryPoint
