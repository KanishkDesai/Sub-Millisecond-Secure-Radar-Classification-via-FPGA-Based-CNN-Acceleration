`timescale 1ns / 1ps

module aes_key_schedule_unrolled (
    input  wire [127:0]  key_in,
    output wire [1407:0] all_round_keys // 11 keys * 128 bits
);

    wire [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;


    assign k0 = key_in;
    
    
    aes_key_round kr1  (.rcon(8'h01), .key_in(k0), .key_out(k1));
    aes_key_round kr2  (.rcon(8'h02), .key_in(k1), .key_out(k2));
    aes_key_round kr3  (.rcon(8'h04), .key_in(k2), .key_out(k3));
    aes_key_round kr4  (.rcon(8'h08), .key_in(k3), .key_out(k4));
    aes_key_round kr5  (.rcon(8'h10), .key_in(k4), .key_out(k5));
    aes_key_round kr6  (.rcon(8'h20), .key_in(k5), .key_out(k6));
    aes_key_round kr7  (.rcon(8'h40), .key_in(k6), .key_out(k7));
    aes_key_round kr8  (.rcon(8'h80), .key_in(k7), .key_out(k8));
    aes_key_round kr9  (.rcon(8'h1b), .key_in(k8), .key_out(k9));
    aes_key_round kr10 (.rcon(8'h36), .key_in(k9), .key_out(k10));

    // k10 is at the top (MSB), k0 is at the bottom (LSB)
    assign all_round_keys = {k10, k9, k8, k7, k6, k5, k4, k3, k2, k1, k0};

endmodule