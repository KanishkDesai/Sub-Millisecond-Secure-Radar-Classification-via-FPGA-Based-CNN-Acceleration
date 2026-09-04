`timescale 1ns / 1ps

module aes_128_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire [127:0] key,
    input  wire [127:0] plaintext,
    output wire [127:0] ciphertext,
    output wire         valid_out
);

    wire [1407:0] all_round_keys;
    aes_key_schedule_unrolled key_gen (
        .key_in         (key),
        .all_round_keys (all_round_keys)
    );

    reg [1407:0] pipe_data;  
    reg [10:0]   pipe_valid; 

    wire [127:0] stage0_out = plaintext ^ all_round_keys[0 +: 128];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid[0] <= 1'b0;
            pipe_data[127:0] <= 128'd0;
        end else begin
            pipe_valid[0] <= valid_in;
            pipe_data[127:0] <= stage0_out;
        end
    end

    
    wire [1151:0] round_out_flat; // 9 rounds * 128 bits

    genvar i;
    generate
        for (i = 1; i <= 9; i = i + 1) begin : pipe_rounds
            
            aes_standard_round round_inst (
                .state_in  (pipe_data[ (i-1)*128 +: 128 ]),
                .round_key (all_round_keys[ i*128 +: 128 ]),
                .state_out (round_out_flat[ (i-1)*128 +: 128 ])
            );

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe_valid[i] <= 1'b0;
                    pipe_data[ i*128 +: 128 ] <= 128'd0;
                end else begin
                    pipe_valid[i] <= pipe_valid[i-1];
                    pipe_data[ i*128 +: 128 ] <= round_out_flat[ (i-1)*128 +: 128 ];
                end
            end
        end
    endgenerate

    
    wire [127:0] final_sub_out, final_shift_out, final_out;

    aes_subbytes_128    final_sub   (.state_in(pipe_data[ 9*128 +: 128 ]),  .state_out(final_sub_out));
    aes_shiftrows_128   final_shift (.state_in(final_sub_out),              .state_out(final_shift_out));
    aes_addroundkey_128 final_key   (.state_in(final_shift_out),            .round_key(all_round_keys[ 10*128 +: 128 ]), .state_out(final_out));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid[10] <= 1'b0;
            pipe_data[ 10*128 +: 128 ] <= 128'd0;
        end else begin
            pipe_valid[10] <= pipe_valid[9];
            pipe_data[ 10*128 +: 128 ] <= final_out;
        end
    end

    
    assign ciphertext = pipe_data[ 10*128 +: 128 ];
    assign valid_out  = pipe_valid[10];

endmodule