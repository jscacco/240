all:		start	1000
zero:	word	1
one:		word	1
two:		word	2

	byte c'hello'
	byte x'5'
	resw 1234
	resb 1234
	
	add one
	addf	one
	addr A, B
	and zero
	clear L
	comp A
	compf A
	compr A, B
	div one
	divf one
	divr A, B
	fix
	float
	hio
	j zero
	jeq zero
	jgt zero
	jlt zero
	jsub zero
	lda one
	ldb one
	ldch one
	ldf two
	ldl one
	lds one
	ldt one
	ldx two
	lps zero
	mul zero
	mulf one
	mulr A, B
	norm
	or zero
	rd one
	rmo a, b
	rsub
	. shiftl
	. shiftr
	sio
	ssk one
	sta zero
	stb one
	stch two
	stf one
	sti zero
	stl one
	sts one
	stsw two
	stt one
	stx zero
	sub one
	subf zero
	subr a, b
	. svc a
	td one
	tio
	tix one
	tixr a
	wd one
END:	end
	
