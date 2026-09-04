`timescale 1ns / 1ps

module controller_fsm
#(
    parameter TOTAL_WINDOWS = 531
)
(
    input wire clk,
    input wire start,
    input wire window_valid,

    output reg [1:0] filter_batch = 0,
    output reg [9:0] addr = 0,
    output reg we = 0,
    output reg done = 0
);

localparam IDLE = 2'd0;
localparam RUN  = 2'd1;
localparam DONE = 2'd2;

reg [1:0] state = IDLE;

always @(posedge clk)
begin

case(state)

////////////////////////////////////////////////////////////
// IDLE
////////////////////////////////////////////////////////////

IDLE:
begin
    we   <= 0;
    done <= 0;

    if(start)
    begin
        filter_batch <= 0;
        addr <= 0;
        state <= RUN;
    end
end

////////////////////////////////////////////////////////////
// RUN
////////////////////////////////////////////////////////////

RUN:
begin

    if(window_valid)
    begin
        we <= 1;

        if(addr == TOTAL_WINDOWS-1)
        begin
            addr <= 0;

            if(filter_batch == 3)
            begin
                state <= DONE;
                we <= 0;
            end
            else
            begin
                filter_batch <= filter_batch + 1;
            end
        end
        else
        begin
            addr <= addr + 1;
        end

    end
    else
    begin
        we <= 0;
    end

end

////////////////////////////////////////////////////////////
// DONE
////////////////////////////////////////////////////////////

DONE:
begin
    done <= 1;

    if(!start)
        state <= IDLE;
end

endcase

end

endmodule