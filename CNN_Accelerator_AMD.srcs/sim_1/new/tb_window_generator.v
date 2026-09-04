`timescale 1ns/1ps

module tb_window_generator;

parameter IMG_W = 5;
parameter IMG_H = 5;
parameter NUM_FRAMES = 4;

reg clk;
reg ready;
reg [15:0] pix_r0;

wire [15:0] w0,w1,w2,w3,w4,w5,w6,w7,w8;
wire window_valid;

window_generator #(.IMG_W(IMG_W)) DUT (
    .clk(clk),
    .ready(ready),
    .pix_r0(pix_r0),
    .w0(w0), .w1(w1), .w2(w2),
    .w3(w3), .w4(w4), .w5(w5),
    .w6(w6), .w7(w7), .w8(w8),
    .window_valid(window_valid)
);


initial clk = 0;
always #5 clk = ~clk;


task send_frame;
    integer r,c;
    integer val;
begin
    val = 1;  

    for(r=0; r<IMG_H; r=r+1)
    begin
        for(c=0; c<IMG_W; c=c+1)
        begin
           
            if(r==0 && c==0) begin end
            else begin
                @(negedge clk);
                pix_r0 = val;
                val = val + 1;
            end
        end
    end
end
endtask


integer i;

initial begin
    pix_r0 = 0;
    ready = 0;

    repeat(5) @(posedge clk);

    for(i=0; i<NUM_FRAMES; i=i+1)
    begin
        ready = 0;
        pix_r0 = 0;
        repeat(5) @(posedge clk);

        @(negedge clk);
        pix_r0 = 0;

        ready = 1;

        send_frame();
        repeat(2) @(posedge clk);
    end

    repeat(20) @(posedge clk);
    $finish;
end


always @(posedge clk)
begin
    if(window_valid)
    begin
        $display("\nWindow:");
        $display("%4d %4d %4d", w0,w1,w2);
        $display("%4d %4d %4d", w3,w4,w5);
        $display("%4d %4d %4d", w6,w7,w8);
    end
end

endmodule