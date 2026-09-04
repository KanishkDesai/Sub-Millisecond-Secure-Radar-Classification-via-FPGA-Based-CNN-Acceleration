`timescale 1ns / 1ps

module cnn_top
(
    input wire clk,
    input wire start,
    input wire ready,   

    input wire [15:0] pixel_ch0,
    input wire [15:0] pixel_ch1,
    input wire [15:0] pixel_ch2,

    output wire done,
    output wire [1:0] class_id,
    output wire signed [37:0] debug_out,
    output wire signed [31:0] neuron_checksum
);

wire signed [1023:0] feature_bus;
wire classifier_done;

wire signed [15:0] dense_debug_weight;

wire [15:0] ch0_w [0:8];
wire [15:0] ch1_w [0:8];
wire [15:0] ch2_w [0:8];

wire valid0;
wire valid1;
wire valid2;

////////////////////////////////////////////////////////////
// making valid windows
////////////////////////////////////////////////////////////

window_generator WG0(
    .clk(clk),
    .ready(ready),
    .pix_r0(pixel_ch0),
    .window_valid(valid0),

    .w0(ch0_w[0]), .w1(ch0_w[1]), .w2(ch0_w[2]),
    .w3(ch0_w[3]), .w4(ch0_w[4]), .w5(ch0_w[5]),
    .w6(ch0_w[6]), .w7(ch0_w[7]), .w8(ch0_w[8])
);

window_generator WG1(
    .clk(clk),
    .ready(ready),
    .pix_r0(pixel_ch1),
    .window_valid(valid1),

    .w0(ch1_w[0]), .w1(ch1_w[1]), .w2(ch1_w[2]),
    .w3(ch1_w[3]), .w4(ch1_w[4]), .w5(ch1_w[5]),
    .w6(ch1_w[6]), .w7(ch1_w[7]), .w8(ch1_w[8])
);

window_generator WG2(
    .clk(clk),
    .ready(ready),
    .pix_r0(pixel_ch2),
    .window_valid(valid2),

    .w0(ch2_w[0]), .w1(ch2_w[1]), .w2(ch2_w[2]),
    .w3(ch2_w[3]), .w4(ch2_w[4]), .w5(ch2_w[5]),
    .w6(ch2_w[6]), .w7(ch2_w[7]), .w8(ch2_w[8])
);

wire window_valid;
assign window_valid = valid0 & valid1 & valid2;


wire signed [431:0] pixel_bus;

assign pixel_bus = {
    ch2_w[8],ch2_w[7],ch2_w[6],ch2_w[5],ch2_w[4],ch2_w[3],ch2_w[2],ch2_w[1],ch2_w[0],
    ch1_w[8],ch1_w[7],ch1_w[6],ch1_w[5],ch1_w[4],ch1_w[3],ch1_w[2],ch1_w[1],ch1_w[0],
    ch0_w[8],ch0_w[7],ch0_w[6],ch0_w[5],ch0_w[4],ch0_w[3],ch0_w[2],ch0_w[1],ch0_w[0]
};

wire [1:0] filter_batch_raw;
wire [9:0] addr_raw;
wire we_raw;
wire conv_done_raw;

controller_fsm FSM(
    .clk(clk),
    .start(start),
    .window_valid(window_valid),

    .filter_batch(filter_batch_raw),
    .addr(addr_raw),
    .we(we_raw),
    .done(conv_done_raw)
);

wire signed [303:0] result_bus;

conv_cluster CLUSTER(
    .clk(clk),
    .pixel_bus(pixel_bus),
    .filter_batch(filter_batch_raw),
    .out_bus(result_bus)
);

wire signed [37:0] debug_sum;

assign debug_sum =
      result_bus[37:0]
    + result_bus[75:38]
    + result_bus[113:76]
    + result_bus[151:114]
    + result_bus[189:152]
    + result_bus[227:190]
    + result_bus[265:228]
    + result_bus[303:266];

assign debug_out = debug_sum;

parameter LAT = 10;

reg we_d [0:LAT-1];
reg conv_done_d [0:LAT-1];
reg [9:0] addr_d [0:LAT-1];
reg [1:0] batch_d [0:LAT-1];

integer i;

always @(posedge clk)
begin
    we_d[0]        <= we_raw;
    conv_done_d[0] <= conv_done_raw;
    addr_d[0]      <= addr_raw;
    batch_d[0]     <= filter_batch_raw;

    for(i=1;i<LAT;i=i+1)
    begin
        we_d[i]        <= we_d[i-1];
        conv_done_d[i] <= conv_done_d[i-1];
        addr_d[i]      <= addr_d[i-1];
        batch_d[i]     <= batch_d[i-1];
    end
end

wire [4:0] dense_channel;
wire [9:0] dense_pixel;
wire signed [15:0] bank_data;

featuremap_banks BANKS(
    .clk(clk),

    .we(we_d[LAT-1]),
    .filter_batch(batch_d[LAT-1]),
    .addr(addr_d[LAT-1]),
    .in_bus(result_bus),

    .rd_channel(dense_channel),
    .rd_pixel(dense_pixel),
    .rd_data(bank_data)
);

wire dense_done;

dense_top DENSE(
    .clk(clk),
    .start(conv_done_d[LAT-1]),

    .bank_data(bank_data),
    .bank_channel(dense_channel),
    .bank_pixel(dense_pixel),

    .done(dense_done),

    .debug_weight(dense_debug_weight),
    .neuron_checksum(neuron_checksum),
    .feature_bus(feature_bus)
);

classifier3 CLASSIFIER(
    .clk(clk),
    .start(dense_done),

    .feature_bus(feature_bus),

    .class_out(class_id),
    .done(classifier_done)
);

assign done = classifier_done;

endmodule