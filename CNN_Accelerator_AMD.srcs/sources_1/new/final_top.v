`timescale 1ns / 1ps

module final_top
(
    input wire clk,
    input wire start,
    input wire ready,
    input wire rst_n,

    input wire [127:0] aes_key,

    input wire signed [15:0] pixel_ch0,
    input wire signed [15:0] pixel_ch1,
    input wire signed [15:0] pixel_ch2,

    output wire done,
    output wire [1:0] class_id,

    output wire alive
);



wire signed [37:0] debug_out;
wire signed [31:0] neuron_checksum;

wire [127:0] ciphertext;
wire aes_valid_out;



(* DONT_TOUCH = "yes" *)
cnn_top CNN (
    .clk(clk),
    .start(start),
    .ready(ready),
    .pixel_ch0(pixel_ch0),
    .pixel_ch1(pixel_ch1),
    .pixel_ch2(pixel_ch2),
    .done(done),
    .class_id(class_id),
    .debug_out(debug_out),
    .neuron_checksum(neuron_checksum)
);



reg [1:0] sel;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel <= 0;
    else if (ready)
        sel <= sel + 1;
end

wire [15:0] pixel_stream_comb;

assign pixel_stream_comb =
    (sel == 2'd0) ? pixel_ch0 :
    (sel == 2'd1) ? pixel_ch1 :
    (sel == 2'd2) ? pixel_ch2 :
                    16'd0;



reg [15:0] pixel_stream;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pixel_stream <= 0;
    else if (ready)
        pixel_stream <= pixel_stream_comb;
end



reg [127:0] shift_reg;
reg [2:0] count;
reg aes_valid_in;
reg [127:0] plaintext_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 0;
        count <= 0;
        aes_valid_in <= 0;
        plaintext_reg <= 0;
    end else begin
        aes_valid_in <= 0;

        if (ready) begin
            shift_reg <= {shift_reg[111:0], pixel_stream};

            if (count == 3'd7) begin
                plaintext_reg <= {shift_reg[111:0], pixel_stream};
                aes_valid_in <= 1;
                count <= 0;
            end else begin
                count <= count + 1;
            end
        end
    end
end



(* DONT_TOUCH = "yes" *)
aes_128_top AES (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(aes_valid_in),
    .key(aes_key),
    .plaintext(plaintext_reg),
    .ciphertext(ciphertext),
    .valid_out(aes_valid_out)
);



reg [127:0] alive_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        alive_reg <= 128'h69;  // non-zero seed
    else begin
        alive_reg <= {
            alive_reg[126:0],
            alive_reg[127] ^
            ^ciphertext ^
            ^neuron_checksum ^
            ^debug_out ^
            aes_valid_out ^
            done ^
            ^class_id
        };
    end
end

assign alive = alive_reg[127];

endmodule