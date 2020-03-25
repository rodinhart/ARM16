# ARM16
- 2 clock cycles per instruction
  - rising edge instruction fetch?
  - falling edge for exec?
- 16 bit instructions word aligned
- 16 bit registers
- 8 registers, R7 is program counter
- 4 bit status register
- status register always updated on ALU operations

## Data paths
![datapaths](comp_arch.png)

## Instruction set

| Assembly | Bits | IN1 | IN2 | IN3 | OUT
| -------- | ---- |:---:|:---:|:---:|:---:
| ldr Rd, [Ra, #x] | `00dd daaa xxxx xxxx` | Ra   |    | IR  | RAM->Rd
| str Rm, [Ra, #x] | `01mm maaa xxxx xxxx` | Ra   | Rm | IR  |
| alu Ra, #x       | `10zz zaaa xxxx xxxx` | Ra   |    | IR  | ALU->Ra
| b\<c\> x         | `110c cccx xxxx xxx0` | R7   |    | IR  | ALU->7
| swi x            | `110x xxxx xxxx xxx1` | 8000 |    | IR  | ALU->7
| shu Ra, #x       | `1110 0aaa 1zzz xxxx` | Ra   |    | IR  | ALU->Ra
| lnk Ra           | `1110 0aaa 1111 xxxx` | R7   |    | IR  | ALU->Ra
| alu Ra, Rm       | `1110 1aaa 0zzz 0mmm` | Ra   | Rm | IN2 | ALU->Ra
| shu Ra, Rm       | `1110 1aaa 1zzz 0mmm` | Ra   | Rm | IN2 | ALU->Ra

## Condition codes

|cccc  |     |      |     |      |  |      |
|:----:|-----|------|-----|------|--|------|--
|`0000`|nv   |`0100`|cc/lo|`1000`|vc|`1100`|lt
|`0001`|eq   |`0101`|mi   |`1001`|hi|`1101`|gt
|`0010`|ne   |`0110`|pl   |`1010`|ls|`1110`|le
|`0011`|cs/hs|`0111`|vs   |`1011`|ge|`1111`|al


## Arithmetic and Logic Unit

|zzz  |Operation|Flags affected
|:---:|---------|--------------
|`000`|mov      |NZ
|`001`|and      |NZ
|`010`|not      |NZ
|`011`|eor      |NZ
|`100`|add      |CNZV
|`101`|adc      |CNZV
|`110`|sub      |CNZV
|`111`|sbc      |CNZV


## Shift Unit

|zzz  |Operation|Flags affected
|:---:|---------|--------------
|`000`|lsl      |CNZ
|`001`|lsr      |CNZ
|`010`|asr      |CNZ
|`011`|ror      |CNZ
|`100`|rrx      |CNZ
|`101`|         |
|`110`|         |
|`111`|lnk      |CNZV

## Status flags

|Status bit|flag|
|---------:|-|
|`0001`    |C
|`0010`    |N
|`0100`    |Z
|`1000`    |V


## Memory map
```txt
      +-------------+
 0000 | reset       | 8 words
 0010 | mapped IO   | 4kb - 8 words
 1000 |             |                  ROM
      |             |
      |             |
      +-------------+ 32kb
 8000 | swi vectors | 8kb (or 8000 - 8080, 64 words?)
 A000 |             |
      |             |                  RAM
      |             |
      |             |
10000 +-------------+ 64kb
```

## TODO

- Can we load from byte boundary (as opposed to word boundary)
- Can we set/clear/read status bits?
