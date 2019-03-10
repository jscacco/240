
                                        hello
.
  .

        start   200
        j       @meme,x
        byte    cHello
        byte    x56
num:    word    2
        word    5
        word    10
        word    9
        word    16777215
        byte    255
        base  2
        resb    20
arr:    resw    2
forx:   resw    1
new:    ldx     #1,x
loop:   lda     num,x
        sta     arr,x
        tix     #10
        jlt     loop,x
        clear   a
        compr   a, x
        shiftr  a, 16
        svc     15
        add     h
        end     $
        end     $
