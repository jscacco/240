	.this is a comment

	start	1000
first:	lda	#10
second:	lda	#11
	BASE	2500
	byte	x'F1BB34'
	word	123
	byte	4
third:	lda	first
dat:	byte	c'H'
fourth:	lda	dat
	TIO
	SIO
	end
