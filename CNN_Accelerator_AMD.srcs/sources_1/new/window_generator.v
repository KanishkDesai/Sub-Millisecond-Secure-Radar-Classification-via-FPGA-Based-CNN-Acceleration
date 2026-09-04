`timescale 1ns/1ps

module window_generator
#(
parameter IMG_W = 61
)
(
input  wire        clk,
input  wire        ready,   
input  wire [15:0] pix_r0,

output wire [15:0] w0,w1,w2,
output wire [15:0] w3,w4,w5,
output wire [15:0] w6,w7,w8,

output reg window_valid
);

////////////////////////////////////////////////////////////
// line buffers for temp storage to make window
////////////////////////////////////////////////////////////

reg [15:0] lb1 [0:IMG_W-1];
reg [15:0] lb2 [0:IMG_W-1];

reg [15:0] row = 0;
reg [15:0] col = 0;

////////////////////////////////////////////////////////////
// the windowwwww
////////////////////////////////////////////////////////////

reg [15:0] r0c0=0,r0c1=0,r0c2=0;
reg [15:0] r1c0=0,r1c1=0,r1c2=0;
reg [15:0] r2c0=0,r2c1=0,r2c2=0;

wire [15:0] pix_row0 = pix_r0;
wire [15:0] pix_row1 = lb1[col];
wire [15:0] pix_row2 = lb2[col];

always @(posedge clk)
begin
    if(ready) begin
        lb2[col] <= lb1[col];
        lb1[col] <= pix_r0;
    end
end

always @(posedge clk)
begin
    if(!ready) begin
        r0c0<=0; r0c1<=0; r0c2<=0;
        r1c0<=0; r1c1<=0; r1c2<=0;
        r2c0<=0; r2c1<=0; r2c2<=0;
    end
    else begin
        r0c0 <= r0c1;
        r0c1 <= r0c2;
        r0c2 <= pix_row0;

        r1c0 <= r1c1;
        r1c1 <= r1c2;
        r1c2 <= pix_row1;

        r2c0 <= r2c1;
        r2c1 <= r2c2;
        r2c2 <= pix_row2;
    end
end

always @(posedge clk)
begin
    if(!ready) begin
        row <= 0;
        col <= 0;
    end
    else begin
        if(col == IMG_W-1)
        begin
            col <= 0;
            row <= row + 1;
        end
        else
            col <= col + 1;
    end
end

always @(posedge clk)
begin
    if(!ready)
        window_valid <= 0;
    else if(row >= 2 && col >= 2)
        window_valid <= 1;
    else
        window_valid <= 0;
end


assign w0 = r2c0;
assign w1 = r2c1;
assign w2 = r2c2;

assign w3 = r1c0;
assign w4 = r1c1;
assign w5 = r1c2;

assign w6 = r0c0;
assign w7 = r0c1;
assign w8 = r0c2;

endmodule