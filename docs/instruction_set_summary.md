# TT06-TYE-Tiny-CPU instruction set summary
This document describes instruction set of CPU that is embedded in the TT06-TYE-Tiny-CPU design.

## Memory Address Space
This CPU employs a Harvard architecture. So, it has an instruction bus and a data bus internally.
Both buses have 16-bit address space.

For the detailed memory map, please see [info.md](https://github.com/JA1TYE/tt06-TYE-tiny-cpu/blob/main/docs/info.md)

## Registers
This CPU has 8 general-purpose registers. These registers can be used as the destination/source register of Register-Register type instructions and Load Immediate instruction.

In addition, register 0 ("$0" in tt06-tmasm) has special function that the destination/source register of Load/Store instructions.

Other than the general-purpose registers, this CPU has 4-bit status register. Bit definition is below:

|Bit|Name|Description|Abbreviation|
|---|---|---|---|
|0|Zero Flag|Set if the result is zero|Z|
|1|Overflow Flag|Set if signed overflow is occured|V|
|2|Sign Flag|Equal to result[7]|S|
|3|Carry Flag|Set if carry is occured|C|

Status register is updated when R-Type instructions are executed.

Flags in status register cannot use as an operand of instruction.
SCF (Set Condition bit from Flag) instruction copies status of these flag to condition bit.
Please see description of SCF instruction for details.

## Instruction set
This CPU uses 16-bit fixed-length instruction format. Instructions can be classified to I,R,J,F types.

All instuction have a conditional execution feature. if the bit 13 in fetched instruction is set and the condition bit in CPU is also set, the instruction will be treated as NOP (In other words, the instruction will be skipped.) .

### I-Type Instructions
I-Type instruction format is below. I-Type instructions do not affect the flag register.

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:11]|bit[10:8]|bit[7:0]|Operation|
|---|---|---|---|---|---|---|---|
|Load|LD|3|CondEn|0|Ri|Imm|$0 <- Memory((Imm << 8) + Ri)|
|Store|ST|3|CondEn|1|Ri|Imm|Memory((Imm << 8) + Ri) <- $0|
|Load Immediate|LDI|3|CondEn|2|Rd|Imm|Rd <- Imm|
* Memory(addr):Content of data memory adderss addr
* Ri,Rd:3-bit register index
* Imm:8-bit immediate value
* CondEn 0:Unconditional, 1:Skip if condition bit is set

### R-Type Instructions
R-Type instructions are Register-Register operation. Its format is below:

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:11]|bit[10:8]|bit[7:5]|bit[4:0]|Operation|Affected Flags|
|---|---|---|---|---|---|---|---|---|---|
|Shift Logical Right|SLR|2|CondEn|0|Rs|Rd|0|{Rd,C} <- {1'b0,Rs}|Z, S, C|
|Shift Logical Left|SLL|2|CondEn|0|Rs|Rd|1|{C,Rd} <- {Rs,1'b0}|Z, S, C|
|Increment|INC|2|CondEn|0|Rs|Rd|4|Rd <- (Rs + 1)|Z, V, S, C|
|Decrement|DEC|2|CondEn|0|Rs|Rd|5|Rd <- (Rs - 1)|Z, V, S, C|
|Add|ADD|2|CondEn|0|Rs|Rd|6|Rd <- (Rs + Rd)|Z, V, S, C|
|Not|NOT|2|CondEn|0|Rs|Rd|8|Rd <- ~Rs|Z, S|
|And|AND|2|CondEn|0|Rs|Rd|9|Rd <- (Rs & Rd)|Z, S|
|Or|OR|2|CondEn|0|Rs|Rd|10|Rd <- (Rs \| Rd)|Z, S|
|Exclusive Or|XOR|2|CondEn|0|Rs|Rd|11|Rd <- (Rs ^ Rd)|Z, S|
|Move|MOV|2|CondEn|0|Rs|Rd|12|Rd <- Rs|Z, S|

### J-Type Instruction
J-Type instruction is GOTO instruction only.

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:11]|bit[10:8]|bit[7:5]|bit[4:0]|Operation|
|---|---|---|---|---|---|---|---|---|
|Branch|GOTO|1|CondEn|0|Rs|Rd|0|PC <- {(Rs << 8) + Rd}|

### F-Type Instruction
SCF and NOP are F-Type instruction. F-Type instruction format is below:

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:9]|bit[8]|bit[7:4]|bit[3]|bit[2]|bit[1]|bit[0]|Operation|
|---|---|---|---|---|---|---|---|---|---|---|---|
|Set Condition bit from Flag|SCF|0|CondEn|4|Inv|0|C|S|V|Z|Condition <- (Inv ^ (Status & bit[3:0]))|
|No Operation|NOP|0|CondEn|0|0|0|0|0|0|0|Do nothing|

SCF instruction copies flag bits to the condition bit based on bit mask in the instruction bit[3:0].
For example, if the instruciton bit[3:0] is 8 (4'b1000), Carry flag is copied to the condition bit.

You can make conditional branch instruction in combination with GOTO instruction and SCF instruction. For example, "Branch if carry" instruction can be achieved like below:
```C
//Set jump destination address (0xff00) to $6 and $7
LDI $6,0xff
LDI $7,0x00
//Do an operation that may set the carry flag
ADD $0,$2
//Set Condition bit from Flag, Condition <- not(Carry)
SCF C,Inv
//GOTO instruction with conditional execution enable
GOTO $6,$7,Cond
```
