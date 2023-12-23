`default_nettype none

module aes_col_mux (
    input  wire clk,
    input  wire rst,

    input  wire [127:0] in,
    input  wire col_mix_en,

    output reg [127:0] out,
    output reg out_flag
);
localparam IDLE = 0,MIX_W0 = 1,MIX_W1 = 2,MIX_W2 = 3,MIX_W3 = 4,DONE = 5;
reg [2:0] cur_state,next_state;
reg [7:0] temp_r [7:0];
reg [7:0] temp_w [7:0];
wire [7:0] k [15:0];
reg  [7:0] k_out [15:0];
reg [1:0] cnt;
reg rom_en;
reg cal_flag;
assign {k[0],k[1],k[2],k[3],
        k[4],k[5],k[6],k[7],
        k[8],k[9],k[10],k[11],
        k[12],k[13],k[14],k[15] } = in;
always @(posedge clk) begin
    if(rst) begin
        cal_flag <= 1'b0;
    end else if((cur_state == DONE)  && (cnt == 1)) begin
        cal_flag <= 1'b1;
    end else begin
        cal_flag <= 1'b0;
    end
end
always @(posedge clk) begin
    if(rst) begin
        out <= 128'd0;
        out_flag <= 1'b0;
    end
    else if(cal_flag) begin
        out <= {k_out[0],k_out[1],k_out[2],k_out[3],
                k_out[4],k_out[5],k_out[6],k_out[7],
                k_out[8],k_out[9],k_out[10],k_out[11],
                k_out[12],k_out[13],k_out[14],k_out[15]};
        out_flag <= 1'b1;
    end
    else begin
        out <= 128'd0;
        out_flag <= 1'b0;
    end
end

always @(posedge clk) begin
    if(rst) begin
        cur_state <= IDLE;
    end else begin
        cur_state <= next_state;
    end
end
always@(*)begin
    case (cur_state)
        IDLE:begin
            if(col_mix_en)begin
                next_state = MIX_W0;
            end else begin
                next_state = IDLE;
            end
        end 
        MIX_W0:begin
            if(cnt == 0) begin
                next_state = MIX_W1;
            end else begin
                next_state = MIX_W0;
            end
        end
        MIX_W1:begin
            if(cnt == 0) begin
                next_state = MIX_W2;
            end else begin
                next_state = MIX_W1;
            end
        end
        MIX_W2:begin
            if(cnt == 0) begin
                next_state = MIX_W3;
            end else begin
                next_state = MIX_W2;
            end
        end
        MIX_W3:begin
            if(cnt == 0) begin
                next_state = DONE;
            end else begin
                next_state = MIX_W3;
            end
        end
        DONE:begin
            if(cnt == 0) begin
                next_state = IDLE;
            end else begin
                next_state = DONE;
            end
        end
        default: next_state = IDLE;
    endcase
end
always @(posedge clk) begin
    if (rst) begin
        for(integer i = 0;i < 8;i++) begin
            temp_w[i] <= 8'd0;
        end
        for(integer i = 0;i < 16;i++) begin
            k_out[i] <= 8'd0;
        end
        cnt <= 0;
        rom_en <= 1'b0;
    end
    else begin
        case (next_state)
            IDLE:begin
                for(integer i = 0;i < 8;i++) begin
                    temp_w[i] <= 8'd0;
                end
                for(integer i = 0;i < 16;i++) begin
                    k_out[i] <= 8'd0;
                end
                cnt <= 0;
                rom_en <= 1'b0;
            end
            MIX_W0:begin
                temp_w[0] <= k[0];
                temp_w[1] <= k[1];
                temp_w[2] <= k[2];
                temp_w[3] <= k[3];
                temp_w[4] <= k[1];
                temp_w[5] <= k[2];
                temp_w[6] <= k[3];
                temp_w[7] <= k[0];
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
            end
            MIX_W1:begin
                temp_w[0] <= k[4];
                temp_w[1] <= k[5];
                temp_w[2] <= k[6];
                temp_w[3] <= k[7];
                temp_w[4] <= k[5];
                temp_w[5] <= k[6];
                temp_w[6] <= k[7];
                temp_w[7] <= k[4];
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[0] <=  temp_r[0]^temp_r[4]^k[2]^k[3];//*2k0^3k1^k2^k3
                k_out[1] <=  k[0]^temp_r[1]^temp_r[5]^k[3];
                k_out[2] <=  k[0]^k[1]^temp_r[2]^temp_r[6];
                k_out[3] <=  temp_r[3]^k[1]^k[2]^temp_r[7];
            end
            MIX_W2:begin
                temp_w[0] <= k[8];
                temp_w[1] <= k[9];
                temp_w[2] <= k[10];
                temp_w[3] <= k[11];
                temp_w[4] <= k[9];
                temp_w[5] <= k[10];
                temp_w[6] <= k[11];
                temp_w[7] <= k[8];
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[4] <=  temp_r[0]^temp_r[4]^k[7]^k[6];//*2k0^3k1^k2^k3
                k_out[5] <=  k[4]^temp_r[1]^temp_r[5]^k[7];
                k_out[6] <=  k[4]^k[5]^temp_r[2]^temp_r[6];
                k_out[7] <=  temp_r[3]^k[5]^k[6]^temp_r[7];
            end
            MIX_W3:begin
                temp_w[0] <= k[12];
                temp_w[1] <= k[13];
                temp_w[2] <= k[14];
                temp_w[3] <= k[15];
                temp_w[4] <= k[13];
                temp_w[5] <= k[14];
                temp_w[6] <= k[15];
                temp_w[7] <= k[12];
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[8]  <=  temp_r[0]^temp_r[4]^k[10]^k[11];//*2k0^3k1^k2^k3
                k_out[9]  <=  k[8]^temp_r[1]^temp_r[5]^k[11];
                k_out[10] <=  k[8]^k[9]^temp_r[2]^temp_r[6];
                k_out[11] <=  temp_r[3]^k[9]^k[10]^temp_r[7];
            end
            DONE:begin
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[12] <=  temp_r[0]^temp_r[4]^k[14]^k[15];//*2k0^3k1^k2^k3
                k_out[13] <=  k[12]^temp_r[1]^temp_r[5]^k[15];
                k_out[14] <=  k[12]^k[13]^temp_r[2]^temp_r[6];
                k_out[15] <=  temp_r[3]^k[13]^k[14]^temp_r[7];
            end
            default: begin
                for(integer i = 0;i < 8;i++) begin
                    temp_w[i] <= 8'd0;
                end
                for(integer i = 0;i < 16;i++) begin
                    k_out[i] <= 8'd0;
                end
                cnt <= 0;
                rom_en <= 1'b0;
            end
        endcase
    end
end
mul_02_bram u0 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[0]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[0]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[1]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[1]                 ) // output wire [7 : 0] doutb
);

mul_02_bram2 u1 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[2]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[2]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[3]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[3]                 ) // output wire [7 : 0] doutb
);
mul_03_bram u2 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[4]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[4]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[5]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[5]                 ) // output wire [7 : 0] doutb
);

mul_03_bram2 u3 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[6]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[6]                 ),// output wire [7 : 0] douta
    
    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[7]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[7]                 ) // output wire [7 : 0] doutb
);

endmodule //aes_col_mux