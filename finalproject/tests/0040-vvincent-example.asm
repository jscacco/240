copy:	start	0
first:	stl		retadr
		ldb		#length
		base	length
cloop:	+jsub	rdrec
		lda		length
		comp	#0
		jeq		endfil
		+jsub	wrrec
		j       cloop
endfil:	lda		eof
		sta 	buffer
		lda		#3
		sta 	length
		+jsub	wrrec
		j 		@retadr
eof:	byte	c'eof'
retadr:	resw	1
length:	resw	1
buffer:	resb	4096

rdrec:	clear	x
		clear	a
		clear	s
		+ldt	#4096
rloop:	td		input
		jeq		rloop
		rd 		input
		compr	a, s
		jeq		exit
		stch	buffer, x
		tixr	t
		jlt		rloop
exit:	stx		length
		rsub
input:	byte	x'f1'

wrrec:	clear	x
		ldt		length
wloop:	td		output
		jeq		wloop
		