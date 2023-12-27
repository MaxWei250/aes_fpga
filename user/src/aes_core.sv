`default_nettype none
module aes_core (
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,

    input  wire                         init                       ,//*密钥拓展使能信号
    input  wire        [ 255:0]         key_in                     ,
    input  wire        [   1:0]         keylen                     ,

    input  wire        [ 127:0]         init_plain                 ,
    input  wire                         next                       ,

    output wire        [ 127:0]         cipher                     ,
    output wire                         cipher_ready               ,
    output wire                         key_ready                  ,
    output wire        [ 127:0]         plain                      ,
    output wire                         decode_done                ,
    output wire                         error                       //*key error
);
wire                   [ 127:0]         round_key                  ;
wire                   [   3:0]         round_num                  ;

wire                   [   3:0]         de_round                   ;

wire                   [   3:0]         round                      ;



wire [3:0] temp_round = (cipher_ready) ? de_round : round;

aes_key_expasion u_aes_key_expasion(
	//ports
    .clk                               (clk                       ),
    .rst                               (~rst_n                    ),
    .key_in                            (key_in                    ),
    .keylen                            (keylen                    ),
    .init                              (init                      ),
    .round                             (temp_round                ),
    .round_key                         (round_key                 ),
    .key_ready                         (key_ready                 ),
    .round_num                         (round_num                 ) 
);




aes_encipher u_aes_encipher(
	//ports
    .clk                               (clk                       ),
    .rst                               (~rst_n                    ),
    .next                              (next                      ),
    .round_num                         (round_num                 ),
    .key_ready                         (key_ready                 ),
    .round_key                         (round_key                 ),
    .round                             (round                     ),
    .plain                             (init_plain                ),
    .cipher                            (cipher                    ),
    .cipher_ready                      (cipher_ready              ),
    .error                             (error                     ) 
);


aes_decipher u_aes_decipher(
	//ports
    .clk                               (clk                       ),
    .rst                               (~rst_n                    ),
    .round_num                         (round_num                 ),
    .cipher_ready                      (cipher_ready              ),
    .round_key                         (round_key                 ),
    .de_round                          (de_round                  ),
    .cipher                            (cipher                    ),
    .plain                             (plain                     ),
    .plain_ready                       (decode_done               ) 
);


endmodule //aes_core