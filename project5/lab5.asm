; Name: Jack Scacco
; Date: 10-7-18
; Assignment: Project5
; File: lab5.asm

TITLE lab5

INCLUDE cs240.inc
.8086

DOSEXIT = 4C00h
DOS = 21h
PRINTCHR = 06h
READCHR = 07h
GETTIME = 2Ch

.code

PrintChar PROC
; Prints the ASCII character in the lower half of the value in ax
	push	ax
	push	dx

	mov	dx, ax
	mov	ah, PRINTCHR
	int 	DOS
	
	pop	dx
	pop	ax
	ret
PrintChar ENDP

SafeRead PROC
	offst = 6 
	sze = 4
	push	bp
	mov	bp, sp

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	pushf

	mov	di, [bp + offst]
	mov	cx, [bp + sze]		; Store max length in cx
	dec	cx			; We need to save one spot for 00h
	mov	bx, 0			; Store current length in bx
	
top:
	mov	ah, READCHR		; Read a char, put it in al
	int	DOS
	cmp	al, 0Dh			; Check for enter (end)
	je	done
	cmp	al, 03h			; Check for ^C (terminate)
	je	errormsg
	cmp	al, 08h			; Check for backspace 
	je	backspc
	cmp	al, 20h			; Otherwise, only take printable chrs
	jl	top
	cmp	al, 7Eh	
	jg	top

normal:
	cmp	bx, cx			; Do nothing if we are at buffer max.
	jae	top
	mov	[di], al
	call	PrintChar
	inc	di
	inc	bx
	jmp	top	

backspc:
	cmp	bx, 0		; If we have nothing, no-op
	jbe	top
	call	PrintChar	; Print the backspace
	mov	al, " "
	call	PrintChar	; Print and actual space
	mov	al, 08h
	call	PrintChar	; Move the cursor back by printing backspace
	mov	al, 0		; Clear the current buffer index
	mov	[di], al	
	dec	di		; Move back once in the buffer
	dec	bx
	jmp	top
	
errormsg:
.data
ctrlcmsg BYTE "Uh oh! Program manually terminated.", 0
.code	
	call	NewLine
	mov	dx, OFFSET ctrlcmsg
	call	WriteString
done:
	popf	
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret
SafeRead ENDP

; -------------------------------------------------------------------------- ;
.code

FetchTime PROC
; Retrieves the system time and places it in cx + dx

	push	ax
	mov	ah, GETTIME
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
	cmp	si, 9
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
END 
