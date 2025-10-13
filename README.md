# datacontroller-fsm

## Overview
This is an introductory FSM for week 6 of my FPGA+RF roadmap that implements a simple memory read-write controller as both Mealy and Moore machines. The controller handles CPU memory requests, performs read/write operations, and signals completion. I also use this to explore some state encoding choices and testing for timing hazards.

## Controller behavior
### Inputs:
- `REQ`: request signal received from CPU
- `RW`: read/write (0=read, 1=write)
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
| Current State | Input (`REQ`, `RW`) | Next State | Outputs (`MEM_EN`, `DATA_EN`, `DONE`) |
|---------------|--------------------|------------|--------------------------------------|
| IDLE          | 0, X               | IDLE       | 0, 0, 0                              |
| IDLE          | 1, 0               | ACCESS     | 1, 1, 0                              |
| IDLE          | 1, 1               | ACCESS     | 1, 1, 0                              |
| ACCESS        | -                  | DONE       | 0, 0, 1                              |
| DONE          | X                  | IDLE       | 0, 0, 0                              |

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
