`timescale 1ns / 1ps
(* DONT_TOUCH = "yes" *)

module conv_engine#(
    parameter ENGINE_ID = 0
)(
    input wire clk,
    input wire signed [431:0] pixel_bus,
    input wire [1:0] filter_batch,
    output reg signed [37:0] result
);

////////////////////////////////////////////////////////////
// WEIGHTS & BIAS
////////////////////////////////////////////////////////////

reg signed [15:0] weight [0:3][0:26];
reg signed [47:0] bias [0:3];   // ✅ FIXED (was 37 bits)

////////////////////////////////////////////////////////////
// TEMP MEMORY FOR READMEMH (IMPORTANT FIX)
////////////////////////////////////////////////////////////

reg signed [15:0] w0 [0:26];
reg signed [15:0] w1 [0:26];
reg signed [15:0] w2 [0:26];
reg signed [15:0] w3 [0:26];

////////////////////////////////////////////////////////////
// LOAD WEIGHTS
////////////////////////////////////////////////////////////

integer k;

initial begin : WEIGHT_BANK

    case (ENGINE_ID)

    0: begin
        $readmemh("conv_e0_f0.mem", w0);
        $readmemh("conv_e0_f1.mem", w1);
        $readmemh("conv_e0_f2.mem", w2);
        $readmemh("conv_e0_f3.mem", w3);
        $readmemh("conv_e0_bias.mem", bias);
    end

    1: begin
        $readmemh("conv_e1_f0.mem", w0);
        $readmemh("conv_e1_f1.mem", w1);
        $readmemh("conv_e1_f2.mem", w2);
        $readmemh("conv_e1_f3.mem", w3);
        $readmemh("conv_e1_bias.mem", bias);
    end

    2: begin
        $readmemh("conv_e2_f0.mem", w0);
        $readmemh("conv_e2_f1.mem", w1);
        $readmemh("conv_e2_f2.mem", w2);
        $readmemh("conv_e2_f3.mem", w3);
        $readmemh("conv_e2_bias.mem", bias);
    end

    3: begin
        $readmemh("conv_e3_f0.mem", w0);
        $readmemh("conv_e3_f1.mem", w1);
        $readmemh("conv_e3_f2.mem", w2);
        $readmemh("conv_e3_f3.mem", w3);
        $readmemh("conv_e3_bias.mem", bias);
    end

    4: begin
        $readmemh("conv_e4_f0.mem", w0);
        $readmemh("conv_e4_f1.mem", w1);
        $readmemh("conv_e4_f2.mem", w2);
        $readmemh("conv_e4_f3.mem", w3);
        $readmemh("conv_e4_bias.mem", bias);
    end

    5: begin
        $readmemh("conv_e5_f0.mem", w0);
        $readmemh("conv_e5_f1.mem", w1);
        $readmemh("conv_e5_f2.mem", w2);
        $readmemh("conv_e5_f3.mem", w3);
        $readmemh("conv_e5_bias.mem", bias);
    end

    6: begin
        $readmemh("conv_e6_f0.mem", w0);
        $readmemh("conv_e6_f1.mem", w1);
        $readmemh("conv_e6_f2.mem", w2);
        $readmemh("conv_e6_f3.mem", w3);
        $readmemh("conv_e6_bias.mem", bias);
    end

    7: begin
        $readmemh("conv_e7_f0.mem", w0);
        $readmemh("conv_e7_f1.mem", w1);
        $readmemh("conv_e7_f2.mem", w2);
        $readmemh("conv_e7_f3.mem", w3);
        $readmemh("conv_e7_bias.mem", bias);
    end

    endcase

    // COPY INTO ACTUAL WEIGHT ARRAY
    for(k=0;k<27;k=k+1)
    begin
        weight[0][k] = w0[k];
        weight[1][k] = w1[k];
        weight[2][k] = w2[k];
        weight[3][k] = w3[k];
    end

end

////////////////////////////////////////////////////////////
// ORIGINAL PIPELINE (UNCHANGED)
////////////////////////////////////////////////////////////

wire signed [15:0] pixel [0:26];
reg signed [431:0] pixel_bus_r;

reg [1:0] fb_swtf, fb_s0, fb_s1, fb_s2, fb_s3, fb_s4, fb_s5, fb_s6;

always @(posedge clk)
begin: STAGE_WTF
    fb_swtf <= filter_batch;
    pixel_bus_r <= pixel_bus;
end

genvar i;
generate
    for(i=0;i<27;i=i+1)
    begin: UNBOX
        assign pixel[i] = pixel_bus_r[i*16 +: 16];
    end
endgenerate

////////////////////////////////////////////////////////////
// MULTIPLY
////////////////////////////////////////////////////////////

wire signed [31:0] prod_w [0:26];
reg signed [31:0] prod_s1 [0:26];

reg signed [15:0] weight_reg [0:26];
reg signed [15:0] pixel_reg [0:26];

always @(posedge clk)
begin: STAGE_0
    integer k;
    fb_s0 <= fb_swtf;
    for(k=0;k<27;k=k+1)
    begin
        weight_reg[k] <= weight[fb_swtf][k];
        pixel_reg[k]  <= pixel[k];
    end
end

generate
    for(i=0;i<27;i=i+1)
    begin: MAKE_MUL
        (* use_dsp = "yes" *)
        assign prod_w[i] = pixel_reg[i] * weight_reg[i];
    end
endgenerate

always @(posedge clk)
begin: STAGE_1
    integer k;
    fb_s1 <= fb_s0;
    for(k=0;k<27;k=k+1)
        prod_s1[k] <= prod_w[k];
end

////////////////////////////////////////////////////////////
// ADD TREE (UNCHANGED LOGIC, DSP-FORCED OFF)
////////////////////////////////////////////////////////////

(* use_dsp = "no" *)
wire signed [32:0] add_s2_w [0:13];
reg  signed [32:0] add_s2   [0:13];

generate
    for(i=0;i<13;i=i+1)
        assign add_s2_w[i] = prod_s1[2*i] + prod_s1[2*i+1];

    assign add_s2_w[13] = prod_s1[26];
endgenerate

always @(posedge clk)
begin: STAGE_2
    integer k;
    for(k=0;k<14;k=k+1)
        add_s2[k] <= add_s2_w[k];
    fb_s2 <= fb_s1;
end

(* use_dsp = "no" *)
wire signed [33:0] add_s3_w [0:6];
reg  signed [33:0] add_s3   [0:6];

generate
    for(i=0;i<7;i=i+1)
        assign add_s3_w[i] = add_s2[2*i] + add_s2[2*i+1];
endgenerate

always @(posedge clk)
begin: STAGE_3
    integer k;
    for(k=0;k<7;k=k+1)
        add_s3[k] <= add_s3_w[k];
    fb_s3 <= fb_s2;
end

(* use_dsp = "no" *)
wire signed [34:0] add_s4_w [0:3];
reg  signed [34:0] add_s4   [0:3];

generate
    for(i=0;i<3;i=i+1)
        assign add_s4_w[i] = add_s3[2*i] + add_s3[2*i+1];

    assign add_s4_w[3] = add_s3[6];
endgenerate

always @(posedge clk)
begin: STAGE_4
    integer k;
    for(k=0;k<4;k=k+1)
        add_s4[k] <= add_s4_w[k];
    fb_s4 <= fb_s3;
end

(* use_dsp = "no" *)
wire signed [35:0] add_s5_w [0:1];
reg  signed [35:0] add_s5   [0:1];

generate
    for(i=0;i<2;i=i+1)
        assign add_s5_w[i] = add_s4[2*i] + add_s4[2*i+1];
endgenerate

always @(posedge clk)
begin: STAGE_5
    integer k;
    for(k=0;k<2;k=k+1)
        add_s5[k] <= add_s5_w[k];
    fb_s5 <= fb_s4;
end

////////////////////////////////////////////////////////////
// FINAL STAGES (FIXED WIDTH)
////////////////////////////////////////////////////////////

(* use_dsp = "no" *)
wire signed [36:0] add_s6_w;
reg  signed [36:0] add_s6;

assign add_s6_w = add_s5[0] + add_s5[1];

always @(posedge clk)
begin: STAGE_6
    add_s6 <= add_s6_w;
    fb_s6 <= fb_s5;
end

// ✅ FIXED WIDTH
(* use_dsp = "no" *)
wire signed [47:0] add_s7_w;
reg  signed [47:0] add_s7;

assign add_s7_w = add_s6 + (bias[fb_s6]<<<13);

always @(posedge clk)
begin
    add_s7 <= add_s7_w;
end

////////////////////////////////////////////////////////////
// RELU + OUTPUT
////////////////////////////////////////////////////////////

wire signed [47:0] relu_s8_w;

assign relu_s8_w = add_s7[47] ? 48'd0 : add_s7;

always @(posedge clk)
begin
    result <= relu_s8_w[37:15];  // truncate safely
end

endmodule