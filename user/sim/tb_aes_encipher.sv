`timescale 1ns / 1ns
module tb_aes_encipher ();
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

wire                   [   3:0]         round                      ;
wire                   [ 127:0]         cipher                     ;

wire                   [ 127:0]         round_key                  ;
wire                                    key_ready                  ;
wire                   [   3:0]         round_num                  ;
wire                                    cipher_ready               ;
wire                   [   3:0]         de_round                   ;
wire                   [ 127:0]         plain                      ;

wire [3:0] temp_round = (cipher_ready) ? de_round : round;
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

aes_key_expasion u_aes_key_expasion(
	//ports
    .clk                               (clk                       ),
    .rst                               (~rst_n                    ),
    .key_in                            ({128'h01020304050607080910111213141516,128'd0}),
    .keylen                            (0                         ),
    .init                              (next                      ),
    .round                             (temp_round                     ),
    .round_key                         (round_key                 ),
    .key_ready                         (key_ready                 ),
    .round_num                         (round_num                 ) 
);

aes_encipher u_aes_encipher(
	//ports
    .clk                               (clk                       ),
    .rst                               (~rst_n                    ),
    .next                              (key_ready_rise            ),
    .round_num                         (round_num                 ),
    .key_ready                         (key_ready                 ),
    .round_key                         (round_key                 ),
    .round                             (round                     ),
    .plain                             (128'h01020304050607080910111213141516),
    .cipher                            (cipher                    ),
    .cipher_ready                      (cipher_ready              ) 
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
    .plain                             (plain                     ) 
);

endmodule //tb_aes_encipher