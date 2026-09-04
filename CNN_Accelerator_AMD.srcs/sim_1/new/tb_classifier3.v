`timescale 1ns / 1ps

module tb_classifier3;

reg clk;
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

reg start;
reg signed [1023:0] feature_bus;

wire [1:0] class_out;
wire done;

classifier3 DUT(
    .clk(clk),
    .start(start),
    .feature_bus(feature_bus),
    .class_out(class_out),
    .done(done)
);

integer i;

initial begin
    start = 0;
    feature_bus = 0;

    #20;
    
    $display("\n==== WEIGHTS CHECK ====");

    for(i = 0; i < 10; i = i + 1) begin
        $display("i=%0d w0=%0d w1=%0d w2=%0d",
            i,
            DUT.weight0[i],
            DUT.weight1[i],
            DUT.weight2[i]
        );
    end

    $display("\n==== BIAS ====");
    $display("b0=%0d b1=%0d b2=%0d",
        DUT.bias[0], DUT.bias[1], DUT.bias[2]);

    // pattern: increasing numbers (easy to debug)
    for(i = 0; i < 64; i = i + 1) begin
        feature_bus[i*16 +:16] = i * 100;
    end

    #20;
    start = 1;
    #10;
    start = 0;


    wait(done);

    #10;

    $display("\n==== FINAL LOGITS ====");
    $display("z0 = %0d", DUT.z0);
    $display("z1 = %0d", DUT.z1);
    $display("z2 = %0d", DUT.z2);

    $display("\nCLASS = %0d", class_out);

    $finish;
end


always @(posedge clk) begin
    if(DUT.running && DUT.idx < 5) begin
        $display("idx=%0d f=%0d w0=%0d p0=%0d acc0=%0d",
            DUT.idx,
            DUT.feature_reg[DUT.idx],
            DUT.weight0[DUT.idx],
            DUT.p0,
            DUT.acc0
        );
    end
end

endmodule