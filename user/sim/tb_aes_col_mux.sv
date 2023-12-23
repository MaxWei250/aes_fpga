`timescale 1ns / 1ns
module tb_aes_col_mux ();
reg clk;
reg rst_n;
reg col_mix_en;
initial begin
    clk    = 1'b0;
    rst_n <= 1'b0;
    #30
    rst_n <= 1'b1;
    #100 
col_mix_en = 1;
#10
col_mix_en = 0;
end
always #5 clk=~clk;
wire [127:0]	out;

/* aes_col_mux u_aes_col_mux(
	//ports
	.clk        		( clk        		),
	.rst        		( ~rst_n        		),
	.in         		(128'hd4bf5d30050607080910111213141516),
	.col_mix_en 		( col_mix_en 		),
	.out        		(         		)
); */

aes_inv_col_mix u_aes_col_mux(
	//ports
	.clk        		( clk        		),
	.rst        		( ~rst_n        		),
	.in         		(128'hd01020304050607080910111213141516),
	.col_mix_en 		( col_mix_en 		),
	.out        		(         		)
);
endmodule //tb_aes_col_mux