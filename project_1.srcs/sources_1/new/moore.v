`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2025 11:22:16 AM
// Design Name: 
// Module Name: moore
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


module moore(
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
localparam READ = 2'b01;
localparam WRITE = 2'b10;
localparam DONE_STATE = 2'b11;

reg[1:0] state, next_state;

// next state
always @(*) begin
    case(state)
        IDLE: begin
            if(REQ && !RW)
                next_state = READ;
            else if(REQ && RW==1)
                next_state = WRITE;
            else
                next_state = IDLE;
        end
        READ: begin
            if(MEM_READY)
                next_state = DONE_STATE;
            else
                next_state = READ;
        end
        WRITE: begin
            if(MEM_READY)
                next_state = DONE_STATE;
            else
                next_state = WRITE; 
        end
        DONE_STATE: begin
            if(!REQ)
                next_state = IDLE;
            else
                next_state = DONE_STATE;
        end
    endcase
end

// output logic
always @(*) begin
    case(state)
        IDLE: begin
            MEM_EN = 0;
            DATA_EN = 0;
            DONE = 0;
        end
        READ: begin
            MEM_EN = 1;
            DATA_EN = 1;
            DONE = 0;
        end
        WRITE: begin
            MEM_EN = 1;
            DATA_EN = 1;
            DONE = 0;
        end 
        DONE_STATE: begin
            MEM_EN = 0;
            DATA_EN = 0;
            DONE = 1;
        end
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
