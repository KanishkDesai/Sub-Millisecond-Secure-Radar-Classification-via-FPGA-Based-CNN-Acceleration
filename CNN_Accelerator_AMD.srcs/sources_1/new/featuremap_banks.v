
/*`timescale 1ns / 1ps

module featuremap_banks(
    input wire clk,

    input wire we,
    input wire [1:0] filter_batch,
    input wire [9:0] addr,
    input wire signed [303:0] in_bus,

    input wire [4:0] rd_channel,
    input wire [9:0] rd_pixel,

    output wire signed [15:0] rd_data
);
reg signed [37:0] bank [0:31][0:530];

initial begin : INIT_MEM
    integer i,j;
    for(i=0;i<32;i=i+1)
    for(j=0;j<531;j=j+1)
        bank[i][j] = 0;
end

integer i;

always @(posedge clk)
begin
    if(we)
    begin
        for(i=0;i<8;i=i+1)
        begin
            bank[filter_batch*8 + i][addr] <= in_bus[i*38 +: 16];
        end
    end
end

assign rd_data = bank[rd_channel][rd_pixel];

endmodule
THIS CODE DOES NOT INFER BRAM AND JUST EXPLODES REGISTER USAGE TO LAKHS
*/
`timescale 1ns / 1ps

module featuremap_banks
(
    input wire clk,


    input wire we,
    input wire [1:0] filter_batch,
    input wire [9:0] addr,
    input wire signed [303:0] in_bus,

    input wire [4:0] rd_channel,
    input wire [9:0] rd_pixel,

    output reg signed [15:0] rd_data
);


localparam CHANNELS = 32;
localparam DEPTH = 531;

//forcing brammmm
(* ram_style = "block" *)
reg signed [15:0] bank0  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank1  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank2  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank3  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank4  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank5  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank6  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank7  [0:DEPTH-1];

(* ram_style = "block" *)
reg signed [15:0] bank8  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank9  [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank10 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank11 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank12 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank13 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank14 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank15 [0:DEPTH-1];

(* ram_style = "block" *)
reg signed [15:0] bank16 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank17 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank18 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank19 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank20 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank21 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank22 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank23 [0:DEPTH-1];

(* ram_style = "block" *)
reg signed [15:0] bank24 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank25 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank26 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank27 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank28 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank29 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank30 [0:DEPTH-1];
(* ram_style = "block" *)
reg signed [15:0] bank31 [0:DEPTH-1];

////////////////////////////////////////////////////////////
// WRITE LOGIC
////////////////////////////////////////////////////////////
initial rd_data = 0;
always @(posedge clk)

begin
    if(we)
    begin
        case(filter_batch)

        2'd0:
        begin
            bank0[addr] <= in_bus[0*38 +: 16];
            bank1[addr] <= in_bus[1*38 +: 16];
            bank2[addr] <= in_bus[2*38 +: 16];
            bank3[addr] <= in_bus[3*38 +: 16];
            bank4[addr] <= in_bus[4*38 +: 16];
            bank5[addr] <= in_bus[5*38 +: 16];
            bank6[addr] <= in_bus[6*38 +: 16];
            bank7[addr] <= in_bus[7*38 +: 16];
        end

        2'd1:
        begin
            bank8[addr]  <= in_bus[0*38 +: 16];
            bank9[addr]  <= in_bus[1*38 +: 16];
            bank10[addr] <= in_bus[2*38 +: 16];
            bank11[addr] <= in_bus[3*38 +: 16];
            bank12[addr] <= in_bus[4*38 +: 16];
            bank13[addr] <= in_bus[5*38 +: 16];
            bank14[addr] <= in_bus[6*38 +: 16];
            bank15[addr] <= in_bus[7*38 +: 16];
        end

        2'd2:
        begin
            bank16[addr] <= in_bus[0*38 +: 16];
            bank17[addr] <= in_bus[1*38 +: 16];
            bank18[addr] <= in_bus[2*38 +: 16];
            bank19[addr] <= in_bus[3*38 +: 16];
            bank20[addr] <= in_bus[4*38 +: 16];
            bank21[addr] <= in_bus[5*38 +: 16];
            bank22[addr] <= in_bus[6*38 +: 16];
            bank23[addr] <= in_bus[7*38 +: 16];
        end

        2'd3:
        begin
            bank24[addr] <= in_bus[0*38 +: 16];
            bank25[addr] <= in_bus[1*38 +: 16];
            bank26[addr] <= in_bus[2*38 +: 16];
            bank27[addr] <= in_bus[3*38 +: 16];
            bank28[addr] <= in_bus[4*38 +: 16];
            bank29[addr] <= in_bus[5*38 +: 16];
            bank30[addr] <= in_bus[6*38 +: 16];
            bank31[addr] <= in_bus[7*38 +: 16];
        end

        endcase
    end
end

////////////////////////////////////////////////////////////
// READ LOGIC
////////////////////////////////////////////////////////////

always @(posedge clk)
begin
    case(rd_channel)

    0:  rd_data <= bank0 [rd_pixel];
    1:  rd_data <= bank1 [rd_pixel];
    2:  rd_data <= bank2 [rd_pixel];
    3:  rd_data <= bank3 [rd_pixel];
    4:  rd_data <= bank4 [rd_pixel];
    5:  rd_data <= bank5 [rd_pixel];
    6:  rd_data <= bank6 [rd_pixel];
    7:  rd_data <= bank7 [rd_pixel];

    8:  rd_data <= bank8 [rd_pixel];
    9:  rd_data <= bank9 [rd_pixel];
    10: rd_data <= bank10[rd_pixel];
    11: rd_data <= bank11[rd_pixel];
    12: rd_data <= bank12[rd_pixel];
    13: rd_data <= bank13[rd_pixel];
    14: rd_data <= bank14[rd_pixel];
    15: rd_data <= bank15[rd_pixel];

    16: rd_data <= bank16[rd_pixel];
    17: rd_data <= bank17[rd_pixel];
    18: rd_data <= bank18[rd_pixel];
    19: rd_data <= bank19[rd_pixel];
    20: rd_data <= bank20[rd_pixel];
    21: rd_data <= bank21[rd_pixel];
    22: rd_data <= bank22[rd_pixel];
    23: rd_data <= bank23[rd_pixel];

    24: rd_data <= bank24[rd_pixel];
    25: rd_data <= bank25[rd_pixel];
    26: rd_data <= bank26[rd_pixel];
    27: rd_data <= bank27[rd_pixel];
    28: rd_data <= bank28[rd_pixel];
    29: rd_data <= bank29[rd_pixel];
    30: rd_data <= bank30[rd_pixel];
    31: rd_data <= bank31[rd_pixel];
    default: rd_data<=0;
    endcase
end

endmodule