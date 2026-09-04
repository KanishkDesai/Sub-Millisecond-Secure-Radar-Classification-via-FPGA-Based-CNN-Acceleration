`timescale 1ns / 1ps

// ============================================================================
// 128-BIT MIXCOLUMNS WRAPPER
// ============================================================================
module aes_mixcolumns_128 (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : mix_col_loop
            // Extract and process one 32-bit column at a time
            mix_single_column mix_inst (
                .col_in  (state_in[127 - (i*32) -: 32]),
                .col_out (state_out[127 - (i*32) -: 32])
            );
        end
    endgenerate
endmodule

// ============================================================================
// 32-BIT SINGLE COLUMN MIXER
// ============================================================================
module mix_single_column (
    input  wire [31:0] col_in,
    output wire [31:0] col_out
);
    wire [7:0] s0, s1, s2, s3;
    wire [7:0] s0_out, s1_out, s2_out, s3_out;

    assign {s0, s1, s2, s3} = col_in; 

    // Helper function for GF(2^8) multiplication by 2
    function [7:0] mul2;
        input [7:0] x;
        begin
            mul2 = (x[7]) ? ((x << 1) ^ 8'h1b) : (x << 1);
        end
    endfunction

    // Helper function for GF(2^8) multiplication by 3
    function [7:0] mul3;
        input [7:0] x;
        begin
            mul3 = mul2(x) ^ x;
        end
    endfunction

    // Matrix Multiplication logic
    assign s0_out = mul2(s0) ^ mul3(s1) ^ s2       ^ s3;
    assign s1_out = s0       ^ mul2(s1) ^ mul3(s2) ^ s3;
    assign s2_out = s0       ^ s1       ^ mul2(s2) ^ mul3(s3);
    assign s3_out = mul3(s0) ^ s1       ^ s2       ^ mul2(s3);

    assign col_out = {s0_out, s1_out, s2_out, s3_out};
endmodule