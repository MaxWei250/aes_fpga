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
    output wire [127:0] cipher
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
reg sbox_flag;
reg [127:0] temp_sbox;
reg [127:0] mix_col_data;
reg mix_col_en;
reg mix_cnt ;
// endregion:logic define

// region:************assign************

// endregion:assign

// region:************always************

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
            if (round == (round_num + 1)) begin
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
                        round <= round + 1;
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

function ShifeRows(input  [127:0] data);
    reg [31:0] w [4];
    w[0] = data[127:96];
    w[1] = {data[87:64],data[95:88]};// 3 0 1 2
    w[2] = {data[47:32],data[63:48]};// 2 3 0 1
    w[3] = {data[7:0],data[31:8]};// 1 2 3 0
    ShifeRows = {w[0],w[1],w[2],w[3]};// 0 1 2 3
endfunction:ShifeRows

// endregion:function

endmodule //aes_encipher