//Instruction set test
VAR GPIO_DIR 0xf000
VAR GPIO_OUT 0xf001
VAR MEM_REGION 0x0001
INIT_GPIO:
    LDI $1,0xff
    LDI $2,0x0
    ST  $1,GPIO_DIR
    ST  $2,GPIO_OUT
SLR_TEST:
    LDI $1,0x01
    LDI $2,0x00
SLR_TEST2:
    SLR $1,$2
    ST  $2,GPIO_OUT
SLL_TEST:
    LDI $1,0x01
    LDI $2,0x00
SLL_TEST2:
    SLL $1,$2
    ST  $2,GPIO_OUT
INC_TEST:
    LDI $1,0x01
    LDI $2,0x00
INC_TEST2:
    INC $1,$2
    ST  $2,GPIO_OUT
DEC_TEST:
    LDI $1,0x01
    LDI $2,0x00
DEC_TEST2:
    DEC $1,$2
    ST  $2,GPIO_OUT
ADD_TEST:
    LDI $1,0x01
    LDI $2,0x00
ADD_TEST2:
    ADD $1,$2
    ADD $1,$2
    ST  $2,GPIO_OUT
NOT_TEST:
    LDI $1,0x01
    LDI $2,0x00
NOT_TEST2:
    NOT $1,$2
    ST  $2,GPIO_OUT
AND_TEST:
    LDI $1,0xaa
    LDI $2,0xa5
AND_TEST2:
    AND $1,$2
    ST  $2,GPIO_OUT
OR_TEST:
    LDI $1,0xaa
    LDI $2,0xa5
OR_TEST2:
    OR  $1,$2
    ST  $2,GPIO_OUT
XOR_TEST:
    LDI $1,0xaa
    LDI $2,0xa5
XOR_TEST2:
    XOR $1,$2
    ST  $2,GPIO_OUT
MOV_TEST:
    LDI $1,0xaa
    LDI $2,0xa5
MOV_TEST2:
    MOV $1,$2
    ST  $2,GPIO_OUT
GOTO_TEST:
    LDI $1,0x00
    GOTO GOTO_END
    LDI $1,0xff
GOTO_END:
    ST  $1,GPIO_OUT
GPIO_LOAD_TEST:
    LDI $1,0x01
GPIO_LOAD_TEST2:
    LD  $1,GPIO_OUT.hi
    NOT $0,$0
    ST  $0,GPIO_OUT
MEM_STORE_TEST:
    ST $0,MEM_REGION
    LDI $0,0x00
    LD $0,MEM_REGION
    ST $0,GPIO_OUT
//Test for flag registers
CLEAR_ALL_FLAGS:
    LDI $0,0x00
    INC $0,$0
    ST  $0,GPIO_OUT
SLR_FLAG_TEST:
    //Flag not changed
    LDI $1,0x02
    SLR $1,$1
    ST  $1,GPIO_OUT
    //Z,C flags set
    SLR $1,$1
    ST  $1,GPIO_OUT
SLL_FLAG_TEST:
    //S flag is set
    LDI $1,0x40
    SLL $1,$1
    ST  $1,GPIO_OUT
    //Z,C flags set
    SLL $1,$1
    ST  $1,GPIO_OUT
INC_FLAG_TEST:
    //Z,C flag is set
    LDI $1,0xff
    INC $1,$1
    ST  $1,GPIO_OUT
    //S,V flag is set
    LDI $1,0x7f
    INC $1,$1
    ST  $1,GPIO_OUT
    //S flag is set
    LDI $1,0xfe
    INC $1,$1
    ST  $1,GPIO_OUT
NOT_FLAG_TEST:
    //S flag is set
    LDI $1,0x00
    NOT $1,$1
    ST  $1,GPIO_OUT
    //Z flag is set
    NOT $1,$1
    ST  $1,GPIO_OUT
    NOT $1,$1
    ST  $1,GPIO_OUT
END_LOOP:
    GOTO END_LOOP