`default_nettype none
    
module aes_encipher (
    input  wire clk,
    input  wire rst,

    input  wire next,
    input  wire [3:0] round_num,
    input  wire key_ready,

    input  wire [127:0] round_key,
    output wire [3:0] round,

    output wire [127:0] cipher
);
localparam AES_128_N_ROUND = 10;
localparam AES_192_N_ROUND = 12;
localparam AES_256_N_ROUND = 14;
endmodule //aes_encipher