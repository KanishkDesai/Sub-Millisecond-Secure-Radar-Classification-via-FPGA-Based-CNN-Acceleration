`timescale 1ns/1ps
//OUT OF DATE, CHANGED RTL AFTER USING THIS
module tb_conv_engine;

reg clk;
reg signed [431:0] pixel_bus;
reg [1:0] filter_batch;

wire signed [37:0] result;

conv_engine dut(
    .clk(clk),
    .pixel_bus(pixel_bus),
    .filter_batch(filter_batch),
    .result(result)
);

initial clk = 0;
always #5 clk = ~clk;

integer i,j;
integer test_count = 0;
integer error_count = 0;

reg signed [15:0] pixel [0:26];
reg signed [37:0] golden;

reg signed [37:0] queue [0:8];
reg [1:0] fb_queue [0:8];


initial begin

    pixel_bus = 0;
    filter_batch = 0;

    for(i=0;i<9;i=i+1) begin
        queue[i] = 0;
        fb_queue[i] = 0;
    end

    repeat(200) begin
        @(negedge clk);

        for(i=0;i<27;i=i+1)
            pixel_bus[i*16 +: 16] = $random % 50;

        filter_batch = $urandom % 4;
    end

end


function signed [37:0] conv_sum;
    input [1:0] fb;
    integer k;
    reg signed [31:0] prod;
    reg signed [37:0] acc;
begin

    acc = 0;

    for(k=0;k<27;k=k+1) begin

        pixel[k] = pixel_bus[k*16 +: 16];

        case(fb)
            2'd0: prod = pixel[k];
            2'd1: prod = pixel[k]*2;
            2'd2: prod = -pixel[k];
            2'd3: prod = pixel[k];
        endcase

        acc = acc + prod;

    end

    conv_sum = acc;

end
endfunction


always @(posedge clk) begin

    for(i=8;i>0;i=i-1) begin
        queue[i] <= queue[i-1];
        fb_queue[i] <= fb_queue[i-1];
    end

    queue[0] <= conv_sum(filter_batch);
    fb_queue[0] <= filter_batch;

end

always @(posedge clk) begin

    test_count = test_count + 1;

    if(test_count > 9) begin

        golden = queue[8];

        if(fb_queue[8] == 3)
            golden = golden + 100;

        if(golden < 0)
            golden = 0;

        if(result !== golden) begin
            $display("ERROR cycle %0d",test_count);
            $display("Expected %0d  Got %0d",golden,result);
            error_count = error_count + 1;
        end

    end

end

//////////////////////////////////////////////////

initial begin

    #5000;

    $display("================================");
    $display("Tests  : %0d",test_count);
    $display("Errors : %0d",error_count);

    if(error_count==0)
        $display("PASS");
    else
        $display("FAIL");

    $finish;

end

endmodule