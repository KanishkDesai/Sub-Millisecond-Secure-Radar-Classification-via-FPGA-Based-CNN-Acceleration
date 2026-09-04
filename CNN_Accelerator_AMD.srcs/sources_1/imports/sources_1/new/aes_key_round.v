`timescale 1ns / 1ps

module aes_key_round (
    input  wire [7:0]   rcon,      
    input  wire [127:0] key_in,    
    output wire [127:0] key_out   
);

    wire [31:0] w0, w1, w2, w3;          
    wire [31:0] w3_rot;                 
    wire [31:0] w3_sub;                  
    wire [31:0] w0_new, w1_new, w2_new, w3_new; 
    
    assign w0 = key_in[127:96];
    assign w1 = key_in[95:64];
    assign w2 = key_in[63:32];
    assign w3 = key_in[31:0];

    
    assign w3_rot = {w3[23:0], w3[31:24]};

    // reusing the aes_sbox from the subbytes file
    aes_sbox sbox_0 (.in_byte(w3_rot[31:24]), .out_byte(w3_sub[31:24]));
    aes_sbox sbox_1 (.in_byte(w3_rot[23:16]), .out_byte(w3_sub[23:16]));
    aes_sbox sbox_2 (.in_byte(w3_rot[15:8]),  .out_byte(w3_sub[15:8]));
    aes_sbox sbox_3 (.in_byte(w3_rot[7:0]),   .out_byte(w3_sub[7:0]));
    
    assign w0_new = w0 ^ w3_sub ^ {rcon, 24'h000000};
    assign w1_new = w1 ^ w0_new;
    assign w2_new = w2 ^ w1_new;
    assign w3_new = w3 ^ w2_new;

 
    assign key_out = {w0_new, w1_new, w2_new, w3_new};

endmodule