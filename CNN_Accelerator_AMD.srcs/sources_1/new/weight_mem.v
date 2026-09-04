`timescale 1ns / 1ps

module weight_memory
#(
    parameter NEURON_ID = 0
)
(
    input wire clk,

    input wire [1:0] batch,
    input wire [14:0] addr,

    output reg signed [15:0] weight,
    output reg signed [47:0] bias
);

(* ram_style = "block" *)
reg signed [15:0] mem [0:17119];

// per neuron weight file load (each neuron has its own mem file)
//    file names: neuron_00.mem ... neuron_63.mem
initial begin
    case (NEURON_ID)
        0:  $readmemh("neuron_00.mem", mem);
        1:  $readmemh("neuron_01.mem", mem);
        2:  $readmemh("neuron_02.mem", mem);
        3:  $readmemh("neuron_03.mem", mem);
        4:  $readmemh("neuron_04.mem", mem);
        5:  $readmemh("neuron_05.mem", mem);
        6:  $readmemh("neuron_06.mem", mem);
        7:  $readmemh("neuron_07.mem", mem);
        8:  $readmemh("neuron_08.mem", mem);
        9:  $readmemh("neuron_09.mem", mem);
        10: $readmemh("neuron_10.mem", mem);
        11: $readmemh("neuron_11.mem", mem);
        12: $readmemh("neuron_12.mem", mem);
        13: $readmemh("neuron_13.mem", mem);
        14: $readmemh("neuron_14.mem", mem);
        15: $readmemh("neuron_15.mem", mem);
        16: $readmemh("neuron_16.mem", mem);
        17: $readmemh("neuron_17.mem", mem);
        18: $readmemh("neuron_18.mem", mem);
        19: $readmemh("neuron_19.mem", mem);
        20: $readmemh("neuron_20.mem", mem);
        21: $readmemh("neuron_21.mem", mem);
        22: $readmemh("neuron_22.mem", mem);
        23: $readmemh("neuron_23.mem", mem);
        24: $readmemh("neuron_24.mem", mem);
        25: $readmemh("neuron_25.mem", mem);
        26: $readmemh("neuron_26.mem", mem);
        27: $readmemh("neuron_27.mem", mem);
        28: $readmemh("neuron_28.mem", mem);
        29: $readmemh("neuron_29.mem", mem);
        30: $readmemh("neuron_30.mem", mem);
        31: $readmemh("neuron_31.mem", mem);
        32: $readmemh("neuron_32.mem", mem);
        33: $readmemh("neuron_33.mem", mem);
        34: $readmemh("neuron_34.mem", mem);
        35: $readmemh("neuron_35.mem", mem);
        36: $readmemh("neuron_36.mem", mem);
        37: $readmemh("neuron_37.mem", mem);
        38: $readmemh("neuron_38.mem", mem);
        39: $readmemh("neuron_39.mem", mem);
        40: $readmemh("neuron_40.mem", mem);
        41: $readmemh("neuron_41.mem", mem);
        42: $readmemh("neuron_42.mem", mem);
        43: $readmemh("neuron_43.mem", mem);
        44: $readmemh("neuron_44.mem", mem);
        45: $readmemh("neuron_45.mem", mem);
        46: $readmemh("neuron_46.mem", mem);
        47: $readmemh("neuron_47.mem", mem);
        48: $readmemh("neuron_48.mem", mem);
        49: $readmemh("neuron_49.mem", mem);
        50: $readmemh("neuron_50.mem", mem);
        51: $readmemh("neuron_51.mem", mem);
        52: $readmemh("neuron_52.mem", mem);
        53: $readmemh("neuron_53.mem", mem);
        54: $readmemh("neuron_54.mem", mem);
        55: $readmemh("neuron_55.mem", mem);
        56: $readmemh("neuron_56.mem", mem);
        57: $readmemh("neuron_57.mem", mem);
        58: $readmemh("neuron_58.mem", mem);
        59: $readmemh("neuron_59.mem", mem);
        60: $readmemh("neuron_60.mem", mem);
        61: $readmemh("neuron_61.mem", mem);
        62: $readmemh("neuron_62.mem", mem);
        63: $readmemh("neuron_63.mem", mem);
        default: $readmemh("neuron_00.mem", mem);
    endcase
end

// --- bias arrays (global per-layer biases) ---
// Files produced by the python script:
//   layer3_dense1_bias.mem  (64 entries, 48-bit hex)
//   layer5_dense2_bias.mem  (64 entries, 48-bit hex)
//   layer7_dense3_bias.mem  (64 entries, 48-bit hex)

reg signed [47:0] bias0 [0:63];
reg signed [47:0] bias1 [0:63];
reg signed [47:0] bias2 [0:63];

initial begin
    $readmemh("layer3_dense1_bias.mem", bias0);
    $readmemh("layer5_dense2_bias.mem", bias1);
    $readmemh("layer7_dense3_bias.mem", bias2);
end

always @(posedge clk)
begin
    case(batch)

        2'd0:
        begin
            weight <= mem[addr];
            bias   <= bias0[NEURON_ID];
        end

        2'd1:
        begin
            weight <= mem[16992 + addr];
            bias   <= bias1[NEURON_ID];
        end

        2'd2:
        begin
            weight <= mem[16992 + 64 + addr];
            bias   <= bias2[NEURON_ID];
        end

        default:
        begin
            weight <= 0;
            bias   <= 0;
        end

    endcase
end

endmodule