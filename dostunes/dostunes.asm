; Name: Jack Scacco
; Assignment: Project 7
; Due Date: 11/12/18
; File: music.asm

INCLUDE CS240.inc
.386

BIOS			= 10h
DOS 			= 21h
DOS_EXIT		= 4C00h

TIMER			= 15h
TIMER_WAIT		= 86h
ONE_SECOND		= 1000000
ONE_MINUTE		= 60000000

FREQUENCY		= 1193180

READY_TIMER		= 0B6h
TIMER_DATA_PORT		= 42h
TIMER_CONTROL_PORT	= 43h
SPEAKER_PORT 		= 61h

PSPPOINTER	= 6200h
CMDTAIL		= 80h
OPENF 		= 3D00h
CLOSEF 		= 3E00h
READF 		= 3F00h
CARRIAGERET	= 0Dh
PRINTCHR	= 02h
READ_CHAR	= 01h

.data
FileName BYTE 127 dup(0)
FileHandle WORD ?

Muted 			BYTE 	0
WaitInterval 		LABEL 	DWORD
WaitTop 		WORD 	0
WaitBot 		WORD 	0

TimeSignature		BYTE	0, 0
BPM 			WORD 	0
BeatLength		DWORD	0

WholeNoteLength		DWORD	0
HalfNoteLength		DWORD	0
QuarterNoteLength	DWORD	0
EighthNoteLength	DWORD	0
SixteenthNoteLength	DWORD	0
ThirtysecondNoteLength	DWORD	0

CurrentOctave		BYTE	0
CurrentNote		BYTE	0
CurrentAccidental	BYTE	0
CurrentLength		BYTE	0

KeySigNote		BYTE	0, 0
KeySigAccidental	BYTE	0
KeySigNumber		BYTE	0

CurrentLine		BYTE 	0 dup(10)
TrashBuffer		BYTE	0 dup(10)
Note1			BYTE	"C	4	W"
Note2			BYTE	"F	4	W"
Note3			BYTE	"G	4	W"

CurrentPixelOffset	WORD	0
;-----------------------------------------------------------------------------
;\\\\\\\\\\\\\\\\\\ Notes -> Count \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------------------------------
;		A	A#	B	C	C#	D	D#	E	F	F#	G	G#
Octave1 WORD	43388,	40961,	38664,	36489,	34445,	32512,	30681,	28961,	27335,	25804,	24356,	22986
Octave2 WORD	21694,	20477,	19327,	18243,	17219,	16254,	15340,	14479,	13666,	12899,	12177,	11492
Octave3 WORD	10847,	10238,	9664,	9121,	8609,	8126,	7670,	7240,	6833,	6450,	6088,	5746
Octave4 WORD	5424,	5119,	4831,	4554,	4305,	4064,	3835,	3620,	3417,	3225,	3044,	2873
Octave5 WORD	2712,	2560,	2416,	2280,	2152,	2032,	1918,	1810,	1708,	1612,	1522,	1437
Octave6 WORD	1356,	1280,	1208,	1140,	1076,	1016,	959,	905,	854,	806,	761,	718
Octave7	WORD	678,	640,	604,	570,	538,	508,	479,	452,	427,	403,	380,	359
Octave8 WORD	339,	320,	302,	285

;-----------------------------------------------------------------------------
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------------------------------

CurrentPixel WORD 0

Pixels	WORD	13, 20, 100
	WORD	13, 20, 102
	WORD	15, 20, 104
	WORD	15, 20, 106
	WORD	3, 20,  108
	WORD	5, 44,  108
	WORD	3, 20,  110
	WORD	5, 44,  110
	WORD	3, 20,  112
	WORD	5, 44,  112
	WORD	3, 20,  114
	WORD	5, 44,  114
	WORD	3, 20,  116
	WORD	5, 44,  116
	WORD	3, 20,  118
	WORD	5, 44,  118
	WORD	3, 20,  120
	WORD	5, 44,  120
	WORD	3, 20,  122
	WORD	5, 44,  122
	WORD	3, 20,  124
	WORD	5, 44,  124
	WORD	3, 20,  126
	WORD	5, 44,  126
	WORD	3, 20,  128
	WORD	5, 44,  128
	WORD	3, 20,  130
	WORD	5, 44,  130
	WORD	3, 20,  132
	WORD	5, 44,  132
	WORD	3, 20,  134
	WORD	5, 44,  134
	WORD	3, 20,  136
	WORD	5, 44,  136
	WORD	3, 20,  138
	WORD	5, 44,  138
	WORD	3, 20,  140
	WORD	5, 44,  140
	WORD	15, 20, 142
	WORD	15, 20, 144
	WORD	13, 20, 146
	WORD	13, 20, 148

	WORD	9, 60, 132
	WORD	9, 60, 134
	WORD	2, 60, 136
	WORD	2, 74, 136
	WORD	2, 60, 138
	WORD	2, 74, 138
	WORD	2, 60, 140
	WORD	2, 74, 140
	WORD	2, 60, 142
	WORD	2, 74, 142
	WORD	2, 60, 144
	WORD	2, 74, 144
	WORD	9, 60, 146
	WORD	9, 60, 148

	WORD	7, 84, 132
	WORD	7, 84, 134
	WORD	2, 84, 136
	WORD	7, 84, 138
	WORD	7, 84, 140
	WORD	2, 94, 142
	WORD	2, 94, 144
	WORD	7, 84, 146
	WORD	7, 84, 148

	WORD	2, 108, 114
	WORD	2, 108, 116
	WORD	2, 108, 118
	WORD	2, 108, 120
	WORD	2, 108, 122
	WORD	2, 108, 124
	WORD	2, 108, 126
	WORD	2, 108, 128
	WORD	2, 108, 130
	WORD	6, 104, 132
	WORD	6, 104, 134
	WORD	2, 108, 136
	WORD	2, 108, 138
	WORD	2, 108, 140
	WORD	2, 108, 142
	WORD	2, 108, 144
	WORD	2, 108, 146
	WORD	2, 108, 148

	WORD	2, 120, 132
	WORD	2, 128, 132	
	WORD	2, 120, 134
	WORD	2, 128, 134
	WORD	2, 120, 136
	WORD	2, 128, 136
	WORD	2, 120, 138
	WORD	2, 128, 138
	WORD	2, 120, 140
	WORD	2, 128, 140
	WORD	2, 120, 142
	WORD	2, 128, 142
	WORD	2, 120, 144
	WORD	2, 128, 144
	WORD	7, 120, 146
	WORD	7, 120, 148

	WORD	2, 138, 132
	WORD	6, 138, 134
	WORD	6, 138, 136
	WORD	2, 138, 138
	WORD	2, 146, 138
	WORD	2, 138, 140
	WORD	2, 146, 140
	WORD	2, 138, 142
	WORD	2, 146, 142
	WORD	2, 138, 144
	WORD	2, 146, 144
	WORD	2, 138, 146
	WORD	2, 146, 146
	WORD	2, 138, 148
	WORD	2, 146, 148

	WORD	6, 158, 132
	WORD	3, 156, 134
	WORD	2, 168, 134
	WORD	3, 156, 136
	WORD	1, 170, 136
	WORD	8, 156, 138
	WORD	8, 156, 140
	WORD	3, 156, 142
	WORD	3, 156, 144
	WORD	7, 158, 146
	WORD	6, 158, 148

	WORD	7, 176, 132
	WORD	7, 176, 134
	WORD	2, 176, 136
	WORD	7, 176, 138
	WORD	7, 176, 140
	WORD	2, 186, 142
	WORD	2, 186, 144
	WORD	7, 176, 146
	WORD	7, 176, 148
EndPixels	LABEL	WORD

	WORD	54, 20
	WORD	55, 20

	WORD	56, 20
	WORD	57, 20
	WORD	58, 20
	WORD	59, 20
	WORD	60, 20
	WORD	61, 20
	WORD	62, 20
	WORD 	164, 104
	WORD	165, 105
	WORD	166, 106
	WORD	167, 107
	WORD 	168, 108
	WORD	169, 109
	WORD	170, 110

	WORD	0, 0
	WORD 	0, 0
	WORD	0, 0
	WORD	0, 0
	WORD	0, 0
	WORD 	0, 0
	WORD	0, 0
	WORD	0, 0
	WORD	0, 0
	WORD 	0, 0
.code

; ---------------------
;|		       |
;|    File Reading     |
;|	Stuff	       |
;|		       |
; ---------------------

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
	and	ax, 00FFh
	mov	cx, ax		; Move into cs the number of bytes to read.
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
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
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
	call	WriteString	; Print Message
	popf			; Restore state
	pop	dx
	mov	ax, DOS_EXIT	; Exit DOS
	int	DOS
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

ReadNextLine PROC
; Reads the next line from the file and places it in CurrentLine
; Does not preserve ax (bc it's the num. read), nor does it update offset.

	push	bx
	push	cx
	push	dx
	push	di
	pushf

	mov	di, OFFSET CurrentLine

top:

	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, di
	int	DOS

	mov	bl, 0Ah
	inc	di
	cmp	[di - 1], bl
	jnz	top

	mov	bl, "!"
	mov	[di - 1], bl
	mov	bl, 0
	mov	[di - 2], bl

	popf
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
ReadNextLine ENDP

; --------------------
;|                    |
;|    Mute/Unmute     |
;|      Speaker       |
;|                    |
; --------------------
MuteSpeaker PROC
	pushf
	mov	Muted, 1
	popf
	ret
MuteSpeaker ENDP

UnmuteSpeaker PROC
	pushf
	mov	Muted, 1
	popf
	ret
UnmuteSpeaker ENDP

; --------------------
;|                    |
;|      Speaker       |
;|      On/Off        |
;|                    |
; --------------------
SpeakerOn PROC
	push	ax
	pushf

	cmp	Muted, 1
	jz	done

	in	al, SPEAKER_PORT
	or	al, 03h
	out	SPEAKER_PORT, al

done:
	popf
	pop	ax
	ret
SpeakerOn ENDP

SpeakerOff PROC
	push	ax
	pushf

	in	al, SPEAKER_PORT
	and	al, 0FCh
	out	SPEAKER_PORT, al

	popf
	pop	ax
	ret
SpeakerOff ENDP

; --------------------
;|                    |
;|       Play         |
;|       Count        |
;|                    |
; --------------------
PlayCount PROC
; Frequency is found in dx

	push	ax
	pushf

	mov	al, READY_TIMER			; Get the timer ready
	out	TIMER_CONTROL_PORT, al

	mov	al, dl
	out	TIMER_DATA_PORT, al

	mov	al, dh
	out	TIMER_DATA_PORT, al

	popf
	pop	ax
	ret
PlayCount ENDP

; --------------------
;|                    |
;|       Delay        |
;|                    |
; --------------------
Delay PROC
; Expects the value in microseconds to be in WaitInterval. Delays that long.

	push	ax
	push	cx
	push	dx
	pushf

	mov	ah, TIMER_WAIT
	mov	cx, WaitBot
	mov	dx, WaitTop
	int	TIMER

	popf
	pop	dx
	pop	cx
	pop	ax
	ret
Delay ENDP

; --------------------
;|                    |
;|     Store Beat     |
;|    Information     |
;|                    |
; --------------------

StoreBeatInfo PROC
; Stores it, and the the beat length, in memory.
	push	eax
	push	ecx
	push	edx
	push	di
	pushf

	mov	di, OFFSET BPM
	mov	[di], dx

	mov	ecx, edx		; Use ecx because edx is used in div
	mov	eax, ONE_MINUTE
	mov	edx, 0
	div	ecx

	mov	di, OFFSET BeatLength	; Store BeatLength in memory
	mov	[di], eax

	popf
	pop	di
	pop	edx
	pop	ecx
	pop	eax
	ret
StoreBeatInfo ENDP

; --------------------
;|                    |
;|     Set Note       |
;|     Lengths        |
;|                    |
; --------------------

BootstrapNotes PROC
; Sets all notes based on the 1/16 note.
; Expects the 1/16 length to be set in memory.

	push	edx
	push	di
	push	si
	pushf

	mov	si, OFFSET SixteenthNoteLength
	mov	edx, [si]			; Load 1/16 length
	shr	edx, 1
	mov	di, OFFSET ThirtysecondNoteLength
	mov	[di], edx

	mov	si, OFFSET SixteenthNoteLength
	mov	edx, [si]			; Load 1/16 length

	shl	edx, 1				; Double it for 1/8 length
	mov	di, OFFSET EighthNoteLength
	mov	[di], edx			; Set 1/8 length

	shl	edx, 1				; Double it for 1/4 length
	mov	di, OFFSET QuarterNoteLength
	mov	[di], edx			; Set 1/4 length

	shl	edx, 1				; Double it for 1/2 length
	mov	di, OFFSET HalfNoteLength
	mov	[di], edx			; Set 1/2 length

	shl	edx, 1				; Double it for whole length
	mov	di, OFFSET WholeNoteLength
	mov	[di], edx			; Set whole length

	popf
	pop	si
	pop	di
	pop	edx
	ret
BootstrapNotes ENDP

SetNoteLengths PROC
; Sets the note lengths in memory based on the time signature in memory.

	push	eax
	push	edx
	push	di
	push	si
	pushf

	mov	si, OFFSET TimeSignature
	inc	si
	mov	al, [si]		; Load the bottom half of time sig.

	cmp	al, 2
	jz	half

	cmp	al, 4
	jz	quarter

	cmp	al, 8
	jz	eighth

	cmp	al, 16
	jz	sixteenth

half:
	mov	si, OFFSET BeatLength
	mov	di, OFFSET SixteenthNoteLength
	mov	edx, [si]
	shr	edx, 3				; Eight 1/16 per 1/8
	mov	[di], edx
	call	BootstrapNotes
	jmp	done

quarter:
	mov	si, OFFSET BeatLength
	mov	di, OFFSET SixteenthNoteLength
	mov	edx, [si]
	shr	edx, 2				; Four 1/16 per 1/8
	mov	[di], edx
	call	BootstrapNotes
	jmp	done

eighth:
	mov	si, OFFSET BeatLength
	mov	di, OFFSET SixteenthNoteLength
	mov	edx, [si]
	shr	edx, 1				; Two 1/16 per 1/8
	mov	[di], edx
	call	BootstrapNotes
	jmp	done

sixteenth:
	mov	si, OFFSET BeatLength
	mov	di, OFFSET SixteenthNoteLength
	mov	edx, [si]
	mov	[di], edx
	call	BootstrapNotes

done:
	popf
	pop	si
	pop	di
	pop	edx
	pop	eax
	ret
SetNoteLengths ENDP

; --------------------
;|                    |
;|    Set Key Num.    |
;|                    |
; --------------------
.data
KeyAccidentalErrorMsg BYTE "Invalid key signature accidental! Terminating.", 0
KeyNoteErrorMsg BYTE "Invalid key signature note! Terminating.", 0
.code
SetKeyNumber PROC
; Set the KeySigNumber value in memory

	pushf

	cmp	KeySigAccidental, "b"
	jz	flats
	cmp	KeySigAccidental, "#"
	jz	sharps
	cmp	KeySigAccidental, "0"
	jz	none
	jmp	accidental_error


sharps:
check_C:
	cmp	KeySigNote, "C"
	jnz	check_am
	cmp	KeySigNote + 1, "#"
	jz	check_Cs
	mov	KeySigNumber, 0
	jmp	done
check_am:
	cmp	KeySigNote, "a"
	jnz	check_G
	cmp	KeySigNote + 1, "b"
	jz	check_asm
	mov	KeySigNumber, 0
	jmp	done
check_G:
	cmp	KeySigNote, "G"
	jnz	check_em
	mov	KeySigNumber, 1
	jmp	done
check_em:
	cmp	KeySigNote, "e"
	jnz	check_D
	mov	KeySigNumber, 1
	jmp	done
check_D:
	cmp	KeySigNote, "D"
	jnz	check_bm
	mov	KeySigNumber, 2
	jmp	done
check_bm:
	cmp	KeySigNote, "b"
	jnz	check_A
	mov	KeySigNumber, 2
	jmp	done
check_A:
	cmp	KeySigNote, "A"
	jnz	check_fsm
	mov	KeySigNumber, 3
	jmp	done
check_fsm:
	cmp	KeySigNote, "f"
	jnz	check_E
	cmp	KeySigNote + 1, "#"
	jnz	check_E
	mov	KeySigNumber, 3
	jmp	done
check_E:
	cmp	KeySigNote, "E"
	jnz	check_csm
	mov	KeySigNumber, 4
	jmp	done
check_csm:
	cmp	KeySigNote, "c"
	jnz	check_B
	cmp	KeySigNote + 1, "#"
	jnz	check_B
	mov	KeySigNumber, 4
	jmp	done
check_B:
	cmp	KeySigNote, "B"
	jnz	check_gsm
	mov	KeySigNumber, 5
	jmp	done
check_gsm:
	cmp	KeySigNote, "g"
	jnz	check_Fs
	cmp	KeySigNote + 1, "#"
	jnz	check_Fs
	mov	KeySigNumber, 5
	jmp	done
check_Fs:
	cmp	KeySigNote, "F"
	jnz	check_dsm
	cmp	KeySigNote + 1, "#"
	jnz	check_dsm
	mov	KeySigNumber, 6
	jmp	done
check_dsm:
	cmp	KeySigNote, "d"
	jnz	check_Cs
	cmp	KeySigNote + 1, "#"
	jnz	check_Cs
	mov	KeySigNumber, 6
	jmp	done
check_Cs:
	cmp	KeySigNote, "C"
	jnz	check_asm
	cmp	KeySigNote + 1, "#"
	jnz	check_asm
	mov	KeySigNumber, 7
	jmp	done
check_asm:
	cmp	KeySigNote, "a"
	jnz	note_error
	cmp	KeySigNote + 1, "#"
	jnz	note_error
	mov	KeySigNumber, 7
	jmp	done

flats:
check_C2:
	cmp	KeySigNote, "C"
	jnz	check_am2
	cmp	KeySigNote + 1, "b"
	jz	check_Cf
	mov	KeySigNumber, 0
	jmp	done
check_am2:
	cmp	KeySigNote, "a"
	jnz	check_F
	cmp	KeySigNote + 1, "b"
	jz	check_afm
	mov	KeySigNumber, 0
	jmp	done
check_F:
	cmp	KeySigNote, "F"
	jnz	check_dm
	mov	KeySigNumber, 1
	jmp	done
check_dm:
	cmp	KeySigNote, "d"
	jnz	check_Bf
	mov	KeySigNumber, 1
	jmp	done
check_Bf:
	cmp	KeySigNote, "B"
	jnz	check_gm
	cmp	KeySigNote + 1, "b"
	jnz	check_gm
	mov	KeySigNumber, 2
	jmp	done
check_gm:
	cmp	KeySigNote, "g"
	jnz	check_Ef
	mov	KeySigNumber, 2
	jmp	done
check_Ef:
	cmp	KeySigNote, "E"
	jnz	check_cm
	cmp	KeySigNote + 1, "b"
	jnz	check_cm
	mov	KeySigNumber, 3
	jmp	done
check_cm:
	cmp	KeySigNote, "c"
	jnz	check_Af
	mov	KeySigNumber, 3
	jmp	done
check_Af:
	cmp	KeySigNote, "A"
	jnz	check_fm
	cmp	KeySigNote + 1, "#"
	jnz	check_fm
	mov	KeySigNumber, 4
	jmp	done
check_fm:
	cmp	KeySigNote, "f"
	jnz	check_Df
	mov	KeySigNumber, 4
	jmp	done
check_Df:
	cmp	KeySigNote, "D"
	jnz	check_bfm
	cmp	KeySigNote + 1, "b"
	jnz	check_bfm
	mov	KeySigNumber, 5
	jmp	done
check_bfm:
	cmp	KeySigNote, "b"
	jnz	check_Gf
	cmp	KeySigNote + 1, "b"
	jnz	check_Gf
	mov	KeySigNumber, 5
	jmp	done
check_Gf:
	cmp	KeySigNote, "G"
	jnz	check_cfm
	cmp	KeySigNote + 1, "b"
	jnz	check_cfm
	mov	KeySigNumber, 6
	jmp	done
check_cfm:
	cmp	KeySigNote, "c"
	jnz	check_Cf
	cmp	KeySigNote + 1, "b"
	jnz	check_Cf
	mov	KeySigNumber, 6
	jmp	done
check_Cf:
	cmp	KeySigNote, "C"
	jnz	check_afm
	cmp	KeySigNote + 1, "b"
	jnz	check_afm
	mov	KeySigNumber, 7
	jmp	done
check_afm:
	cmp	KeySigNote, "a"
	jnz	note_error
	cmp	KeySigNote + 1, "b"
	jnz	note_error
	mov	KeySigNumber, 7
	jmp	done

none:
	mov	KeySigNumber, 0
done:
	popf
	ret

accidental_error:
	mov	dx, OFFSET KeyAccidentalErrorMsg
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
note_error:
	mov	dx, OFFSET KeyNoteErrorMsg
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
SetKeyNumber ENDP

; --------------------
;|                    |
;|     PlayNote       |
;|                    |
; --------------------

.data
NoteErrorMsg BYTE "Unacceptable note! Terminating.", 0
LengthErrorMsg BYTE "Unacceptable note length! Terminating.", 0
.code
PlayNote PROC
; Expects the octave, note (letter), sharp, and length to be in memory.

	push	eax
	push	ebx
	push	edx
	push	di
	push	si
	pushf

	mov	Muted, 0
	mov	si, OFFSET Octave1
	mov	al, CurrentOctave
	dec	al
	and	ax, 00FFh
	mov	bx, 24
	mul	bx
	add	si, ax			; Now we are at the correct octave.

check_a:
	mov	al, CurrentNote
	cmp	al, "A"
	jnz	check_b
	cmp	KeySigAccidental, "#"
	jnz	check_ab
	cmp	KeySigNumber, 5
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_ab:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 3
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_b:
	mov	al, CurrentNote
	cmp	al, "B"
	jnz	check_c
	add	si, 4
	cmp	KeySigAccidental, "#"
	jnz	check_bb
	cmp	KeySigNumber, 7
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_bb:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 1
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_c:
	cmp	al, "C"
	jnz	check_d
	add	si, 6
	cmp	KeySigAccidental, "#"
	jnz	check_cb
	cmp	KeySigNumber, 2
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_cb:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 6
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_d:
	cmp	al, "D"
	jnz	check_e
	add	si, 10
	cmp	KeySigAccidental, "#"
	jnz	check_db
	cmp	KeySigNumber, 4
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_db:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 4
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_e:
	cmp	al, "E"
	jnz	check_f
	add	si, 14
	cmp	KeySigAccidental, "#"
	jnz	check_eb
	cmp	KeySigNumber, 6
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_eb:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 2
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_f:
	cmp	al, "F"
	jnz	check_g
	add	si, 16
	cmp	KeySigAccidental, "#"
	jnz	check_fb
	cmp	KeySigNumber, 1
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_fb:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 7
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_g:
	cmp	al, "G"
	jnz	check_rest
	add	si, 20
	cmp	KeySigAccidental, "#"
	jnz	check_gb
	cmp	KeySigNumber, 3
	jl	check_sharp
	add	si, 2
	jmp	check_sharp
check_gb:
	cmp	KeySigAccidental, "b"
	jnz	check_sharp
	cmp	KeySigNumber, 5
	jl	check_sharp
	sub	si, 2
	jmp	check_sharp
check_rest:
	cmp	al, "R"
	jnz	note_error
	mov	Muted, 1

check_sharp:
	cmp	CurrentAccidental, "#"
	jnz	check_flat
	add	si, 2

check_flat:
	cmp	CurrentAccidental, "b"
	jnz 	check_length
	sub	si, 2

check_length:
	push	si				; Store the count location
	cmp	CurrentLength, "T"
	jnz	check_sixteenth
	mov	di, OFFSET WaitInterval
	mov	si, OFFSET ThirtysecondNoteLength
	mov	eax, [si]
	mov	[di], eax	
	jmp	play
check_sixteenth:
	cmp	CurrentLength, "S"
	jnz	check_eighth
	mov	di, OFFSET WaitInterval
	mov	si, OFFSET SixteenthNoteLength
	mov	eax, [si]
	mov	[di], eax
	jmp	play
check_eighth:
	cmp	CurrentLength, "E"
	jnz	check_quarter
	mov	di, OFFSET WaitInterval
	mov	si, OFFSET EighthNoteLength
	mov	eax, [si]
	mov	[di], eax
	jmp	play
check_quarter:
	cmp	CurrentLength, "Q"
	jnz	check_half
	mov	di, OFFSET WaitInterval
	mov	si, OFFSET QuarterNoteLength
	mov	eax, [si]
	mov	[di], eax
	jmp	play
check_half:
	cmp	CurrentLength, "H"
	jnz	check_whole
	mov	di, OFFSET WaitInterval
	mov	si, OFFSET HalfNoteLength
	mov	eax, [si]
	mov	[di], eax
	jmp	play
check_whole:
	cmp	CurrentLength, "W"
	jnz	length_error
	mov	di, OFFSET WaitInterval
	mov	si, OFFSET WholeNoteLength
	mov	eax, [si]
	mov	[di], eax

play:
	pop	si				; Restore the count location
	mov	dx, [si]			; Load the note
	call	SpeakerOn
	call	PlayCount
	call	Delay
	call	SpeakerOff
	call	DrawNextLine

done:
	pop	si
	pop	di
	pop	edx
	pop	ebx
	pop	eax
	popf

	ret

note_error:
	mov	dx, OFFSET NoteErrorMsg
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS

length_error:
	mov	dx, OFFSET LengthErrorMsg
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
PlayNote ENDP

; -------------------------
;|		           |
;|	Process Line	   |
;|			   |
; -------------------------

CopyBuffer PROC
; Copies the buffer from si to di for cx bytes
	push	ax
	push	cx
	push	si
	push	di
	pushf

	jmp	cond

top:
	mov	al, [si]
	mov	[di], al
	inc	di
	inc	si
	dec	cx

cond:
	cmp	cx, 0
	ja	top

done:
	popf
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
CopyBuffer ENDP

.data
FormatErrorMsg BYTE "Incorrect format! Terminating.", 0
OctaveErrorMsg BYTE "Unacceptable octave! Terminating.", 0
.code
ProcessLine PROC
; Expects the next line of the file to be in the CurrentLine buffer.
; Example format: 	"C	4	W"
; Plays that note.

	push	ax
	push	si
	pushf

	mov	si, OFFSET CurrentLine		; Load the address

get_note:
	mov	al, [si]
	mov	CurrentNote, al			; Load the current note.
	inc	si
get_accidental:
	mov	al, [si]
	cmp	al, "	"
	jnz	check_sharp
	mov	CurrentAccidental, "N"
	jmp	get_octave
check_sharp:
	cmp	al, "#"
	jnz	check_flat
	mov	CurrentAccidental, "#"
	inc	si
	jmp	get_octave
check_flat:
	cmp	al, "b"
	jnz	format_error
	mov	CurrentAccidental, "b"
	inc	si

get_octave:
	inc	si
	mov	al, [si]
	cmp	al, "8"
	ja	octave_error
	sub	al, "0"
	mov	CurrentOctave, al
	inc	si

get_length:
	inc	si
	mov	al, [si]
	mov	CurrentLength, al

done:
	popf
	pop	si
	pop	ax
	ret

format_error:
	mov	dx, OFFSET FormatErrorMsg
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
octave_error:
	mov	dx, OFFSET OctaveErrorMsg
	call	WriteString
	mov	ax, DOS_EXIT
	int	DOS
ProcessLine ENDP

; -------------------------
;|		           |
;|	Play Song	   |
;|			   |
; -------------------------
PlaySong PROC
; Plays the song, ya!

	push	ax
	push	bx
	push	cx
	push	dx
	pushf


	call	GetCmdTail
	call	CleanUpFileName
	call	OpenFile

	call	GetVideoMode
	push	ax
	mov	al, 13h
	call	SetVideoMode

	mov	al, 0
	mov	ah, 0
	mov	cx, 3500h
	call	SetPalleteColor

	mov	al, 1
	mov	ah, 0FFh
	mov	cx, 00000h
	call	SetPalleteColor

	mov	CurrentPixelOffset, OFFSET Pixels


	mov	BPM, 0
get_bpm:
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, OFFSET TrashBuffer
	int	DOS

	mov	al, 0Dh
	cmp	TrashBuffer, al
	jz	get_to_time
	mov	ax, BPM			; Multiply BPM by 10
	mov	bx, 10
	mul	bx
	mov	BPM, ax
	mov	al, TrashBuffer
	and	ax, 00FFh
	sub	ax, "0"
	add	BPM, ax			; Add the next number
	jmp	get_bpm

get_to_time:
	mov	di, OFFSET TrashBuffer	; Get to the next line
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, di
	int	DOS

get_time:
	mov	di, OFFSET TrashBuffer
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, di			; Read in numerator
	int	DOS

	mov	al, [di]		; Place in memory
	sub	al, "0"
	mov	di, OFFSET TimeSignature
	mov	[di], al

	mov	di, OFFSET TrashBuffer	; Skip /
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, di
	int	DOS

	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, di			; Read in denominator
	int	DOS

	mov	al, [di]		; Place in memory
	sub	al, "0"
	mov	di, OFFSET TimeSignature
	mov	[di + 1], al

get_to_key:
	mov	di, OFFSET TrashBuffer	; Get to the next line
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 2
	mov	dx, di
	int	DOS

get_key:
	mov	ax, READF			; Read accidental
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, OFFSET KeySigAccidental
	int	DOS

	mov	ax, READF			; Read note
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, OFFSET KeySigNote
	int	DOS

	mov	ax, READF			; Read note pt. 2
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, OFFSET KeySigNote + 1
	int	DOS

	cmp	KeySigNote + 1, 0Dh
	jnz	skip_two_to_setup
	mov	KeySigNote + 1, 0
	jz	skip_one_to_setup

skip_two_to_setup:
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, OFFSET TrashBuffer
	int	DOS

skip_one_to_setup:
	mov	ax, READF
	mov	bx, FileHandle
	mov	cx, 1
	mov	dx, OFFSET TrashBuffer
	int	DOS
setup:
	mov	dx, BPM
	call	StoreBeatInfo
	call	SetNoteLengths
	call	SetKeyNumber
play_notes:
	call	ReadNextLine
cond:
	cmp	CurrentLine + 1, "!"
	jz	done
	call	ProcessLine
	call	PlayNote
	jmp	play_notes

done:
	call	CloseFile
	pop	ax
	call	SetVideoMode	
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PlaySong ENDP

; -------------------------
;|		           |
;|     Read Character	   |
;|			   |
; -------------------------

ReadCharacter Proc
	Push	ax
	Pushf

	mov	ah, READ_CHAR
	int	DOS

	popf
	pop	ax
	ret
ReadCharacter ENDP

; ---------------------------------------------------------------------------
; /////////////////////////// Graphics //////////////////////////////////////
; ---------------------------------------------------------------------------

; -------------------------
;|		           |
;|    Get Video Mode	   |
;|			   |
; -------------------------
;; Returns:
;; 	AL - Video Mode
;; 	AH - Number of character columns
;; 	BH - Active Page

GetVideoMode PROC
	push	cx
	push	ax

	mov	ah, 0fh
	int	BIOS
	mov	cl, al

	pop	ax
	mov	al, cl
	pop	cx
	Ret	
GetVideoMode Endp

; -------------------------
;|		           |
;|     Set Video Mode	   |
;|			   |
; -------------------------
;; Al - Video mode

SetVideoMode PROC
	push	ax

	mov	ah, 00
	int	BIOS

	pop	ax
	ret
SetVideoMode ENDP

;; BH - Page number
;; CX - X
;; DX - Y
;;
;; Returns:
;;
;; AL - Color

; -------------------------
;|		           |
;|       ReadPixel	   |
;|			   |
; -------------------------
ReadPixel PROC
	push	ax

	mov	ah, 0dh
	int	BIOS

	pop	ax
	ret
ReadPixel ENDP

; -------------------------
;|		           |
;|     Write Pixel	   |
;|			   |
; -------------------------
;; AL - Color
;; BH - Page
;; CX - X
;; DX - Y
WritePixel PROC
	push	ax

	mov	ah, 0fch
	int	BIOS
	
	pop	ax
	ret
WritePixel ENDP

; -------------------------
;|		           |
;|        SetPalette	   |
;|			   |
; -------------------------
;; BL - Palette id

SetPalette PROC
	push	ax
	push	bx

	mov	ah, 0bh
	mov	bh, 01h
	int	BIOS

	pop	bx
	pop	ax
	ret
SetPalette ENDP

; -------------------------
;|		           |
;|     Set Palette Color   |
;|			   |
; -------------------------
;; AL - Pallete Index
;; AH - Red
;; CX - Blue:Green

SetPalleteColor PROC
	push	ax
	push	dx

	mov	dx, 3c8h	; Video pallete port
	out	dx, al		; Write the color out

	mov	dx, 3c9h	; Color selection port

	mov	al, ah		; Red
	out	dx, al
	mov	al, cl		; Green
	out	dx, al
	mov	al, ch		; Blue
	out	dx, al

	pop	dx
	pop	ax
	ret
SetPalleteColor ENDP

; -------------------------
;|		           |
;|      Draw Pixel	   |
;|			   |
; -------------------------
;; BX - Color Index
;; CX - X
;; DX - Y
DrawPixel PROC
;; Screen resolution is 320x200

	push	ax
	push	dx
	push	di
	push	es

	mov	ax, 320
	mul	dx		; AX = 320 * Y
	add	ax, cx		; AX = 320 * Y + X

	mov	di, ax		; Set di to the offset

	push	0A000h		; Set ES to the video segment
	pop	es

	mov	BYTE PTR es:[di], bl ; Set the pixel to the given color

	pop	es
	pop	di
	pop	dx
	pop	ax
	ret
DrawPixel ENDP

DrawQuad PROC
	push	bx
	push	cx
	push	dx

	mov	bx, 1
	call	DrawPixel
	inc	cx
	call	DrawPixel
	inc	dx	
	call	DrawPixel
	dec	cx
	call	DrawPixel
	
	pop	dx
	pop	cx
	pop	bx
	ret
DrawQuad ENDP

DrawLine PROC
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	jmp	cond
top:
	mov	bx, 1
	call	DrawQuad
	add	cx, 2
	dec	ax
cond:
	cmp	ax, 0
	ja	top

	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
DrawLine ENDP

DrawNextLine PROC
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	cmp	CurrentPixelOffset, OFFSET EndPixels
	jz	done
	mov	si, CurrentPixelOffset
	mov	bx, 1
	mov	ax, [si]
	mov	cx, [si + 2]
	mov	dx, [si + 4]
	call	DrawLine
	add	CurrentPixelOffset, 6

done:
	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
DrawNextLine ENDP
;-----------------------------------------------------
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-----------------------------------------------------

main PROC
	mov	ax, @data
	mov	ds, ax

	call	ReadCharacter
	call	PlaySong

	mov	ax, DOS_EXIT
	int	DOS
	ret
main ENDP
END main
