`timescale 1ns / 1ns

module tb_s_box ();
reg  [7:0] in;
wire [7:0] out;

initial begin
    in = 8'h0;
    #30
    in = 8'h01;
    #50
    in = 8'h02;
    #50
    in = 8'h31; 
    #50
    in = 8'h32;
end

s_box u_s_box(
    .in  (in  ),
    .out (out )
);


endmodule //tb_s_box