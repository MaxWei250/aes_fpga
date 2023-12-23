module aes_sbox_128 (
    input  wire [127:0] data_in,

    output wire [127:0] data_out
);

aes_sbox u_0(
	//ports
    .sboxw        (data_in[31:0]             ),
    .new_sboxw    (data_out[31:0]            ) 
);
aes_sbox u_1(
	//ports
    .sboxw        (data_in[63:32]            ),
    .new_sboxw    (data_out[63:32]           ) 
);
aes_sbox u_2(
	//ports
    .sboxw        (data_in[95:64]            ),
    .new_sboxw    (data_out[95:64]           ) 
);
aes_sbox u_3(
	//ports
    .sboxw        (data_in[127:96]           ),
    .new_sboxw    (data_out[127:96]          ) 
);
endmodule //aes_sbox_128