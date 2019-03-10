; Name: Jack Scacco
; Date: 9/7/18
; Assignment: Project 2
; File: funcs.asm

TITLE let's get funcy
INCLUDE cs240.inc
.8086

DOSEXIT = 4C00h
DOS = 21h

.data

.code
Polynomial PROC
	push	bx	; Store all register values that aren't ax.
	push	cx
	push	dx
	pushf

getBX:
	push	ax	; Store the ax register (contains the A value).
	push	dx	; Store the dx register for multiplication.
	mov	ax, bx	; Move the B value to ax for multiplication.
	imul	dx	; Multiply B by X to get BX.
	pop	dx	; Restore the dx register.
	mov	bx, ax	; Move the value BX to bx (fitting, isn't it?).
	pop	ax	; Restore the ax register (now the A value is back).

getAX2:
	push	cx	; Store cx register (contains the C value).
	mov	cx, dx	; Move X value to cx so we can use it in imul.
	push	dx	; Store dx register before multiplication.
	imul	cx	; Multiply A value by X value.
	imul	cx	; Multiply AX value by X to get AX^2.	
	pop	dx	; Restore dx register value.
	pop	cx	; Restore cx register value (now C value is back).
			; We don't need to move AX^2 anywhere.
addEmUp:
	add	ax, bx	; Now we have AX^2 + BX in the ax register.
	add	ax, cx	; Now we have AX^2 + BX + C in the ax register!

cleanUp:	
	popf
	pop	dx	; Restore every register but ax.
	pop	cx
	pop	bx
	ret
Polynomial ENDP

OverFlower PROC
; Set the overflow flag to the value in bx
	push 	ax	; Store the ax value.
	push	cx	; Store the cx value.
	pushf		; Push flags onto stack.
	; CITE: Nathaniel Adair
	; DESC: Figuring out how to get stacks to registers. (smart dude)
	pop	ax 	; Get flags into ax.
	mov	cx, 15 	; Set a counter to keep track of digits.

top:
	shl	ax, 1	; Shift the ax digits left once. CF holds the digit.
	adc	ax, 0 	; Set the last digit to whatever the first was.
	dec	cx	; Update counter.
	cmp	cx, 11	; See if we are at the 5th digit yet (it will be 1).
	je	special	; If we are, go to the special case.
	cmp	cx, 0 	; See if we are done yet.
	jg	top	; If we aren't done, recur.
	jmp	bottom	; Skip the special case.

special:
	shl	ax, 1	; This is the same step we are taking, except...
	add	ax, bx	; Move the value in bx to ax (set the OF flag)
	jmp	top

bottom:
	push	ax	; Push new flags back onto stack.
	popf		; Get new flags into their actual places.
	pop	cx
	pop	ax
	ret
OverFlower ENDP

Factorial PROC
	push	bx
	push	dx
	push	ax	; This is a weird order b/c sometimes we overwrite.
	pushf
	mov	bx, ax	; Copy the A value into bx to use as a counter.
	dec	bx	; Decrease by 1 since we have original in ax already.

compare:
	cmp	bx, 0
	jle	nooverf

top:
	mul	bx	; Multiply current total by the counter value.
	jo	overf	; If we've overflowed, we are done.
	dec	bx	; Decrement the counter value by 1.
	cmp	bx, 0	; Check to see if we are done.
	jg	top	; If we aren't, recur.
	jmp	nooverf	; If we are, go to the bottom.

overf:
	popf			; Reset the flags
	mov	bx, 1		; We want to set OF flag, so set bx to 1
	call	OverFlower	; Set the OF Flag
	pop	ax
	jmp	bottom
	
nooverf:
	popf
	mov	bx, 0	; We want to clear OF, so set bx to 0
	call	OverFlower
	pop	dx	; Clear the old ax value. (We will overwrite dx soon.)

bottom:
	pop	dx
	pop	bx
	ret
Factorial ENDP

Fibonacci PROC
	push	bx
	push	cx
	push	dx
	pushf
	mov	bx, 1	; Set up the counters we will be using.
	mov	cx, 1
	dec	ax	; Decrement this to fix the offset of already
	dec	ax	; having the first two numbers.

compare:
	cmp	ax , 0
	jle	bottom

top:
	add	bx, cx	; Get the sum of the two current numbers.
	mov	dx, bx	; Store the sum while we rearrange.
	mov	bx, cx	; Shift the higher number to the lower spot.
	mov	cx, dx	; Get the sum from storage and put in higher spot.
	dec	ax
	cmp	ax, 0	
	jg	top

bottom:
	mov	ax, cx	; NOTE: the algorithm already handles inputs <=2.
	popf
	pop	dx
	pop	cx
	pop	bx
	ret
Fibonacci ENDP

PrintString PROC
	push	ax
	push	bx
	push	dx
	push	si
	pushf
	mov	si, dx	; Get the offset into si
	mov	bx, 0; Create a counter that will modify our memory location.

top:
	mov	al, [si + bx]	; Move the next byte into dl.
	mov	dl, al
	cmp	dl, 00		; If the next byte is null, we are done!
	je	bottom
	mov	ah, 02h		; Write the character.
	int	21h
	inc	bx		; Increment the counter.
	jmp	top

bottom:	
	popf
	pop	si
	pop	dx
	pop	bx
	pop	ax
	ret
PrintString ENDP

PrintHexDigit PROC
.data
HexArray BYTE "0123456789ABCDEF", 0
.code
	push 	bx
	push	cx
	push 	dx
	push 	si
	pushf

	mov	bx, dx	
	mov	si, OFFSET HexArray 
	mov	cx, 12		; Set cx so we can shift left 11 times.
shltop:
	shl	bx, 1
	loop	shltop
	mov	cx, 12		; Do the same thing, but for shift right.
shrtop:
	shr	bx, 1
	loop	shrtop		; Now we have only the lowest bit in bx.

	mov	dl, [si + bx]	; Get the hex digit from HexArray.
	mov	ah, 02h		; Print the character.
	int	21h
	
	popf
	pop 	si
	pop	dx
	pop	cx
	pop	bx
	ret
PrintHexDigit ENDP
END

