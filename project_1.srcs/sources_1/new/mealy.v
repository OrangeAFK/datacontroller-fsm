`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2025 11:22:16 AM
// Design Name: 
// Module Name: mealy
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mealy(
input REQ,
input RW,
input CLK,
input RESET,
input MEM_READY,
output reg MEM_EN,
output reg DATA_EN,
output reg DONE
    );

// state encoding
localparam IDLE = 2'b00;
localparam ACCESS = 2'b01;
localparam DONE_STATE = 2'b10;
reg[1:0] state, next_state;

// next state
always @(*) begin
    case(state)
        IDLE: begin
            if(REQ)
                next_state = ACCESS;
            else
                next_state = IDLE;
        end
        ACCESS: begin
            if(MEM_READY)
                next_state = DONE_STATE;
            else
                next_state = ACCESS;
        end
        DONE_STATE: begin
            next_state = IDLE;
        end
    endcase
end

// output logic
always @(*) begin
    MEM_EN = 0;
    DATA_EN = 0;
    DONE = 0;
    case(state)
        IDLE: begin
            if(REQ)begin
                MEM_EN = 1;
                DATA_EN = 1;
            end
        end
        ACCESS: begin
            MEM_EN = 1;
            DATA_EN = 1;
            if(MEM_READY)
                DONE = 1;
        end
        DONE_STATE: DONE = 1;
    endcase
end

// state register
always @(posedge CLK or posedge RESET) begin
    if(RESET)
        state <= IDLE;
    else
        state <= next_state;
end
   
endmodule
