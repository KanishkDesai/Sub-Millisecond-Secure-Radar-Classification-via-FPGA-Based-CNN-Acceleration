`timescale 1ns/1ps

module tb_cnn_top;


reg clk;
reg start;
reg ready;   


reg signed [15:0] pixel_ch0;
reg signed [15:0] pixel_ch1;
reg signed [15:0] pixel_ch2;



wire done;
wire [1:0] class_id;

wire signed [37:0] debug_out;
wire signed [31:0] neuron_checksum;


parameter IMG_W = 61;
parameter IMG_H = 11;

integer r, c;


real ch0_mem [0:IMG_H-1][0:IMG_W-1];
real ch1_mem [0:IMG_H-1][0:IMG_W-1];
real ch2_mem [0:IMG_H-1][0:IMG_W-1];


function signed [15:0] to_fixed;
    input real val;
    real scaled;
    begin
        scaled = val / 3.5;
        to_fixed = $rtoi(scaled * 32768.0);
    end
endfunction


initial begin
    clk = 0;
    forever #5 clk = ~clk;
end



cnn_top DUT
(
    .clk(clk),
    .start(start),
    .ready(ready),   // ✅ added

    .pixel_ch0(pixel_ch0),
    .pixel_ch1(pixel_ch1),
    .pixel_ch2(pixel_ch2),

    .done(done),
    .class_id(class_id),

    .debug_out(debug_out),
    .neuron_checksum(neuron_checksum)
);


integer fd;
integer i, j;
real temp;

initial begin
    fd = $fopen("people4.mem", "r");

    if (fd == 0) begin
        $display("ERROR: Cannot open file");
        $finish;
    end

    for(i = 0; i < IMG_H; i = i + 1)
        for(j = 0; j < IMG_W; j = j + 1) begin
            $fscanf(fd, "%f", temp);
            ch0_mem[i][j] = temp;
        end

    for(i = 0; i < IMG_H; i = i + 1)
        for(j = 0; j < IMG_W; j = j + 1) begin
            $fscanf(fd, "%f", temp);
            ch1_mem[i][j] = temp;
        end

    for(i = 0; i < IMG_H; i = i + 1)
        for(j = 0; j < IMG_W; j = j + 1) begin
            $fscanf(fd, "%f", temp);
            ch2_mem[i][j] = temp;
        end

    $fclose(fd);
end


initial begin

    start = 0;
    ready = 0;

    pixel_ch0 = 0;
    pixel_ch1 = 0;
    pixel_ch2 = 0;

    #100;

    $display("=================================");
    $display("STARTING IMAGE STREAM");
    $display("=================================");

    start = 1;

    @(posedge clk);

    repeat(4)
    begin
      

        ready = 0;
        pixel_ch0 = 0;
        pixel_ch1 = 0;
        pixel_ch2 = 0;

        repeat(5) @(posedge clk);

      

        @(negedge clk);
        pixel_ch0 = to_fixed(ch0_mem[0][0]);
        pixel_ch1 = to_fixed(ch1_mem[0][0]);
        pixel_ch2 = to_fixed(ch2_mem[0][0]);

       

        ready = 1;

        for(r = 0; r < IMG_H; r = r + 1)
        begin
            for(c = 0; c < IMG_W; c = c + 1)
            begin
                if(r==0 && c==0) begin end
                else begin
                    @(negedge clk);

                    pixel_ch0 = to_fixed(ch0_mem[r][c]);
                    pixel_ch1 = to_fixed(ch1_mem[r][c]);
                    pixel_ch2 = to_fixed(ch2_mem[r][c]);
                end
            end
        end


        repeat(2) @(posedge clk);
    end

end


integer conv_printed = 0;

always @(posedge clk)
begin
    if(DUT.conv_done_d[DUT.LAT-1] && conv_printed == 0)
    begin
        $display("=================================");
        $display("CONVOLUTION FINISHED");
        $display("=================================");
        conv_printed = 1;
    end
end

always @(posedge clk)
begin
    if(DUT.we_d[DUT.LAT-1])
    begin
        $display("FEATURE WRITE addr=%0d batch=%0d",
            DUT.addr_d[DUT.LAT-1],
            DUT.batch_d[DUT.LAT-1]
        );
    end
end

always @(posedge clk)
begin
    if(DUT.DENSE.enable)
    begin
        $display(
        "[DENSE] t=%0t | batch=%0d addr=%0d act=%0d weight=%0d product=%0d -> neuron[%0d]=%0d",
            $time,
            DUT.DENSE.FSM.batch,
            DUT.DENSE.FSM.weight_addr,
            DUT.DENSE.activation,
            DUT.DENSE.debug_weight,
            DUT.DENSE.activation * DUT.DENSE.debug_weight,
            DUT.DENSE.input_index,
            DUT.DENSE.layer_reg[DUT.DENSE.input_index]
        );
    end
end

integer n;

initial begin

    wait(done);

    #50;

    $display("");
    $display("=================================");
    $display("CNN INFERENCE COMPLETE");
    $display("=================================");

    for(n=0; n<64; n=n+1)
    begin
        $display("Neuron %0d = %0d",
            n,
            DUT.DENSE.layer_reg[n]
        );
    end

    $display("");
    $display("=================================");
    $display("FINAL CLASSIFICATION");
    $display("=================================");

    $display("Predicted Class = %0d", class_id);

    $display("z0 = %0d", DUT.CLASSIFIER.z0);
    $display("z1 = %0d", DUT.CLASSIFIER.z1);
    $display("z2 = %0d", DUT.CLASSIFIER.z2);

    $display("");
    $display("Neuron checksum = %0d", neuron_checksum);

    $display("");
    $display("=================================");
    $display("TEST COMPLETE");
    $display("=================================");

    $finish;

end

endmodule