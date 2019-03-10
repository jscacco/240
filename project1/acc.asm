; Name: Jack Scacco
; Date: 9-2-18
; Assignment: Project 1
; File: acc.asm

TITLE sqrt

INCLUDE cs240.inc
.8086

DOSEXIT = 4C00h
DOS = 21h

.data
prompt	BYTE	"Please enter a number to be square-rooted: ", 0

.code
sqrt PROC
.data
	lower 	WORD	0	; Create two counters to keep track of
	upper	WORD	1	; where we are.
.code
	push	ax		; Push register values onto
	push	bx		; the stack so we can restore them later.

begin:
	cmp	upper, 256	; If we reach 256, then that's the answer.
	je	go_256
	mov	ax, upper	; Move the upper bound to ax for comparison.
	push	dx		; Store dx so it's not lost in multiplication.
	mul	ax		; Square the upper bound.
	pop	dx		; Restore dx.
	cmp	dx, ax		; Compare the upper square to the input.
	jna	choose_bound	; If the input is lte to the square,
				; end recursion.
recur:
	inc	lower		; Increment both counters by 1.
	inc	upper
	jmp	begin		; Recur.

choose_bound:
	mov	ax, upper	; Move the upper counter to ax for squaring.
	push	dx		; Store the dx value.
	mul	ax		; Square the upper counter.
	pop	dx		; Restore the dx value.
	cmp	ax, dx		; Check for equality.
	je	go_upper	; Save some time if they are equal.
	mov	bx, ax		; Move the upper counter's square to bx.
	mov	ax, lower	; Move the lower counter to ax for squaring.
	push	dx		; Store dx.
	mul	ax		; Square the lower counter.
	pop	dx		; Restore dx.
	cmp	ax, dx		; Check for equality.
	je	go_lower	; Save some time if they are equal.
	neg	ax		; Negate the lower square.
	add	ax, dx		; Now we have (input - lower^2)
	neg	bx		; Do the same for the upper square.
	add	bx, dx
	add	ax, bx		; Now we have the sum of the differences.
	cmp	ax, 0		; Compare the sum to 0.
	jle	go_lower	; If it's <0, the lower bound was closer.

go_upper:
	mov 	dx, upper
	jmp	finished

go_lower:
	mov	dx, lower
	jmp	finished

go_256:
	mov	dx, 256

finished:
	pop	bx
	pop	ax
	ret
sqrt ENDP

main PROC
	mov	ax, @data
	mov	ds, ax

	mov	dx, OFFSET prompt	; Prompt the user
	call	WriteString
	call	ReadInt			; Read the input
	call	sqrt
	call	WriteInt		; Write the result
		
	mov 	ax, DOSEXIT
	int	21h
main ENDP
END main
