`timescale 1ns / 1ps

module dense_cluster
(
    input wire clk,
    input wire clear,
    input wire enable,

    input wire signed [15:0] activation,

    input wire [14:0] weight_addr,
    input wire [1:0] batch,

    output wire [3071:0] neuron_out_bus,

    output wire signed [15:0] debug_weight
);

genvar i;

generate
for(i=0;i<64;i=i+1)
begin : neuron_block

    wire signed [15:0] weight;
    wire signed [47:0] bias;
    wire signed [47:0] acc;

    weight_memory
    #(
        .NEURON_ID(i)
    )
    WM
    (
        .clk(clk),
        .batch(batch),
        .addr(weight_addr),
        .weight(weight),
        .bias(bias)
    );
    (* DONT_TOUCH = "yes" *)
    dense_engine NEURON
    (
        .clk(clk),
        .clear(clear),
        .enable(enable),

        .activation(activation),
        .weight(weight),
        .bias(bias),

        .acc(acc)
    );

    assign neuron_out_bus[i*48 +: 48] = acc;

    if(i==0)
        assign debug_weight = weight;

end
endgenerate

endmodule