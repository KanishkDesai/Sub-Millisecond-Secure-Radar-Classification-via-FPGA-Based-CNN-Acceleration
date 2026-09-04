`timescale 1ns / 1ps


module aes_standard_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] subbytes_out;
    wire [127:0] shiftrows_out;
    wire [127:0] mixcolumns_out;


    aes_subbytes_128 u_subbytes (
        .state_in  (state_in),
        .state_out (subbytes_out)
    );

   
    aes_shiftrows_128 u_shiftrows (
        .state_in  (subbytes_out),
        .state_out (shiftrows_out)
    );

    
    aes_mixcolumns_128 u_mixcolumns (
        .state_in  (shiftrows_out),
        .state_out (mixcolumns_out)
    );

   
    aes_addroundkey_128 u_addroundkey (
        .state_in  (mixcolumns_out),
        .round_key (round_key),
        .state_out (state_out)
    );

endmodule