`timescale 1ns / 1ps
(* DONT_TOUCH = "yes" *)
module conv_cluster(
    input wire clk,
    input wire signed [431:0] pixel_bus,
    input wire [1:0] filter_batch,
    output wire signed [303:0] out_bus
);

genvar i;

generate
for(i=0;i<8;i=i+1)
begin: ENGINE

    conv_engine#(
    .ENGINE_ID(i)
)  CE(
        .clk(clk),
        .pixel_bus(pixel_bus),
        .filter_batch(filter_batch),
        .result(out_bus[i*38 +: 38])
    );

end
endgenerate

endmodule
