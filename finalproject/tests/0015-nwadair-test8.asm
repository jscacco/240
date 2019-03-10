copy:	start	1000
first:	stl	retadr
cloop:	jsub	rdrec
	lda	length
	comp	zero
	jeq	endfil
	jsub	wrrec
	j	cloop
endfil:	lda	eof
	sta	buffer
	lda	three
	sta	length
	jsub	wrrec
	ldl	retadr
	rsub
eof:	byte	c'EOF'
three:	word	3
zero:	word	0
retadr:	resw	1
length:	resw	1
buffer:	resb	4096

.	subroutine to read record into buffer

rdrec:	ldx	zero
	lda	zero
rloop:	td	input
	jeq	rloop
	rd	input
	comp	zero
	jeq	exit
	stch	buffer,X
	tix	maxlen
	jlt	rloop
exit:	stx	length
	rsub
input:	byte	x'f1'
maxlen:	word	4096

.	subroutine to write record from buffer

wrrec:	ldx	zero
wloop:	td	output
	jeq	wloop
	ldch	buffer, X
	wd	output
	tix	length
	jlt	wloop
	rsub
output:	byte	x'05'
	end
