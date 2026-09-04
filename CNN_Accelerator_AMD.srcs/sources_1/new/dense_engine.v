`timescale 1ns / 1ps

module dense_engine
(
    input  wire clk,
    input  wire clear,
    input  wire enable,

    input  wire signed [15:0] activation,
    input  wire signed [15:0] weight,
    input  wire signed [47:0] bias,

    output reg  signed [47:0] acc
);

(* use_dsp = "yes" *)
wire signed [31:0] mult;

assign mult = activation * weight;

reg signed [31:0] mult_reg;

always @(posedge clk)
begin
    mult_reg <= mult;
end

(* use_dsp = "no" *) //trying to fit into 240 dsps
wire signed [47:0] acc_next;

assign acc_next = acc + {{16{mult_reg[31]}}, mult_reg};

always @(posedge clk)
begin
    if(clear)
        acc <= bias <<< 13;
    else if(enable)
        acc <= acc_next;
end

endmodule