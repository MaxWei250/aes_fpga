`default_nettype none
module uart_aes_packed 
#(
    parameter   UART_BPS    =   'd115200,         //串口波特率
    parameter   CLK_FREQ    =   'd50_000_000    //时钟频率
)
(
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,

    input  wire                         cipher_key                 ,
    input  wire                         plain_key                  ,
    input  wire                         rx                         ,

    output wire                         tx                         ,
    output wire                         decode_done                ,
	output wire 						key_ready
);
// region:************parameter************
localparam AES_128_N_KEY = 128/8;
localparam AES_192_N_KEY = 192/8;
localparam AES_256_N_KEY = 256/8;
// endregion:parameter

// region:************my_type************

// endregion:my_type

// region:************logic define************
wire [7:0]	po_data;
wire 		po_flag;
wire 		init;
wire 		next;
wire [127:0] plain;
wire 		error;
wire [127:0] cipher;
wire 		cipher_ready;
wire 		tx_end;
reg [1:0] 	cnt_key;
reg [5:0] 	cnt_key_byte;
reg 		key_fileheader_success;
reg 		key_done ;
reg [1:0] 	key_mode ;
reg [5:0] 	temp_n_key;
reg [7:0] 	temp_key_in [31:0];
reg [255:0] key_in;

reg [2:0] 	cnt_plain	;
reg 		plain_fileheader_success;
reg [5:0] 	cnt_plain_byte;
reg 		plain_done  ;
reg [7:0] 	temp_plain_in [15:0];
reg [127:0] plain_in	;

reg [4:0]   tx_cnt;
reg tx_flag;
reg [7:0] tx_data;
reg tx_work_en;
reg [1:0] tx_mode;

reg key_ready_temp;
// endregion:logic define

// region:************assign************
assign init = key_done && (!key_fileheader_success);
assign next = plain_done && (!plain_fileheader_success);
assign key_ready = (key_ready_temp);
// endregion:assign

// region:************always************

//*------------------------key calculate------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		temp_n_key <= 6'd0;
	end
	else if(key_fileheader_success == 0) begin
		temp_n_key <= 6'd0;
	end
	else if(cnt_key_byte == 1) begin
		case (key_mode)
			0: temp_n_key <= AES_128_N_KEY;
			1: temp_n_key <= AES_192_N_KEY;
			2: temp_n_key <= AES_256_N_KEY;
			default:temp_n_key <= 6'd0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_key <= 2'd0;
		key_fileheader_success <= 1'b0;
		key_in <= 256'd0;
	end
	else  begin
		case (cnt_key)
			0: begin
				if(po_flag && (po_data == "k") ) begin
					cnt_key <= 2'd1;
					key_fileheader_success <= 1'b0;
				end
				else if(po_flag)begin
					cnt_key <= 0;
					key_fileheader_success <= 1'b0;
				end
			end
			1: begin
				if(po_flag && (po_data == "e")) begin
					cnt_key <= 2'd2;
					key_fileheader_success <= 1'b0;
				end
				else if(po_flag)begin
					cnt_key <= 0;
					key_fileheader_success <= 1'b0;
				end
			end
			2: begin
				if(po_flag && (po_data == "y")) begin
					cnt_key <= 2'd3;
					key_fileheader_success <= 1'b1;
				end
				else if(po_flag)begin
					cnt_key <= 2'd0;
					key_fileheader_success <= 1'b0;
				end
			end
			3: begin
				if((key_done == 1) || (key_mode == 2'd3)) begin//*3表示文件格式错误
					cnt_key <= 2'd0;
					key_fileheader_success <= 1'b0;
					key_in <= {
								temp_key_in[0] ,temp_key_in[1] ,temp_key_in[2] ,temp_key_in[3] ,
								temp_key_in[4] ,temp_key_in[5] ,temp_key_in[6] ,temp_key_in[7] ,
								temp_key_in[8] ,temp_key_in[9] ,temp_key_in[10],temp_key_in[11],
								temp_key_in[12],temp_key_in[13],temp_key_in[14],temp_key_in[15],
								temp_key_in[16],temp_key_in[17],temp_key_in[18],temp_key_in[19],
								temp_key_in[20],temp_key_in[21],temp_key_in[22],temp_key_in[23],
								temp_key_in[24],temp_key_in[25],temp_key_in[26],temp_key_in[27],
								temp_key_in[28],temp_key_in[29],temp_key_in[30],temp_key_in[31]
					};
				end
				else begin
					cnt_key <= cnt_key;
					key_fileheader_success <= key_fileheader_success;
					key_in <= 256'd0;
				end
			end
			default: begin
				cnt_key <= 0;
				key_fileheader_success <= 1'b0;
			end
		endcase
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_key_byte <= 6'd0;
		key_mode <= 2'd0;
		for(integer i = 0;i < 32;i++) begin
			temp_key_in[i] <= 8'd0;
		end
		key_done <= 1'b0;
	end
	else if(!key_fileheader_success) begin
		cnt_key_byte <= 6'd0;
		key_mode <= key_mode;
		for(integer i = 0;i < 32;i++) begin
			temp_key_in[i] <= 8'd0;
		end
		key_done <= 1'b0;
	end
	else if(key_fileheader_success && po_flag) begin
		case (cnt_key_byte)
			0: begin
				case (po_data)
					"a":begin key_mode <= 2'd0;cnt_key_byte <= cnt_key_byte + 1;end
					"b":begin key_mode <= 2'd1;cnt_key_byte <= cnt_key_byte + 1;end
					"c":begin key_mode <= 2'd2;cnt_key_byte <= cnt_key_byte + 1;end
					default:begin
						key_mode <= 2'd3;
						cnt_key_byte <= 6'd0;
					end
				endcase
				for(integer i = 0;i < 32;i++) begin
					temp_key_in[i] <= 8'd0;
				end
				key_done <= 1'b0;
			end
			1,2,3,4,5,6,7,8,
			9,10,11,12,13,14,15,16,
			17,18,19,20,21,22,23,24,
			25,26,27,28,29,30,31,32: begin
				if(cnt_key_byte == temp_n_key+1) begin
					cnt_key_byte <= 0;
					key_done <= 1;
				end
				else  begin
					cnt_key_byte <= cnt_key_byte + 1;
					temp_key_in[cnt_key_byte-1] <= po_data;
				end
			end
			default: begin
				cnt_key_byte <= 6'd0;
				key_mode <= 2'd0;
				for(integer i = 0;i < 32;i++) begin
					temp_key_in[i] <= 8'd0;
				end
				key_done <= 1'b0;
			end
		endcase
	end
end
//*------------------------endkey calculate------------------------

//*------------------------plain calculate------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_plain <= 3'd0;
		plain_fileheader_success <= 1'b0;
		plain_in <= 128'd0;
	end
	else  begin
		case (cnt_plain)
			0: begin
				if(po_flag && (po_data == "p")) begin
					cnt_plain <= 3'd1;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
				else if(po_flag)begin
					cnt_plain <= 0;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
			end
			1: begin
				if(po_flag && (po_data == "l")) begin
					cnt_plain <= 3'd2;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
				else if(po_flag)begin
					cnt_plain <= 0;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
			end
			2: begin
				if(po_flag && (po_data == "a")) begin
					cnt_plain <= 3'd3;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
				else if(po_flag)begin
					cnt_plain <= 0;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
			end
			3: begin
				if(po_flag && (po_data == "i")) begin
					cnt_plain <= 3'd4;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
				else if(po_flag)begin
					cnt_plain <= 0;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
			end
			4: begin
				if(po_flag && (po_data == "n")) begin
					cnt_plain <= 3'd5;
					plain_fileheader_success <= 1'b1;
					plain_in <= 128'd0;
				end
				else if(po_flag)begin
					cnt_plain <= 2'd0;
					plain_fileheader_success <= 1'b0;
					plain_in <= 128'd0;
				end
			end
			5: begin
				if((plain_done == 1)) begin//*3表示文件格式错误
					cnt_plain <= 2'd0;
					plain_fileheader_success <= 1'b0;
					plain_in <= {
						temp_plain_in[0] ,temp_plain_in[1] ,temp_plain_in[2] ,temp_plain_in[3] ,
						temp_plain_in[4] ,temp_plain_in[5] ,temp_plain_in[6] ,temp_plain_in[7] ,
						temp_plain_in[8] ,temp_plain_in[9] ,temp_plain_in[10],temp_plain_in[11],
						temp_plain_in[12],temp_plain_in[13],temp_plain_in[14],temp_plain_in[15]
					};
				end
				else begin
					cnt_plain <= cnt_plain;
					plain_fileheader_success <= plain_fileheader_success;
					plain_in <= 128'd0;
				end
			end
			default: begin
				cnt_plain <= 0;
				plain_fileheader_success <= 1'b0;
			end
		endcase
	end
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_plain_byte <= 6'd0;
		for(integer i = 0;i < 16;i++) begin
			temp_plain_in[i] <= 8'd0;
		end
		plain_done <= 1'b0;
	end
	else if(!plain_fileheader_success) begin
		cnt_plain_byte <= 6'd0;
		for(integer i = 0;i < 16;i++) begin
			temp_plain_in[i] <= 8'd0;
		end
		plain_done <= 1'b0;
	end
	else if(plain_fileheader_success && po_flag) begin
		if(cnt_plain_byte == 16) begin
			cnt_plain_byte <= 0;
			plain_done <= 1;
		end
		else  begin
			cnt_plain_byte <= cnt_plain_byte + 1;
			temp_plain_in[cnt_plain_byte] <= po_data;
		end
	end
end

//*------------------------endplain calculate------------------------

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		tx_cnt <= 5'd0;
		tx_flag <= 1'b0;
		tx_data <= 8'd0;
		tx_work_en <= 1'b0;
		tx_mode <= 2'd0;
	end
	else if(tx_work_en && (tx_cnt == 17)) begin
		tx_cnt <= 5'd0;
		tx_flag <= 1'b0;
		tx_data <= 8'd0;
		tx_work_en <= 1'b0;
		tx_mode <= 2'd0;
	end
	else if(tx_work_en && ((tx_cnt == 0) || (tx_end))) begin
		tx_flag <= 1'b1;
		tx_data <= (tx_mode == 1) ? (plain<<(tx_cnt*8)>>120) : cipher<<(tx_cnt*8)>>120;
		tx_cnt <= tx_cnt + 1;
	end
	else if(plain_key||cipher_key) begin
		tx_work_en <= 1'b1;
		tx_mode <= plain_key ? 2'd1 : 2'd2;//*1为明文模式，2为密文模式
	end
	else begin
		tx_flag <= 1'b0;
	end
end
// endregion:always

// region:************state machine************

// endregion:state machine

// region:************instantiate************
uart_rx #(
    .UART_BPS                          (UART_BPS                  ),
    .CLK_FREQ                          (CLK_FREQ                  ) 
    )
u_uart_rx(
	//ports
    .sys_clk                           (clk                       ),
    .sys_rst_n                         (rst_n                     ),
    .rx                                (rx                        ),
    .po_data                           (po_data                   ),
    .po_flag                           (po_flag                   ) 
);

uart_tx #(
    .UART_BPS                          (UART_BPS                  ),
    .CLK_FREQ                          (CLK_FREQ                  ) 
    )
u_uart_tx(
	//ports
    .sys_clk                           (clk                       ),
    .sys_rst_n                         (rst_n                     ),
    .pi_data                           (tx_data                   ),
    .pi_flag                           (tx_flag                   ),
    .tx                                (tx                        ),
	.tx_end (tx_end) 
);



aes_core u_aes_core(
	//ports
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .init                              (init                      ),
    .key_in                            (key_in                    ),
    .keylen                            (key_mode                  ),
    .init_plain                        (plain_in                  ),
    .next                              (next                      ),
    .key_ready                         (key_ready_temp            ),
    .plain                             (plain                     ),
    .decode_done                       (decode_done               ),
    .cipher                            (cipher                    ),
    .cipher_ready                      (cipher_ready              ),
    .error                             (error                     ) 
);

/* ila_0 uila (
    .clk                               (clk                       ),// input wire clk
    .probe0                            (key_mode                  ),// input wire [1:0]  probe0  
    .probe1                            (init                      ),// input wire [0:0]  probe1 
    .probe2                            (next                      ),// input wire [0:0]  probe2 
    .probe3                            (plain_in                  ),// input wire [127:0]  probe3 
    .probe4                            (key_in                    ),// input wire [255:0]  probe4 
    .probe5                            (plain                     ),// input wire [127:0]  probe5 
    .probe6                            (cipher                    ),// input wire [127:0]  probe6
    .probe7                            (tx_work_en                ),
    .probe8                            (tx_cnt                    ),
    .probe9                            (tx_flag                   ),
    .probe10                           (tx_data                   ),
    .probe11                           (tx                        ),
	.probe12(bit_cnt) 
); */
// endregion:instantiate
endmodule //uart_packed