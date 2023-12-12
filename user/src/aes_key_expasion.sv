`default_nettype none

module aes_key_expasion
(
    input  wire                         clk                        ,
    input  wire                         rst                        ,

    input  wire        [ 255:0]         key_in                     ,//*按有可能输入的最大值来输入(256bit)
    input  wire        [   1:0]         keylen                     ,//*0 1 2
    input  wire                         init                       ,//*indicate the initial key is ready
    
    input  wire        [   3:0]         round                      ,//*indicate the current round
    output wire        [ 127:0]         round_key                  ,//*output the round key
    output wire                         key_ready                   

);
// region:************parameter************
localparam AES_128_KEY = 2'D0;
localparam AES_192_KEY = 2'D1;
localparam AES_256_KEY = 2'D2;

localparam AES_128_N_ROUND = 10;//*if round include initialize transform, then this value should be 11
localparam AES_192_N_ROUND = 12;
localparam AES_256_N_ROUND = 14;

localparam AES_128_N_KEY = 4;
localparam AES_192_N_KEY = 6;
localparam AES_256_N_KEY = 8;

localparam IDLE = 0, INIT_KEY  = 1,ROUND_KEY = 2 ,DONE = 3;//*state machine param

// endregion:parameter

// region:************logic define************
//cnt register
reg [3:0] cnt_round;//*record the current round
reg [1:0] cnt_word ;//*record the current word of per round
reg [2:0] cnt_remain0;//*judge if the remainer  is 0
reg [3:0] cnt_round6_8;
//key register
reg key_done_flag;
reg wr_sbox_flag;
reg [127:0] key_mem [AES_256_N_ROUND+1];//include initial key
reg [127:0] key_mem_new ;
//tempraory register
reg [3:0] tem_mode_round ;
reg [127:0] tem_key0;
reg [127:0] tem_key1;
reg [31:0] tem_sbox_wr;
reg tem_ready;
reg [31:0] temp_w [4];
reg [31:0] w [8];

reg [31:0] rcon_table [10];
//control register
reg key_new_we;
//————————————————————————state register————————————————————————
reg [1:0] cur_state,next_state;

//+++++++++++++++++++++++wire+++++++++++++++++++++++
wire [1:0] AES_MODE;
wire [31:0]	new_sboxw;
wire [31:0] sbox_rd = wr_sbox_flag ? new_sboxw : 32'd0;
// endregion:logic define

// region:************initial************
initial begin
    rcon_table[0] = 32'h01000000;
    rcon_table[1] = 32'h02000000;
    rcon_table[2] = 32'h04000000;
    rcon_table[3] = 32'h08000000;
    rcon_table[4] = 32'h10000000;
    rcon_table[5] = 32'h20000000;
    rcon_table[6] = 32'h40000000;
    rcon_table[7] = 32'h80000000;
    rcon_table[8] = 32'h1b000000;
    rcon_table[9] = 32'h36000000;
end
// endregion:initial

// region:************assign************
assign AES_MODE = keylen;

//+++++++++++out assign+++++++++++
assign key_ready = tem_ready;
assign round_key = key_ready ? key_mem[round] : 0;
// endregion:assign

// region:************always************
//*****************key_expasion*****************
always @(*) begin : round_mode
    case (AES_MODE)
        AES_128_KEY: begin
            tem_mode_round = AES_128_N_ROUND;
        end
        AES_192_KEY: begin
            tem_mode_round = AES_192_N_ROUND;
        end
        AES_256_KEY: begin
            tem_mode_round = AES_256_N_ROUND;
        end
        default: begin
            tem_mode_round = AES_128_N_ROUND;
        end
    endcase
end

always @(posedge clk) begin:key_set
    if(rst) begin
        for(integer i = 0;i < (AES_256_N_ROUND+1);i++) begin
            key_mem[i] <= 128'd0;
        end
    end
    else if(key_done_flag) begin
        if(cur_state == INIT_KEY)
            key_mem[cnt_round-1] <= key_mem_new;
        else
            key_mem[cnt_round-1] <= key_mem_new;
    end
end

// endregion:always

// region:************state machine************
//1.
always @(posedge clk) begin:first_state
    if(rst) begin
        cur_state <= IDLE;
    end
    else begin
        cur_state <= next_state;
    end
end
//2.
always_comb begin:second_state
    case (cur_state)
        IDLE :begin 
            if (init) begin
                next_state = INIT_KEY;
            end
            else begin
                next_state = next_state;
            end
        end
        INIT_KEY:begin
            case (AES_MODE)
                AES_128_KEY:begin
                    if ((cnt_round == 1)) begin
                        next_state = ROUND_KEY;
                    end
                    else begin
                        next_state = next_state;
                    end
                end
                AES_192_KEY:begin
                    if ((cnt_word == (AES_192_N_KEY - AES_128_N_KEY)) && (cnt_round == (1))) begin
                        next_state = ROUND_KEY;
                    end
                    else begin
                        next_state = next_state;
                    end
                end
                AES_256_KEY:begin
                    if ((cnt_round == (1))) begin
                        next_state = ROUND_KEY;
                    end
                    else begin
                        next_state = next_state;
                    end
                end
                default:
                    next_state = next_state;
            endcase
        end
        ROUND_KEY:begin
            if ((cnt_round == tem_mode_round + 1) && (cnt_word == 1)) begin
                next_state = DONE;
            end
            else begin
                next_state = next_state;
            end
        end
        DONE: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end
//3.
always @(posedge clk) begin:third_state
    if(rst) begin
        cnt_round     <= 0;
        cnt_round6_8  <= 0;
        cnt_word      <= 0;
        cnt_remain0   <= 0;
        key_mem_new   <= 0; 
        key_done_flag <= 0;
        tem_key0      <= key_in[255:128];
        tem_key1      <= key_in[127:0];
        wr_sbox_flag  <= 1'b0;
        tem_sbox_wr   <=32'd0;
        key_new_we    <= 1'b0;
        tem_ready     <= 1'b0;//*在down模式拉高
        for(integer i = 0;i < 8;i++) begin
            w[i] <= 32'd0;
        end
        for(integer i = 0;i < 4;i++) begin
            temp_w[i] <= 32'd0;
        end
    end
    else begin
        case (next_state)
            IDLE:begin
                cnt_round     <= 0;
                cnt_round6_8  <= 0;
                cnt_word      <= 0;
                cnt_remain0   <= 0;
                key_mem_new   <= 0;
                tem_key0      <= key_in[255:128];
                tem_key1      <= key_in[127:0];
                key_done_flag <= 1'b0;
                key_new_we    <= 1'b0;
                for(integer i = 0;i < 8;i++) begin
                    w[i] <= 32'd0;
                end
                for(integer i = 0;i < 4;i++) begin
                    temp_w[i] <= 32'd0;
                end
                tem_ready <= init ? 1'b0 : tem_ready;
            end
            INIT_KEY:begin
                case (AES_MODE)
                    AES_128_KEY: begin
                        key_mem_new   <= tem_key0;
                        cnt_round     <= 4'd1;
                        cnt_word      <= 2'd0;
                        key_done_flag <= 1'b1;
                        {w[0],w[1],w[2],w[3]} <= tem_key0;
                    end
                    AES_192_KEY: begin
                        key_mem_new   <= tem_key0;
                        cnt_round     <= 4'd1;
                        cnt_word      <= 2'd2;
                        cnt_round6_8  <= 0;
                        cnt_remain0   <= 3'd5;
                        key_done_flag <= 1'b1;
                        {w[0],w[1],w[2],w[3],w[4],w[5]} <= {tem_key0,tem_key1[127:64]};
                    end
                    AES_256_KEY: begin
                        key_mem_new   <= tem_key0;
                        //key_mem[1]    <= tem_key1;
                        cnt_round     <= 4'd1;
                        cnt_word      <= 2'd0;
                        cnt_remain0   <= 3'd7;
                        key_done_flag <= 1'b1;
                        {temp_w[0],temp_w[1],temp_w[2],temp_w[3],w[4],w[5],w[6],w[7]} <= {tem_key0,tem_key1};
                        {w[0],w[1],w[2],w[3]} <= tem_key1;
                    end
                    default:begin
                        cnt_round     <= 4'd0;
                        cnt_word      <= 2'd0;
                        key_mem_new   <= 128'd0;
                        key_done_flag <= 1'd0;
                    end
                endcase
            end
            ROUND_KEY: begin
                    case (AES_MODE)
                        AES_128_KEY:begin
                            if (cnt_word == 0) begin//*开始是第四个字
                                cnt_word     <= 2'd1;
                                cnt_round    <= cnt_round;
                                wr_sbox_flag <= 1'b1;
                                tem_sbox_wr  <= {w[3][23:0],w[3][31:24]};
                                key_new_we   <= 1'b1;
                                key_mem_new  <= {w[4],w[5],w[6],w[7]};
                                key_done_flag<= key_new_we ? 1'b1 : 1'b0;
                            end
                            else if(wr_sbox_flag) begin
                                cnt_word      <= cnt_word;
                                cnt_round     <= cnt_round;
                                w[4] <= w[0]^sbox_rd^rcon_table[cnt_round-1];
                                wr_sbox_flag  <= 1'b0;
                                key_mem_new   <= 128'd0;
                                key_done_flag <= 1'b0;
                            end
                            else if(cnt_word == (AES_128_N_KEY-1)) begin
                                cnt_word      <= 2'd0;
                                cnt_round     <= cnt_round + 1;
                                w[cnt_word+4] <= w[cnt_word+0-2]^w[cnt_word+3];
                                {w[0],w[1],w[2],w[3]} <= {w[4],w[5],w[6],w[cnt_word+0-2]^w[cnt_word+3]};
                                key_done_flag <= 1'b0;
                                key_mem_new   <= 128'd0;
                            end
                            else begin
                                w[cnt_word+4] <= w[cnt_word+0]^w[cnt_word+3];
                                cnt_word      <= cnt_word + 1   ;
                                cnt_round     <= cnt_round      ;
                                key_done_flag <= 1'b0       ;
                                key_mem_new   <= 128'd0       ;
                            end
                        end 
                        AES_192_KEY:begin
                            if ((cnt_remain0 == AES_192_N_KEY - 1) || (cnt_word == 0)) begin:remian6_0
                                cnt_round     <= cnt_round;
                                cnt_word      <= cnt_word + 1;
                                w[4] <= (cnt_remain0 != (AES_192_N_KEY - 1)) ? w[3]^temp_w[2] : w[4];//*因为cnt word为0的情况已经被截胡了，所以这里要判断w4的值
                                cnt_round6_8  <= (cnt_remain0 == AES_192_N_KEY - 1) ? cnt_round6_8 + 1'b1 : cnt_round6_8;
                                cnt_remain0   <= (cnt_remain0 == AES_192_N_KEY - 1) ? 3'd0 : cnt_remain0+ 1'b1;
                                key_done_flag <= (cnt_word == 0) ? 1'b1 : 1'b0;
                                key_mem_new   <= (cnt_word == 0) ? {w[4],w[5],w[6],w[7]} : 0;
                                wr_sbox_flag  <= (cnt_remain0 == AES_192_N_KEY - 1) ? 1'b1 : 1'b0;
                                tem_sbox_wr   <= (cnt_word == 2) ? {w[5][23:0],w[5][31:24]} : {w[3][23:0],w[3][31:24]};
                            end
                            else if(wr_sbox_flag) begin
                                w[6] <= (cnt_word == 3) ? w[0] ^ sbox_rd ^ rcon_table[cnt_round6_8 - 1] : w[6];
                                w[4] <= (cnt_word == 1) ? temp_w[2] ^ sbox_rd ^ rcon_table[cnt_round6_8 - 1] : w[4];
                                cnt_remain0   <= cnt_remain0 ;
                                cnt_round6_8  <= cnt_round6_8  ;
                                cnt_word      <= cnt_word    ;
                                cnt_round     <= cnt_round   ;
                                wr_sbox_flag  <= 1'b0        ;
                                key_done_flag <= 1'b0        ;
                            end
                            else if(cnt_word == (AES_128_N_KEY-1)) begin
                                cnt_word      <= 2'd0;
                                cnt_round     <= cnt_round + 1;
                                cnt_remain0   <= cnt_remain0 + 1;
                                w[cnt_word+4] <= w[cnt_word+0-2]^w[cnt_word+3];
                                {w[0],w[1],w[2],w[3]} <= {w[4],w[5],w[6],w[cnt_word+0-2]^w[cnt_word+3]};
                                {temp_w[0],temp_w[1],temp_w[2],temp_w[3]} <= {w[0],w[1],w[2],w[3]};
                                key_done_flag <= 1'b0;
                                key_mem_new   <= 128'd0;
                            end
                            else begin
                                w[cnt_word+4] <= (cnt_word >= 2) ? w[cnt_word-2]^w[cnt_word+3] : w[cnt_word+3]^temp_w[cnt_word+2];
                                cnt_word      <= cnt_word + 1'b1;
                                cnt_round     <= cnt_round;
                                cnt_remain0   <= cnt_remain0 + 1'b1;
                                key_done_flag <= 1'b0;
                                key_mem_new   <= 128'd0;
                            end
                        end
                        AES_256_KEY:begin
                            if ((cnt_word == 0)) begin:remian8_0
                                cnt_round     <= (cnt_round == 1) ? 4'd2 : cnt_round;
                                cnt_word      <= cnt_word + 1;
                                cnt_round6_8  <= (cnt_remain0 == 3) ? cnt_round6_8 : cnt_round6_8 + 1'b1;
                                cnt_remain0   <= cnt_remain0+ 1'b1;
                                key_done_flag <= 1'b1;
                                key_mem_new   <= {w[4],w[5],w[6],w[7]} ;
                                wr_sbox_flag  <= 1'b1;
                                tem_sbox_wr   <= (cnt_remain0 == 3) ? w[3] : {w[3][23:0],w[3][31:24]};
                            end
                            else if(wr_sbox_flag) begin
                                w[4] <=  (cnt_remain0 == 4) ? (temp_w[0]^sbox_rd) : (temp_w[0] ^ sbox_rd ^ rcon_table[cnt_round6_8 - 1]);
                                cnt_remain0   <= cnt_remain0 ;
                                cnt_round6_8  <= cnt_round6_8;
                                cnt_word      <= cnt_word    ;
                                cnt_round     <= cnt_round   ;
                                wr_sbox_flag  <= 1'b0        ;
                                key_done_flag <= 1'b0        ;
                            end
                            else if(cnt_word == (AES_128_N_KEY-1)) begin
                                cnt_word      <= 2'd0;
                                cnt_round     <= cnt_round + 1;
                                cnt_remain0   <= cnt_remain0 + 1;
                                w[cnt_word+4] <= temp_w[cnt_word]^w[cnt_word+3];
                                {w[0],w[1],w[2],w[3]} <= {w[4],w[5],w[6],temp_w[cnt_word]^w[cnt_word+3]};
                                {temp_w[0],temp_w[1],temp_w[2],temp_w[3]} <= {w[0],w[1],w[2],w[3]};
                                key_done_flag <= 1'b0;
                                key_mem_new   <= 128'd0;
                            end
                            else begin
                                w[cnt_word+4] <= w[cnt_word+3]^temp_w[cnt_word];
                                cnt_word      <= cnt_word + 1'b1;
                                cnt_round     <= cnt_round;
                                cnt_remain0   <= cnt_remain0 + 1'b1;
                                key_done_flag <= 1'b0;
                                key_mem_new   <= 128'd0;
                            end
                        end
                        default:begin
                            cnt_round    <= 4'b0;
                            cnt_word     <= 2'd0;
                            key_mem_new  <= 128'd0;
                            key_done_flag<= 1'b0;
                            wr_sbox_flag <= 1'b0;
                            tem_sbox_wr  <=32'd0;
                        end
                    endcase
                end
            DONE:begin
                cnt_round    <= 4'b0;
                cnt_word     <= 2'd0;
                key_mem_new  <= 128'd0;
                key_done_flag<= 1'b0;
                wr_sbox_flag <= 1'b0;
                tem_sbox_wr  <=32'd0;
                key_new_we   <= 1'b0;
                tem_ready    <= 1'b1;
            end
            default: begin
                cnt_round   <= 0;
                cnt_word    <= 0;
                key_mem_new <= 0; 
                tem_key0    <= 128'd0;
                tem_key1    <= 128'd0;
                wr_sbox_flag<= 1'b0;
                tem_sbox_wr <=32'd0;
                key_new_we  <= 1'b0;
                tem_ready   <= 1'b0;//*在down模式拉高
                for(integer i = 0;i < 8;i++) begin
                    w[i] <= 32'd0;
                end
            end
        endcase
    end
end
// endregion:state machine

// region:************instantiate************
aes_sbox u_aes_sbox(
	//ports
	.sboxw     		( tem_sbox_wr     	),
	.new_sboxw 		( new_sboxw 		)
);
// endregion:instantiate
endmodule //key_expasion