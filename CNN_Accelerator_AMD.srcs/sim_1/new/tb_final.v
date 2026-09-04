`timescale 1ns/1ps

module tb_final;

reg clk;
reg start;
reg ready;
reg rst_n;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

reg signed [15:0] pixel_ch0;
reg signed [15:0] pixel_ch1;
reg signed [15:0] pixel_ch2;

wire done;
wire alive;
wire [1:0] class_id;

wire signed [37:0] debug_out;
wire [127:0] ciphertext;
wire aes_valid_out;

wire signed [47:0] z0;
wire signed [47:0] z1;
wire signed [47:0] z2;

final_top DUT(
    .clk(clk),
    .start(start),
    .ready(ready),
    .rst_n(rst_n),
    .aes_key(128'h2b7e151628aed2a6abf7158809cf4f3c),
    .pixel_ch0(pixel_ch0),
    .pixel_ch1(pixel_ch1),
    .pixel_ch2(pixel_ch2),
    .done(done),
    .class_id(class_id),
    .alive(alive)
);

// internal taps (simulation only)
assign debug_out     = DUT.debug_out;
assign ciphertext    = DUT.ciphertext;
assign aes_valid_out = DUT.aes_valid_out;

assign z0 = DUT.CNN.CLASSIFIER.z0;
assign z1 = DUT.CNN.CLASSIFIER.z1;
assign z2 = DUT.CNN.CLASSIFIER.z2;

parameter IMG_W = 61;
parameter IMG_H = 11;

real ch0_mem [0:IMG_H-1][0:IMG_W-1];
real ch1_mem [0:IMG_H-1][0:IMG_W-1];
real ch2_mem [0:IMG_H-1][0:IMG_W-1];

reg [15:0] original_pixels [0:5000];
reg [15:0] aes_pixels      [0:5000];

integer orig_idx;
integer aes_idx;

function signed [15:0] to_fixed;
    input real val;
    real scaled;
    begin
        scaled = val / 3.5;
        to_fixed = $rtoi(scaled * 32768.0);
    end
endfunction

integer fd, i, j;
real temp;

initial begin
    fd = $fopen("drone1.mem", "r");

    for(i=0;i<IMG_H;i=i+1)
    for(j=0;j<IMG_W;j=j+1) begin
        $fscanf(fd,"%f",temp);
        ch0_mem[i][j] = temp;
    end

    for(i=0;i<IMG_H;i=i+1)
    for(j=0;j<IMG_W;j=j+1) begin
        $fscanf(fd,"%f",temp);
        ch1_mem[i][j] = temp;
    end

    for(i=0;i<IMG_H;i=i+1)
    for(j=0;j<IMG_W;j=j+1) begin
        $fscanf(fd,"%f",temp);
        ch2_mem[i][j] = temp;
    end

    $fclose(fd);
end

integer k;

always @(posedge clk) begin
    if (aes_valid_out) begin
        for (k = 0; k < 8; k = k + 1) begin
            aes_pixels[aes_idx + k] = ciphertext[(7-k)*16 +: 16];
        end
        aes_idx = aes_idx + 8;
    end
end

integer r, c;

initial begin
    start = 0;
    ready = 0;
    rst_n = 0;

    pixel_ch0 = 0;
    pixel_ch1 = 0;
    pixel_ch2 = 0;

    orig_idx = 0;
    aes_idx  = 0;

    #50 rst_n = 1;
    #100;

    @(posedge clk); #1;
    start = 1;

    repeat(4)
    begin
        ready = 0;
        repeat(5) @(posedge clk);

        @(posedge clk); #1;

        pixel_ch0 = to_fixed(ch0_mem[0][0]);
        pixel_ch1 = to_fixed(ch1_mem[0][0]);
        pixel_ch2 = to_fixed(ch2_mem[0][0]);

        original_pixels[orig_idx] = pixel_ch0; orig_idx = orig_idx + 1;
        original_pixels[orig_idx] = pixel_ch1; orig_idx = orig_idx + 1;
        original_pixels[orig_idx] = pixel_ch2; orig_idx = orig_idx + 1;

        ready = 1;

        for(r=0;r<IMG_H;r=r+1)
        begin
            for(c=0;c<IMG_W;c=c+1)
            begin
                if(!(r==0 && c==0)) begin
                    @(posedge clk); #1;

                    pixel_ch0 = to_fixed(ch0_mem[r][c]);
                    pixel_ch1 = to_fixed(ch1_mem[r][c]);
                    pixel_ch2 = to_fixed(ch2_mem[r][c]);

                    original_pixels[orig_idx] = pixel_ch0; orig_idx = orig_idx + 1;
                    original_pixels[orig_idx] = pixel_ch1; orig_idx = orig_idx + 1;
                    original_pixels[orig_idx] = pixel_ch2; orig_idx = orig_idx + 1;
                end
            end
        end

        repeat(2) @(posedge clk);
    end
end

initial begin
    wait(done);
    #50;

    $display("\n=================================");
    $display("CNN INFERENCE COMPLETE");
    $display("=================================");

    $display("z0 = %0d", z0);
    $display("z1 = %0d", z1);
    $display("z2 = %0d", z2);

    $display("Predicted Class = %0d", class_id);

    $display("\n=================================");
    $display("AES OUTPUTS");
    $display("=================================");

    for (i = 0; i < 2014; i = i + 1) begin
        $display("%0d : orig=%0d enc=%0d",
                 i, original_pixels[i], aes_pixels[i]);
    end

    $display("=================================\n");

    $finish;
end

endmodule