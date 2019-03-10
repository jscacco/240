; Name: Jack Scacco
; Date: 9-16-18
; Assignment: Project 3
; File: procs.asm

TITLE proc-tically perfect

INCLUDE cs240.inc
.8086


.code

ArraySum PROC
.data
	len	WORD 0
.code	
	push	bx
	push	cx
	push	dx
	pushf
	mov	ax, 0		; Prepare our output register.
	mov	dh, 0		; Clear dh

top:
	cmp	dl, 1		; It's annoying to have this in loop, but
	jg	words		; it saves code down the line.

bytes:	
	push 	cx		; Add the byte value to ax with magic.
	mov	ch, 0
	mov	cl, [bx]
	cmp	cx, 128		; Check if we need to take two's complement.
	jl	bpositive
	not	cl		; Take two's complement
	inc	cl
	neg	cx		; Actually make it negative
bpositive:
	add	ax, cx
	pop	cx
	jmp	rest

words:
	push	cx
	mov	cx, [bx]
	cmp	cx, 32768	; Check if it's negative.
	jl	wpositive
	not	cx		; Take two's complement.
	inc	cx
	neg	cx
wpositive:
	add	ax, cx		; Add the value in the current location.
	pop	cx
	
rest:
	add	bx, dx		; Update our data segment pointer.
	inc	len
	cmp	len, cx
	jl	top

bottom:
	popf
	pop	dx
	pop	cx
	pop	bx
	ret
ArraySum ENDP

FactHelper PROC
	cmp	ax, 2
	jl	bottom

	push	ax
	dec	ax
	call	FactHelper
	pop	ax

	push	ax		; These lines essentially do cx = cx*ax
	push	bx
	mov	bx, ax
	mov	ax, cx
	mul	bx
	jo 	overflow
	mov	cx, ax
	pop	bx
	pop	ax
	ret

overflow:
	pop	bx
	pop	ax
	mov	cx, -1	; Place -1 here so we can overflow in wrapper.
	ret

bottom:
	mov	cx, 1
	ret
FactHelper ENDP

Fact PROC
	push	bx
	push	cx
	push	dx
	push	ax
	pushf

	call	FactHelper
	cmp	cx, -1
	je	overflow

nooverflow:
	popf
	pushf
	pop	ax
	and	ax, 0F7FFh
	push	ax
	popf

	mov	ax, cx
	pop	dx	; Overwrite the old ax
	jmp	bottom

overflow:
	popf
	pushf
	pop	ax
	or	ax, 0800h
	push	ax
	popf

	pop	ax

bottom:
	pop	dx
	pop	cx
	pop	bx
	ret
Fact ENDP

PrintHexDigit PROC
	; This is the function I wrote last project
.data
HexArray BYTE "0123456789ABCDEF", 0
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
	mov	ah, 02h
	int	21h

	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PrintHexDigit ENDP

HexOut PROC
; Expects the address in bx and the length in cx.
.data
hlen WORD 0
.code
	push	ax
	push	bx
	push	cx
	push	dx
	pushf

	mov	ax, cx		; Store the length in ax

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

	push	ax		; Print out a space
	mov	dl, 32
	mov	ah, 02h
	int	21h
	pop	ax

	inc	bx
	inc	hlen
	cmp	hlen, ax
	jl	top
	
bottom:
	popf
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
HexOut ENDP

PrintIntHelper PROC
; Takes a value in ax
	cmp	ax, 0
	je	bottom

	mov	dx, 0		; Clear dx for division
	mov	cx, 10		; Load the divisor
	div 	cx		; ax/10, remainder in dx
	push	dx
	call	PrintIntHelper
	pop	dx
	mov	bx, dx		; Now we have num % 10 in bx
	mov	dl, [si + bx]	; Print out the digit
	mov	ah, 02h
	int	21h
	ret

bottom:
	ret
PrintIntHelper ENDP

PrintInt PROC
.data
decDigits BYTE "0123456789", 0
.code
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	pushf

	cmp	ax, 0
	je	zero
	push	ax	; Print out a "-" if we need to
	and	ax, 8000h
	cmp	ax, 8000h
	jne	positive
	mov	dl, 45
	mov	ah, 02h
	int 	21h
	pop	ax
	not	ax	; Take two's complement
	inc	ax	
	jmp	operate

positive:
	pop	ax

operate:
	mov	si, OFFSET decDigits	
	call	PrintIntHelper
	jmp	done

zero:
	mov	dl, 48	
	mov	ah, 02h
	int	21h

done:
	popf
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
PrintInt ENDP
END
