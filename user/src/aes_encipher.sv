`default_nettype none
    
module aes_encipher (
    input  wire clk,
    input  wire rst,

    input  wire next,
    input  wire [3:0] round_num,
    input  wire key_ready,

    input  wire [127:0] round_key,
    output reg  [3:0]   round,

    input  wire [127:0] plain,
    output reg [127:0] cipher,
    output reg cipher_ready,

    output wire error       //*密钥未生成，收到了加密信号
);
// region:************parameter************
localparam AES_128_N_ROUND = 10;
localparam AES_192_N_ROUND = 12;
localparam AES_256_N_ROUND = 14;

localparam IDLE = 0,INIT_TRANS = 1,ROUND_LOOP = 2,END_ROUND = 3,DONE = 4;
// endregion:parameter

// region:************logic define************
wire work_en = next & key_ready;
wire                   [ 127:0]         temp_sbox_out              ;
wire                   [ 127:0]         mix_col_out                ;
wire                                    mix_col_flag               ;

reg [2:0] cur_state,next_state;
reg [127:0] temp_encipher;
reg [3:0] cnt_round;
reg [127:0] temp_sbox;
reg [127:0] mix_col_data;
reg mix_col_en;
reg mix_cnt ;
// endregion:logic define

// region:************assign************
assign error = (!key_ready) & next;
// endregion:assign

// region:************always************
always @(posedge clk ) begin
    if (rst) begin
        cipher <= 128'd0;
        cipher_ready <= 1'b0;
    end
    else if(next_state == DONE) begin
        cipher <= temp_encipher;
        cipher_ready <= 1'b1;
    end
    else if(work_en)begin
        cipher <= 128'd0;
        cipher_ready <= 1'b0;
    end
end
// endregion:always

// region:************state machine************

//*1
always @(posedge clk) begin
    if (rst) begin
        cur_state <= IDLE;
    end
    else begin
        cur_state <= next_state;    
    end
end
//*2 
always@(*)begin
    case (cur_state)
        IDLE:begin
            if (work_en) begin
                next_state <= INIT_TRANS;
            end
            else begin
                next_state <= IDLE;
            end
        end
        INIT_TRANS:begin
            if(round == 1) begin
                next_state <= ROUND_LOOP;
            end
            else begin
                next_state <= INIT_TRANS;
            end
        end
        ROUND_LOOP:begin
            if(round == round_num) begin
                next_state <= END_ROUND;
            end
            else begin
                next_state <= ROUND_LOOP;
            end
        end
        END_ROUND:begin
            if (round == (0)) begin
                next_state <= DONE;
            end
            else begin
                next_state <= END_ROUND;
            end
        end
        DONE:begin
            next_state <= IDLE;
        end
        default: next_state <= IDLE;
    endcase
end
//*3
always @(posedge clk) begin
    if (rst) begin
        temp_encipher <= 128'd0;
        round <= 4'd0;
        cnt_round <= 4'd0;
        temp_sbox <= 128'd0;
        mix_col_data <= 128'd0;
        mix_col_en   <= 1'd0;
        mix_cnt <= 1'b0;
    end
    else begin
        case (next_state)
            IDLE:begin
                temp_encipher <= 128'd0;
                round <= 4'd0;
                cnt_round <= 4'd0;
                temp_sbox <= 128'd0;
                mix_col_data <= 128'd0;
                mix_col_en   <= 1'd0;
                mix_cnt <= 1'b0;
            end
            INIT_TRANS:begin
                round <= round + 1;
                cnt_round <= 4'd0;
                temp_encipher <= addroundkey(round_key,plain);
            end
            ROUND_LOOP:begin
                case (cnt_round)
                    0: begin
                        temp_sbox <= temp_encipher;
                        cnt_round <= cnt_round + 1;
                    end
                    1: begin
                        temp_encipher <= ShifeRows(temp_sbox_out);
                        cnt_round <= cnt_round + 1;
                    end 
                    2: begin
                        if(mix_cnt == 0) begin
                            mix_col_data <= temp_encipher;
                            mix_col_en   <= 1'b1;
                            mix_cnt <= 1'b1;
                        end
                        else if(mix_col_flag) begin
                            temp_encipher <= mix_col_out;
                            cnt_round <= cnt_round + 1;
                            mix_cnt <= 1'b0;
                        end
                        else if(mix_cnt == 1) begin
                            mix_col_data <= 0;
                            mix_col_en   <= 1'b0;
                            mix_cnt      <= 1'b1;
                        end
                    end
                    3: begin
                        cnt_round <= 3'd0;
                        round <= round + 1;
                        temp_encipher <= addroundkey(round_key,temp_encipher);
                    end
                endcase
            end
            END_ROUND:begin
                case (cnt_round)
                    0: begin
                        temp_sbox <= temp_encipher;
                        cnt_round <= cnt_round + 1;
                    end
                    1: begin
                        temp_encipher <= ShifeRows(temp_sbox_out);
                        cnt_round <= cnt_round + 1;
                    end 
                    2: begin
                        cnt_round <= 3'd0;
                        round <= 0;
                        temp_encipher <= addroundkey(round_key,temp_encipher);
                    end
                endcase
            end
            DONE:begin
                temp_encipher <= 128'd0;
                round <= 4'd0;
                cnt_round <= 4'd0;
                temp_sbox <= 128'd0;
                mix_col_data <= 128'd0;
                mix_col_en   <= 1'd0;
                mix_cnt <= 1'b0;
            end
            default: begin
                temp_encipher <= 128'd0;
                round <= 4'd0;
                cnt_round <= 4'd0;
                temp_sbox <= 128'd0;
                mix_col_data <= 128'd0;
                mix_col_en   <= 1'd0;
                mix_cnt <= 1'b0;
            end
        endcase
    end
end
// endregion:state machine

// region:************instantiate************

aes_sbox_128 u_aes_sbox_128(
	//ports
    .data_in                           (temp_sbox                 ),
    .data_out                          (temp_sbox_out             ) 
);


aes_col_mux u_aes_col_mux(
	//ports
    .clk                               (clk                       ),
    .rst                               (rst                       ),
    .in                                (mix_col_data              ),
    .col_mix_en                        (mix_col_en                ),
    .out                               (mix_col_out               ),
    .out_flag                          (mix_col_flag              ) 
);

// endregion:instantiate

// region:************function************
function [127 : 0] addroundkey(input [127 : 0] data, input [127 : 0] rkey);
    addroundkey = data ^ rkey;
endfunction:addroundkey

function [127:0] ShifeRows(input  [127:0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
        w0 = data[127 : 096];
        w1 = data[095 : 064];
        w2 = data[063 : 032];
        w3 = data[031 : 000];

        ws0 = {w0[31 : 24], w1[23 : 16], w2[15 : 08], w3[07 : 00]};
        ws1 = {w1[31 : 24], w2[23 : 16], w3[15 : 08], w0[07 : 00]};
        ws2 = {w2[31 : 24], w3[23 : 16], w0[15 : 08], w1[07 : 00]};
        ws3 = {w3[31 : 24], w0[23 : 16], w1[15 : 08], w2[07 : 00]};
    ShifeRows = {ws0,ws1,ws2,ws3};// 0 1 2 3
endfunction:ShifeRows
// endregion:function

endmodule //aes_encipher