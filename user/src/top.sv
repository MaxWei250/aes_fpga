module top (
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,

    input  wire                         key_in1                    ,
    input  wire                         key_in2                    ,

    input  wire                         rx                         ,

    output wire                         tx                         ,
    output wire                         decode_done                ,
    output wire                         key_ready                   
);

wire                                    key_flag_cipher,key_flag_plain;

key_filter #(
    .CNT_MAX                           (20'd999_999               ) 
)
u_key_filter(
	//ports
    .sys_clk                           (clk                       ),
    .sys_rst_n                         (rst_n                     ),
    .key_in                            (key_in1                   ),
    .key_flag                          (key_flag_cipher           ) 
);
key_filter #(
    .CNT_MAX                           (20'd999_999               ) 
)
u_key_filter2(
	//ports
    .sys_clk                           (clk                       ),
    .sys_rst_n                         (rst_n                     ),
    .key_in                            (key_in2                   ),
    .key_flag                          (key_flag_plain            ) 
);

uart_aes_packed #(
    .UART_BPS                          ('d115200                  ),
    .CLK_FREQ                          ('d50_000_000              ) 
    )
u_uart_aes_packed(
	//ports
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .cipher_key                        (key_flag_cipher           ),
    .plain_key                         (key_flag_plain            ),
    .rx                                (rx                        ),
    .tx                                (tx                        ),
    .decode_done                       (decode_done               ),
    .key_ready                         (key_ready                 ) 
);

endmodule //top