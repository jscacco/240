        +J	BEGIN
ARY:	RESB	4096 

VALUE:	RESW	1    

BEGIN:	LDS	VALUE   
	    LDT	#8     
	    SHIFTL  A,1    
	    DIVR	T,S    
	    +LDB	#ARY   
        BASE	ARY    
        HIO          
        RMO	S,A      
        +RSUB           
        LDX	#7          
        STCH	ARY,X   
