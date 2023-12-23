`default_nettype none

module aes_inv_col_mix (
    input  wire clk,
    input  wire rst,

    input  wire [127:0] in,
    input  wire col_mix_en,

    output reg [127:0] out,
    output reg out_flag
);
localparam IDLE = 0,MIX_W0 = 1,MIX_W1 = 2,MIX_W2 = 3,MIX_W3 = 4,DONE = 5;
reg [2:0] cur_state,next_state;
reg [7:0] temp_r [15:0];
reg [7:0] temp_w [15:0];
reg [7:0] k [15:0];
reg  [7:0] k_out [15:0];
reg [1:0] cnt;
reg rom_en;
reg cal_flag;

always @(posedge clk) begin
    if(rst) begin
        for(integer i = 0;i < 16;i++) begin
            k[i] <= 8'd0;
        end
    end
    else if(col_mix_en) begin
        {k[0],k[1],k[2],k[3],
        k[4],k[5],k[6],k[7],
        k[8],k[9],k[10],k[11],
        k[12],k[13],k[14],k[15] } <= in; 
    end
    else if(out_flag) begin
        for(integer i = 0;i < 16;i++) begin
            k[i] <= 8'd0;
        end
    end
end

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
                for(integer i = 0;i < 16;i++) begin
                    temp_w[i] <= 8'd0;
                end
                for(integer i = 0;i < 16;i++) begin
                    k_out[i] <= 8'd0;
                end
                cnt <= 0;
                rom_en <= 1'b0;
            end
            MIX_W0:begin
                temp_w[0]  <=  k[0];//*09          
                temp_w[1]  <=  k[1];//*09
                temp_w[2]  <=  k[2];//*09
                temp_w[3]  <=  k[3];//*09

                temp_w[4]  <=  k[0];//*0b
                temp_w[5]  <=  k[1];//*0b
                temp_w[6]  <=  k[2];//*0b
                temp_w[7]  <=  k[3];//*0b

                temp_w[8]  <=  k[0];//*0d   
                temp_w[9]  <=  k[1];//*0d
                temp_w[10] <=  k[2];//*0d
                temp_w[11] <=  k[3];//*0d

                temp_w[12] <=  k[0];//*0e
                temp_w[13] <=  k[1];//*0e
                temp_w[14] <=  k[2];//*0e
                temp_w[15] <=  k[3];//*0e
                rom_en <= (cnt == 2) ? (0)  : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
            end
            MIX_W1:begin
                temp_w[0]  <=  k[4];//*09          
                temp_w[1]  <=  k[5];//*09
                temp_w[2]  <=  k[6];//*09
                temp_w[3]  <=  k[7];//*09

                temp_w[4]  <=  k[4];//*0b
                temp_w[5]  <=  k[5];//*0b
                temp_w[6]  <=  k[6];//*0b
                temp_w[7]  <=  k[7];//*0b

                temp_w[8]  <=  k[4];//*0d   
                temp_w[9]  <=  k[5];//*0d
                temp_w[10] <=  k[6];//*0d
                temp_w[11] <=  k[7];//*0d
                
                temp_w[12] <=  k[4];//*0e
                temp_w[13] <=  k[5];//*0e
                temp_w[14] <=  k[6];//*0e
                temp_w[15] <=  k[7];//*0e
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[0] <=  temp_r[12]^temp_r[5]^temp_r[10]^temp_r[3];
                k_out[1] <=  temp_r[0]^temp_r[13]^temp_r[6]^temp_r[11];
                k_out[2] <=  temp_r[8]^temp_r[1]^temp_r[14]^temp_r[7];
                k_out[3] <=  temp_r[4]^temp_r[9]^temp_r[2]^temp_r[15];
            end
            MIX_W2:begin
                temp_w[0]  <= k[8 ];//*09 
                temp_w[1]  <= k[9 ];//*09
                temp_w[2]  <= k[10];//*09
                temp_w[3]  <= k[11];//*09
                temp_w[4]  <= k[8 ];//*0b
                temp_w[5]  <= k[9 ];//*0b
                temp_w[6]  <= k[10];//*0b
                temp_w[7]  <= k[11];//*0b
                temp_w[8]  <= k[8 ];//*0d 
                temp_w[9]  <= k[9 ];//*0d
                temp_w[10] <= k[10];//*0d
                temp_w[11] <= k[11];//*0d
                temp_w[12] <= k[8 ];//*0e
                temp_w[13] <= k[9 ];//*0e
                temp_w[14] <= k[10];//*0e
                temp_w[15] <= k[11];//*0e
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[4] <=  temp_r[12]^temp_r[5]^temp_r[10]^temp_r[3];
                k_out[5] <=  temp_r[0]^temp_r[13]^temp_r[6]^temp_r[11];
                k_out[6] <=  temp_r[8]^temp_r[1]^temp_r[14]^temp_r[7];
                k_out[7] <=  temp_r[4]^temp_r[9]^temp_r[2]^temp_r[15];
            end
            MIX_W3:begin
                temp_w[0]  <= k[12];//*09 
                temp_w[1]  <= k[13];//*09
                temp_w[2]  <= k[14];//*09
                temp_w[3]  <= k[15];//*09
                temp_w[4]  <= k[12];//*0b
                temp_w[5]  <= k[13];//*0b
                temp_w[6]  <= k[14];//*0b
                temp_w[7]  <= k[15];//*0b
                temp_w[8]  <= k[12];//*0d 
                temp_w[9]  <= k[13];//*0d
                temp_w[10] <= k[14];//*0d
                temp_w[11] <= k[15];//*0d
                temp_w[12] <= k[12];//*0e
                temp_w[13] <= k[13];//*0e
                temp_w[14] <= k[14];//*0e
                temp_w[15] <= k[15];//*0e
                rom_en <= (cnt == 2) ? (0) : (1);
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[8] <=  temp_r[12]^temp_r[5]^temp_r[10]^temp_r[3];
                k_out[9] <=  temp_r[0]^temp_r[13]^temp_r[6]^temp_r[11];
                k_out[10] <=  temp_r[8]^temp_r[1]^temp_r[14]^temp_r[7];
                k_out[11] <=  temp_r[4]^temp_r[9]^temp_r[2]^temp_r[15];
            end
            DONE:begin
                cnt    <= (cnt == 2) ? ( 0) : (cnt + 1);
                k_out[12] <=  temp_r[12]^temp_r[5]^temp_r[10]^temp_r[3];
                k_out[13] <=  temp_r[0]^temp_r[13]^temp_r[6]^temp_r[11];
                k_out[14] <=  temp_r[8]^temp_r[1]^temp_r[14]^temp_r[7];
                k_out[15] <=  temp_r[4]^temp_r[9]^temp_r[2]^temp_r[15];
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
mul_09_bram u0 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[0]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[0]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[1]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[1]                 ) // output wire [7 : 0] doutb
);

mul_09_bram2 u1 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[2]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[2]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[3]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[3]                 ) // output wire [7 : 0] doutb
);
mul_0b_bram u2 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[4]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[4]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[5]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[5]                 ) // output wire [7 : 0] doutb
);

mul_0b_bram2 u3 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[6]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[6]                 ),// output wire [7 : 0] douta
    
    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[7]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[7]                 ) // output wire [7 : 0] doutb
);
mul_0d_bram u4 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[8]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[8]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[9]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[9]                 ) // output wire [7 : 0] doutb
);

mul_0d_bram2 u5 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[10]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[10]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[11]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[11]                 ) // output wire [7 : 0] doutb
);
mul_0e_bram u6 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[12]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[12]                 ),// output wire [7 : 0] douta

    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[13]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[13]                 ) // output wire [7 : 0] doutb
);

mul_0e_bram2 u7 (
    .clka                              (clk                       ),// input wire clka
    .ena                               (rom_en                    ),// input wire ena
    .addra                             (temp_w[14]                 ),// input wire [7 : 0] addra
    .douta                             (temp_r[14]                 ),// output wire [7 : 0] douta
    
    .clkb                              (clk                       ),// input wire clkb
    .enb                               (rom_en                    ),// input wire enb
    .addrb                             (temp_w[15]                 ),// input wire [7 : 0] addrb
    .doutb                             (temp_r[15]                 ) // output wire [7 : 0] doutb
);
endmodule //aes_col_mux