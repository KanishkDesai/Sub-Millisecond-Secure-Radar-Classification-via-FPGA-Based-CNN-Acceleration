`timescale 1ns / 1ps

module classifier3
(
    input wire clk,
    input wire start,

    input wire signed [1023:0] feature_bus,

    output reg [1:0] class_out = 0,
    output reg done = 0
);

reg signed [15:0] feature_reg [0:63];

integer i;

reg start_d;
wire start_edge;

always @(posedge clk)
    start_d <= start;

assign start_edge = start & ~start_d;

reg running = 0;
reg bias_stage = 0;
reg argmax_stage = 0;

reg [5:0] idx = 0;

reg signed [47:0] acc0 = 0;
reg signed [47:0] acc1 = 0;
reg signed [47:0] acc2 = 0;


reg signed [47:0] z0;
reg signed [47:0] z1;
reg signed [47:0] z2;


reg signed [15:0] weight0 [0:63];
reg signed [15:0] weight1 [0:63];
reg signed [15:0] weight2 [0:63];



reg signed [47:0] bias [0:2];

initial
begin
    $readmemh("layer8_w0.mem", weight0);
    $readmemh("layer8_w1.mem", weight1);
    $readmemh("layer8_w2.mem", weight2);

    $readmemh("layer9_bias.mem", bias);
end

(* use_dsp = "yes" *)
wire signed [31:0] p0 = feature_reg[idx] * weight0[idx];

(* use_dsp = "yes" *)
wire signed [31:0] p1 = feature_reg[idx] * weight1[idx];

(* use_dsp = "yes" *)
wire signed [31:0] p2 = feature_reg[idx] * weight2[idx];

wire signed [31:0] p0_s = p0 >>> 15;
wire signed [31:0] p1_s = p1 >>> 15;
wire signed [31:0] p2_s = p2 >>> 15;
always @(posedge clk)
begin

    done <= 0;

    if(start_edge)
    begin
        // capture features ONCE (stable)
        for(i=0;i<64;i=i+1)
            feature_reg[i] <= feature_bus[i*16 +: 16];

        running <= 1;
        idx <= 0;

        acc0 <= 0;
        acc1 <= 0;
        acc2 <= 0;
    end

    else if(running)
    begin
        

acc0 <= acc0 + {{16{p0_s[31]}}, p0_s};
acc1 <= acc1 + {{16{p1_s[31]}}, p1_s};
acc2 <= acc2 + {{16{p2_s[31]}}, p2_s};

        idx <= idx + 1;

        if(idx == 6'd63)
        begin
            running <= 0;
            bias_stage <= 1;
        end
    end

    else if(bias_stage)
    begin
        z0 <= acc0 + bias[0];
        z1 <= acc1 + bias[1];
        z2 <= acc2 + bias[2];

        bias_stage <= 0;
        argmax_stage <= 1;
    end

    else if(argmax_stage)
    begin
        if(z0 >= z2)
            class_out <= 2'd0;
        else
            class_out <= 2'd2;

        done <= 1;
        argmax_stage <= 0;
    end

end

endmodule