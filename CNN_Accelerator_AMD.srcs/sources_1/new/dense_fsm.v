`timescale 1ns / 1ps

module dense_fsm
(
    input  wire clk,
    input  wire start,

    output reg [4:0] bank_channel = 0,
    output reg [9:0] bank_pixel   = 0,

    output reg [14:0] weight_addr = 0,
    output reg [1:0]  batch       = 0,

    output reg clear  = 0,
    output reg enable = 0,

    output reg done = 0
);

localparam INPUT_LAYER  = 16992;
localparam HIDDEN_LAYER = 64;

localparam IDLE  = 0;
localparam RUN   = 1;
localparam FLUSH = 2;
localparam DONE  = 3;

localparam PIPELINE_DELAY = 8;

reg [1:0] state = IDLE;

reg [14:0] input_count = 0;
reg [3:0]  flush_counter = 0;

always @(posedge clk)
begin

case(state)

////////////////////////////////////////////////////////////
// IDLE
////////////////////////////////////////////////////////////

IDLE:
begin

    done <= 0;
    enable <= 0;

    if(start)
    begin
        batch <= 0;
        clear <= 1;

        weight_addr <= 0;
        input_count <= 0;

        bank_channel <= 0;
        bank_pixel   <= 0;

        state <= RUN;
    end

end

////////////////////////////////////////////////////////////
// RUN
////////////////////////////////////////////////////////////

RUN:
begin

    clear  <= 0;
    enable <= 1;

    weight_addr <= weight_addr + 1;
    input_count <= input_count + 1;


    if(batch == 0)
    begin
        if(bank_channel == 31)
        begin
            bank_channel <= 0;
            bank_pixel   <= bank_pixel + 1;
        end
        else
        begin
            bank_channel <= bank_channel + 1;
        end
    end


    if(batch == 0 && input_count == INPUT_LAYER-1)
    begin
        enable <= 0;
        clear <= 1;
        flush_counter <= 0;
        state <= FLUSH;
        batch <= 1;
    end

    else if(batch == 1 && input_count == HIDDEN_LAYER-1)
    begin
        enable <= 0;
        clear <= 1;
        flush_counter <= 0;
        state <= FLUSH;
        batch <= 2;
    end

    else if(batch == 2 && input_count == HIDDEN_LAYER-1)
    begin
        enable <= 0;
        state <= DONE;
    end

end

////////////////////////////////////////////////////////////
// PIPELINE FLUSH
////////////////////////////////////////////////////////////

FLUSH:
begin

    enable <= 0;

    flush_counter <= flush_counter + 1;

    if(flush_counter == PIPELINE_DELAY)
    begin

        weight_addr <= 0;
        input_count <= 0;

        bank_channel <= 0;
        bank_pixel   <= 0;

        state <= RUN;

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