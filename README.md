# datacontroller-fsm

## Overview
This is an introductory FSM for week 6 of my FPGA+RF roadmap that implements a simple memory read-write controller as both Mealy and Moore machines. The controller handles CPU memory requests, performs read/write operations, and signals completion. I also use this to explore some state encoding choices and testing for timing hazards.

## Controller behavior
### Inputs:
- `REQ`: request signal received from CPU
- `RW`: read/write (0=read, 1=write)
- `MEM_READY`: signal that memory is ready again for operations
- `CLK`: system clock
- `RESET`: asynchronous reset
### Outputs:
- `MEM_EN`: memory enable
- `DATA_EN`: databus enable
- `DONE`: signals completion
### Behavior: 
- Idle until a request is received (`REQ=1`)
- Read/write depending on `RW`
- Enable memory and databus during the operation
- Signal `DONE` when the operation completes
- Return to idle

## State tables
### Mealy:
| Current State | Inputs (REQ, RW, MEM_READY) | Next State | MEM_EN | DATA_EN | DONE |
|---------------|----------------------------|------------|--------|---------|------|
| IDLE          | REQ=0                      | IDLE       | 0      | 0       | 0    |
| IDLE          | REQ=1                      | ACCESS     | 1      | 1       | 0    |
| ACCESS        | MEM_READY=0                | ACCESS     | 1      | 1       | 0    |
| ACCESS        | MEM_READY=1                | DONE       | 1      | 1       | 1    |
| DONE          | X                          | IDLE       | 0      | 0       | 1    |


### Moore:
| State  | Outputs (`MEM_EN`, `DATA_EN`, `DONE`) |
|--------|--------------------------------------|
| IDLE   | 0, 0, 0                              |
| READ   | 1, 1, 0                              |
| WRITE  | 1, 1, 0                              |
| DONE   | 0, 0, 1                              |

State transitions:

IDLE `REQ=1 & RW=0` --> READ

IDLE `REQ=1 & RW=1` --> WRITE

READ -- done --> DONE

WRITE -- done --> DONE

DONE -- `REQ=0` --> IDLE

# FSM Testbench Monitor Results

## Test 1: READ (fast memory)

| TIME    | REQ | RW | MEM_READY | Moore_MEM_EN | Moore_DATA_EN | Moore_DONE | Mealy_MEM_EN | Mealy_DATA_EN | Mealy_DONE |
|---------|-----|----|-----------|--------------|---------------|------------|--------------|---------------|------------|
| 30000   | 1   | 0  | 0         | 0            | 0             | 0          | 1            | 1             | 0          |
| 35000   | 1   | 0  | 0         | 1            | 1             | 0          | 1            | 1             | 0          |
| 50000   | 1   | 0  | 1         | 1            | 1             | 0          | 1            | 1             | 1          |
| 55000   | 1   | 0  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |
| 65000   | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |
| 75000   | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 85000   | 1   | 0  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |
| 95000   | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |

## Test 2: WRITE (slow memory)

| TIME    | REQ | RW | MEM_READY | Moore_MEM_EN | Moore_DATA_EN | Moore_DONE | Mealy_MEM_EN | Mealy_DATA_EN | Mealy_DONE |
|---------|-----|----|-----------|--------------|---------------|------------|--------------|---------------|------------|
| 100000  | 1   | 1  | 0         | 0            | 0             | 1          | 1            | 1             | 0          |
| 180000  | 1   | 1  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 185000  | 1   | 1  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |
| 195000  | 1   | 1  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |
| 205000  | 1   | 1  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |

## Test 3: READ (ready aligns with clock edge)

| TIME    | REQ | RW | MEM_READY | Moore_MEM_EN | Moore_DATA_EN | Moore_DONE | Mealy_MEM_EN | Mealy_DATA_EN | Mealy_DONE |
|---------|-----|----|-----------|--------------|---------------|------------|--------------|---------------|------------|
| 210000  | 1   | 0  | 0         | 0            | 0             | 1          | 1            | 1             | 0          |
| 219000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 225000  | 1   | 0  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |
| 235000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |

## Test 4: WRITE (ready glitch before valid)

| TIME    | REQ | RW | MEM_READY | Moore_MEM_EN | Moore_DATA_EN | Moore_DONE | Mealy_MEM_EN | Mealy_DATA_EN | Mealy_DONE |
|---------|-----|----|-----------|--------------|---------------|------------|--------------|---------------|------------|
| 239000  | 1   | 1  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |
| 242000  | 1   | 1  | 0         | 0            | 0             | 1          | 1            | 1             | 0          |
| 282000  | 1   | 1  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 285000  | 1   | 1  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |

## Test 5: Back-to-back READs

| TIME    | REQ | RW | MEM_READY | Moore_MEM_EN | Moore_DATA_EN | Moore_DONE | Mealy_MEM_EN | Mealy_DATA_EN | Mealy_DONE |
|---------|-----|----|-----------|--------------|---------------|------------|--------------|---------------|------------|
| 292000  | 1   | 0  | 0         | 0            | 0             | 1          | 0            | 0             | 1          |
| 295000  | 1   | 0  | 0         | 0            | 0             | 1          | 1            | 1             | 0          |
| 332000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 335000  | 1   | 0  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |
| 345000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |
| 355000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 362000  | 0   | 0  | 0         | 0            | 0             | 1          | 1            | 1             | 0          |
| 365000  | 0   | 0  | 0         | 0            | 0             | 0          | 1            | 1             | 0          |
| 382000  | 1   | 0  | 0         | 0            | 0             | 0          | 1            | 1             | 0          |
| 385000  | 1   | 0  | 0         | 1            | 1             | 0          | 1            | 1             | 0          |
| 392000  | 1   | 0  | 1         | 1            | 1             | 0          | 1            | 1             | 1          |
| 395000  | 1   | 0  | 1         | 0            | 0             | 1          | 0            | 0             | 1          |
| 405000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 0          |
| 415000  | 1   | 0  | 1         | 0            | 0             | 1          | 1            | 1             | 1          |
| 422000  | 0   | 0  | 0         | 0            | 0             | 1          | 1            | 1             | 0          |
| 425000  | 0   | 0  | 0         | 0            | 0             | 0          | 1            | 1             | 0          |


# Analysis
Generally, it seems that Moore lags by a clock while Mealy responds immediately, meaning it does not respond to the one clock drop in Test 4, which makes Moore marginally stabler and Mealy marginally faster.