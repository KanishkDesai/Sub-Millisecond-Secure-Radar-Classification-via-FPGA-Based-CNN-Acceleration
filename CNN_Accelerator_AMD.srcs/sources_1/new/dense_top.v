`timescale 1ns / 1ps

module dense_top
(
    input wire clk,
    input wire start,


    input wire signed [15:0] bank_data,

    output wire [4:0] bank_channel,
    output wire [9:0] bank_pixel,
    output wire signed [1023:0] feature_bus,

    output wire done,

    output wire signed [15:0] debug_weight,


    output wire signed [47:0] neuron_checksum //ensures neurons arent pruned
);

wire [14:0] weight_addr;
wire [1:0]  batch;

wire clear;
wire enable;

dense_fsm FSM
(
    .clk(clk),
    .start(start),
    
    .bank_channel(bank_channel),
    .bank_pixel(bank_pixel),

    .weight_addr(weight_addr),
    .batch(batch),

    .clear(clear),
    .enable(enable),

    .done(done)
);


reg signed [47:0] layer_reg [0:63];



integer k;

always @(posedge clk)
begin
    if(clear && batch == 0)
    begin
        for(k=0;k<64;k=k+1)
            layer_reg[k] <= 0;
    end
end


wire [5:0] input_index;
assign input_index = weight_addr[5:0];

parameter SHIFT_0 = 20;
parameter SHIFT_1 = 18;
parameter SHIFT_2 = 15;

reg signed [47:0] scaled;

always @(*)
begin
    case(batch)
        2'd0: scaled = (layer_reg[input_index] + (1 <<< (SHIFT_0-1))) >>> SHIFT_0;
        2'd1: scaled = (layer_reg[input_index] + (1 <<< (SHIFT_1-1))) >>> SHIFT_1;
        2'd2: scaled = (layer_reg[input_index] + (1 <<< (SHIFT_2-1))) >>> SHIFT_2;
        default: scaled = 0;
    endcase
end

wire signed [15:0] activation_raw =
        (batch == 0) ? bank_data :
        (scaled > 32767)  ? 32767 :
        (scaled < -32768) ? -32768 :
                            scaled[15:0];


reg signed [15:0] activation_reg;

always @(posedge clk)
begin
    activation_reg <= activation_raw;
end

wire signed [15:0] activation = activation_reg;

////////////////////////////////////////////////////////////
// 8-CYCLE FEATUREMAP WARMUP (pain to realsie)
////////////////////////////////////////////////////////////

reg [3:0] warm_counter = 0;
reg warm_active = 0;
reg enable_warm = 0;

always @(posedge clk)
begin
    if(clear && batch == 0)
    begin
        warm_active <= 1;
        warm_counter <= 0;
        enable_warm <= 0;
    end
    else if(warm_active)
    begin
        warm_counter <= warm_counter + 1;

        if(warm_counter == 8)
        begin
            warm_active <= 0;
            enable_warm <= enable;
        end
    end
    else
    begin
        enable_warm <= enable;
    end
end


reg clear_d1, clear_d2;
reg enable_d1, enable_d2;

always @(posedge clk)
begin
    clear_d1  <= clear;
    clear_d2  <= clear_d1;

    enable_d1 <= enable_warm;
    enable_d2 <= enable_d1;
end


wire [3071:0] neuron_out_bus;

dense_cluster CLUSTER
(
    .clk(clk),
    .clear(clear_d2),
    .enable(enable_d2),

    .activation(activation_reg),

    .weight_addr(weight_addr),
    .batch(batch),

    .neuron_out_bus(neuron_out_bus),

    .debug_weight(debug_weight)
);


reg [3071:0] neuron_out_bus_reg;

always @(posedge clk)
    if(enable_d2)
        neuron_out_bus_reg <= neuron_out_bus;


reg clear_prev;

always @(posedge clk)
    clear_prev <= clear_d2;

wire layer_done = clear_d2 && !clear_prev;


integer i;

always @(posedge clk)
begin
    if(layer_done && batch != 0)
    begin
        for(i=0;i<64;i=i+1)
        begin
            if($signed(neuron_out_bus_reg[i*48 +: 48]) < 0)
                layer_reg[i] <= 0;
            else
                layer_reg[i] <= neuron_out_bus_reg[i*48 +: 48];
        end
    end
end

genvar j;

generate
for(j=0;j<64;j=j+1)
begin
    assign feature_bus[j*16 +: 16] =
        (batch == 2'd0) ? (layer_reg[j] >>> SHIFT_0) :
        (batch == 2'd1) ? (layer_reg[j] >>> SHIFT_1) :
                          (layer_reg[j] >>> SHIFT_2);
end
endgenerate


wire signed [47:0] checksum;

assign checksum =
      layer_reg[0]  ^ layer_reg[1]  ^ layer_reg[2]  ^ layer_reg[3]
    ^ layer_reg[4]  ^ layer_reg[5]  ^ layer_reg[6]  ^ layer_reg[7]
    ^ layer_reg[8]  ^ layer_reg[9]  ^ layer_reg[10] ^ layer_reg[11]
    ^ layer_reg[12] ^ layer_reg[13] ^ layer_reg[14] ^ layer_reg[15]
    ^ layer_reg[16] ^ layer_reg[17] ^ layer_reg[18] ^ layer_reg[19]
    ^ layer_reg[20] ^ layer_reg[21] ^ layer_reg[22] ^ layer_reg[23]
    ^ layer_reg[24] ^ layer_reg[25] ^ layer_reg[26] ^ layer_reg[27]
    ^ layer_reg[28] ^ layer_reg[29] ^ layer_reg[30] ^ layer_reg[31]
    ^ layer_reg[32] ^ layer_reg[33] ^ layer_reg[34] ^ layer_reg[35]
    ^ layer_reg[36] ^ layer_reg[37] ^ layer_reg[38] ^ layer_reg[39]
    ^ layer_reg[40] ^ layer_reg[41] ^ layer_reg[42] ^ layer_reg[43]
    ^ layer_reg[44] ^ layer_reg[45] ^ layer_reg[46] ^ layer_reg[47]
    ^ layer_reg[48] ^ layer_reg[49] ^ layer_reg[50] ^ layer_reg[51]
    ^ layer_reg[52] ^ layer_reg[53] ^ layer_reg[54] ^ layer_reg[55]
    ^ layer_reg[56] ^ layer_reg[57] ^ layer_reg[58] ^ layer_reg[59]
    ^ layer_reg[60] ^ layer_reg[61] ^ layer_reg[62] ^ layer_reg[63];

assign neuron_checksum = checksum; //this is just for debug

endmodule