copy:   start   1000                    copy file from input to output
first:  stl     retadr                  save return address
cloop:  jsub    rdrec                   read input record
        lda     length                  test for eof (length = 0)
        comp    zero
        jeq     endfil                  exit if eof found
        jsub    wrrec                   write output record
        j       cloop                   loop
endfil: lda     eof                     insert end of file marker
        sta     buffer
        lda     three                   set length = 3
        sta     length
        jsub    wrrec                   write eof
        ldl     retadr                  get return address
        rsub                            return to caller
eof:    byte    c'EOF'
three:  word    3
zero:   word    0
retadr: resw    1
length: resw    1                       length of record
buffer: resb    4096                    4096-byte buffer area
.
.       subroutine to read record into buffer
.
rdrec:  ldx     zero                    clear loop counter
        lda     zero                    clear a to zero
rloop:  td      input                   test input device
        jeq     rloop                   loop until ready
        rd      input                   read character into register a
        comp    zero                    test for end of record (X'00')
        jeq     exit                    exit loop if eor
        stch    buffer,x                store character in buffer
        tix     maxlen                  loop unless max length
        jlt     rloop                     has been reached
exit:   stx     length                  save record length
        rsub                            return to caller
input:  byte    x'f1'                   code for input device
maxlen: word    4096
.
.       subroutine to write record from buffer
.
wrrec:  ldx     zero                    clear loop counter
wloop:  td      output                  test output device
        jeq     wloop                   loop until ready
        ldch    buffer, x               get character from buffer
        wd      output                  write character
        tix     length                  loop until all characters
        jlt     wloop                     have been written
        rsub                            return to caller
output: byte    x'05'                   code for output device
        end     first
