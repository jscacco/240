

.

.


prog: start 400
begin:	ldb	10
		mul	20
		start 1200
		ldl	value
		ldx	value
.value:	byte	127
another:	+jeq	begin
value:	word	256
end