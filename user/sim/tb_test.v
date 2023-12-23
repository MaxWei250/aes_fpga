`timescale 1ns / 1ns
module tb_test (
    
);
reg clk;
reg rst_n;
reg [7:0] addr;
reg en=0;
initial begin
    clk    = 1'b0;
    rst_n <= 1'b0;
    addr <= 0;
    en = 0;
    #30
    rst_n <= 1'b1;
    #30
    addr <= 2;
    #10
    en <= 1;
    #20
    en <= 0;
    #50 
    addr <= 16;
    en <= 1;
    #20
    en <= 0;
    #50
    addr <= 32;
    en <= 1;
    #20
    en <= 0;
    #50
    addr <= 48;
    en <= 1;
    #20
    en <= 0;
    #50
    addr <= 64;
    en <= 1;
    #20
    en <= 0;
end
always #5 clk=~clk;

wire [7:0]	douta;
wire [7:0]	doutb;

mul_02_bram your_instance_name (
    .clka                              (clk                       ),// input wire clka
    .ena                               (en                       ),// input wire ena
    .addra                             (addr                     ),// input wire [7 : 0] addra
    .douta                             (douta                     ),// output wire [7 : 0] douta
    .clkb                              (                    ),// input wire clkb
    .enb                               (                    ),// input wire enb
    .addrb                             (                    ),// input wire [7 : 0] addrb
    .doutb                             (                    ) // output wire [7 : 0] doutb
);

endmodule //tb_test