`timescale 1ns / 1ns
module tb_uart_packed (
    
);
localparam NUM_BYTE = 69;
reg clk;
reg rst_n;
initial begin
    clk    = 1'b0;
    rst_n <= 1'b0;
    #30
    rst_n <= 1'b1;
end
always #10 clk=~clk;
    
wire 	tx;
wire tx_end;
reg first_flag;
reg [7:0] pi_data;
reg  pi_flag;
reg cipher_key;
reg plain_key ;
reg [NUM_BYTE*8-1:0] key_buff ;

initial begin
    cipher_key = 0;
    plain_key = 0;
    #5000000 
    cipher_key = 1'b1;
    #20
    cipher_key = 1'b0;
    #3000000 
    plain_key = 1'b1;
    #20
    plain_key = 1'b0;
end
//*generate input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pi_data <= 8'd0;
        pi_flag <= 1'd0;
        first_flag <= 1'b0;
        key_buff <= {"keyahsojeneskxishebaplainsidhaodwiohaaaaakeyb123456789abcdefghthsgdsj"} ;
    end
    else if(first_flag == 0) begin
        pi_data <= key_buff[NUM_BYTE*8-1:NUM_BYTE*8-8];
        pi_flag <= 1'd1;
        first_flag <= ~first_flag;
        key_buff<= key_buff << 8;
    end
    else if(tx_end&& (pi_data!=0)  )begin
        pi_data <= key_buff[NUM_BYTE*8-1:NUM_BYTE*8-8];
        pi_flag <= 1'd1;
        key_buff<= key_buff << 8;
    end
    else begin
        pi_data <= pi_data;
        pi_flag <= 1'b0;
    end
end

uart_tx #(
	.UART_BPS 		( 'd115200      		),
	.CLK_FREQ 		( 'd50_000_000 		))
u_uart_tx(
	//ports
	.sys_clk   		( clk   		),
	.sys_rst_n 		( rst_n 		),
	.pi_data   		( pi_data   		),
	.pi_flag   		( pi_flag   		),
	.tx        		( tx        		),
    .tx_end (tx_end)
);
//*endgenerate

uart_aes_packed #(
	.UART_BPS 		( 'd115200       		),
	.CLK_FREQ 		( 'd50_000_000 		))
u_uart_aes_packed(
	//ports
	.clk   		( clk   		),
	.rst_n 		( rst_n 		),
    .cipher_key (cipher_key),
    .plain_key  (plain_key ),
	.rx    		( tx    		),
	.tx    		(     		)
);

endmodule //tb_uart_packed