`timescale 1ns / 1ns
module tb_key_expansion ();

wire [127:0]	round_key;
wire 	key_ready;
reg clk;
reg rst_n;
reg init;
initial begin
    clk    = 1'b0;
    rst_n <= 1'b0;
    #30
    rst_n <= 1'b1;
end
always #5 clk=~clk;
wire [1:0] keylen = 2;
wire [255:0] key_in = {128'h01_02_03_04_05_06_07_08_09_10_11_12_13_14_15_16,64'h00_01_02_03_04_05_06_07,64'd0};
always @(posedge clk) begin
    if(!rst_n) begin
        init <= 0;
    end
    else begin
        init <= 1;
    end
end
aes_key_expasion u_aes_key_expasion(
	//ports
	.clk       		( clk       		),
	.rst       		( !rst_n       		),
	.key_in    		( key_in    		),
	.keylen    		( keylen    		),
	.init      		( init      		),
	.round     		( /* round */     	),
	.round_key 		( round_key 		),
	.key_ready 		( key_ready 		)
);

endmodule //tb_key_expansion