<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
This is 8-bit CPU that has a simple instruction set.

This design also has these function blocks:
- Memory controller for SPI Flash (for instruction memory) / PSRAM (for data memory)
- SPI Tx (mode 0 only)
- GPIO (Output only x4, In/Out x4)

Dedicated macro assembler is also available at [tt06-tmasm](https://github.com/JA1TYE/tt06-tmasm).

### Memory Address Space
This CPU employs a Harvard architecture. So, it has an instruction bus and a data bus internally.
Both buses have 16-bit address space.

External SPI Flash is mapped to 0x0000-0xFFFF on the instruction memory space.
CPU will read an instruction from 0x0000 after reset.

PSRAM and some peripherals are mapped to the data memory space.
Address map is below:

|Address|Description|
|---|---|
|0x0000-0xEFFF|Mapped to SPI PSRAM|
|0xF000|GPIO Direction Set Register|
|0xF001|GPIO Output Data Register|
|0xF002|GPIO Input Data Register|
|0xF003|Reserved|
|0xF004|SPI Divider Value Register|
|0xF005|SPI CS Control Register|
|0xF006|SPI Status Register|
|0xF007|SPI Data Register|
|0xF008-0xFFFF|0xF000-0xF007 are mirrored in every 8 bytes|

### Registers
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
SCF (Set Condition Flag) instruction copies status of these flag to condition bit.
Please see description of SCF instruction for details.

### Instruction set
This CPU uses 16-bit fixed-length instruction format. Instructions can be classified to I,R,J,F types.

All instuction have a conditional execution feature. if the bit 13 in fetched instruction is set and the condition bit in CPU is also set, the instruction will be treated as NOP (In other words, the instruction will be skipped.) .

#### I-Type Instructions
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

#### R-Type Instructions
R-Type instructions are Register-Register operation. Its format is below:

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:11]|bit[10:8]|bit[7:5]|bit[4:0]|Operation|Affected Flags|
|---|---|---|---|---|---|---|---|---|---|
|Shift Logical Right|SLR|2|CondEn|0|Rs|Rd|0|{Rd,C} <- {1'b0,Rs}|Z,S,C|
|Shift Logical Left|SLL|2|CondEn|0|Rs|Rd|1|{C,Rd} <- {Rs,1'b0}|Z,S,C|
|Increment|INC|2|CondEn|0|Rs|Rd|4|Rd <- (Rs + 1)|Z,V,S,C|
|Decrement|DEC|2|CondEn|0|Rs|Rd|5|Rd <- (Rs - 1)|Z,V,S,C|
|Add|ADD|2|CondEn|0|Rs|Rd|6|Rd <- (Rs + Rd)|Z,V,S,C|
|Not|NOT|2|CondEn|0|Rs|Rd|8|Rd <- ~Rs|Z,S|
|And|AND|2|CondEn|0|Rs|Rd|9|Rd <- (Rs & Rd)|Z,S|
|Or|OR|2|CondEn|0|Rs|Rd|10|Rd <- (Rs \| Rd)|Z,S|
|Exclusive Or|XOR|2|CondEn|0|Rs|Rd|11|Rd <- (Rs ^ Rd)|Z,S|
|Move|MOV|2|CondEn|0|Rs|Rd|12|Rd <- Rs|Z,S|

#### J-Type Instruction
J-Type instruction is GOTO instruction only.

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:11]|bit[10:8]|bit[7:5]|bit[4:0]|Operation|
|---|---|---|---|---|---|---|---|---|
|Branch|GOTO|1|CondEn|0|Rs|Rd|0|PC <- {(Rs << 8) + Rd}|

#### F-Type Instruction
SCF and NOP are F-Type instruction. F-Type instruction format is below:

|Instruction|Mnemonic|bit[15:14]|bit[13]|bit[12:9]|bit[8]|bit[7:4]|bit[3]|bit[2]|bit[1]|bit[0]|Operation|
|---|---|---|---|---|---|---|---|---|---|---|---|
|Set Condition bit from Flag|SCF|0|CondEn|4|Inv|0|C|S|V|Z|Condition <- (Inv ^ (Status & bit[3:0]))|
|No Operation|NOP|0|CondEn|0|0|0|0|0|0|0|Do nothing|

SCF instruction copies flag bits to the condition bit based on bit mask in the instruction bit[3:0].
For example, if the instruciton bit[3:0] is 8 (4'b1000), Carry flag is copied to the condition bit.

You can make conditional branch instruction in combination with GOTO instuction and SCF instruction. For example, "Branch if carry" instruction can be achieved like below:
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

### Peripherals
This design has GPIO and SPI peripherals.
#### GPIO
GPIO has 4x Output-only pins and 4x I/O pins.
These pins are mapped 8-bit registers. Upper 4-bits represents output-only pins.

|Address|Name|Description|
|---|---|---|
|0xF000|GPIO Direction|If bit is set, corresponding pin is configured as output,otherwise it is configured as input (Lower 4-bit only)|
|0xF001|GPIO Output Data|Output data value|
|0xF002|GPIO Input Data|Current pin status|

#### SPI Master
SPI peripheral only supports 8-bit data, mode 0.
CS signal is not controlled automatically.

|Address|Name|Description|
|---|---|---|
|0xF004|SPI Clock Divider Value|SPI SCLK frequency[Hz] = (Main Clock / 2) / (Value[3:0] + 1) |
|0xF005|SPI CS Value|CS pin output value (Valid lowest bit only)|
|0xF006|SPI Status|If bit[0] is set, transmission is ongoing|
|0xF007|SPI Tx Data|When write data to this register, SPI transmission will be started|

## How to test
Write program to SPI Flash (by using ROM Writer etc.) and connect it to the board (Please also see the Pinout section).
SPI PSRAM is also needed if you need data storage other than general-purpose regsiters.

When you clear rst_n, then CPU will load instruction from 0x0000 on SPI Flash.

## External hardware
- SPI Flash Memory (W25Q128 etc.)
- SPI PSRAM (IPS6404 etc.) if you want to use external memory