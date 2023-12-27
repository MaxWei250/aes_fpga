`timescale 1ns / 1ns
module tb_aes_core ();
reg clk;
reg rst_n;
reg next;
reg key_ready_r;
reg key_ready_rise;
initial begin
    clk    = 1'b0;
    rst_n <= 1'b0;
    next  <= 0;
    #30
    rst_n <= 1'b1;
    #50
    next <= 1'b1;
    #10
    next <= 1'b0;
end
always #5 clk=~clk;


wire                                    key_ready                  ;
wire                                    cipher_ready               ;
wire                   [ 127:0]         plain                      ;
wire error;
always @(posedge clk) begin
    if (~rst_n) begin
        key_ready_r <= 0;
        key_ready_rise <= 0;
    end
    else begin
        key_ready_r <= key_ready;
        key_ready_rise <= key_ready & ~key_ready_r;
    end
end

aes_core u_aes_core(
	//ports
	.clk         		( clk         		),
	.rst_n       		( rst_n       		),
	.init        		( next        		),
	.key_in      		( {128'h01020304050607080910111213141516,64'h0001020304050607,64'h0001020304050607}      		),
	.keylen      		( 2      		),
    .key_ready(key_ready),
	.init_plain  		( 128'h01020304050607080910111aef98  		),
	.next        		( key_ready_rise        		),
	.plain       		( plain       		),
	.decode_done 		( cipher_ready 		),
	.error       		( error       		)
);

endmodule //tb_aes_encipher