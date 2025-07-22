// 2023 FPGA
// FIANL : Polish Notation(PN)
//
// -----------------------------------------------------------------------------
// ©Communication IC & Signal Processing Lab 716
// -----------------------------------------------------------------------------
// Author : HSUAN-YU LIN
// File   : PN.v
// Create : 2023-02-27 13:19:54
// Revise : 2023-02-27 13:19:54
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
//`include "./ALU.v"
module PN(
    input clk,
    input rst_n,
    input [1:0] mode,
    input operator,
    input [2:0] in,
    input in_valid,
    output reg out_valid,
    output reg signed [31:0] out
    );
    
//================================================================
//   PARAMETER/INTEGER
//================================================================

//integer
integer i;

localparam IDLE   = 3'd0;
localparam CAL    = 3'd1;
localparam SORT   = 3'd2;
localparam OUT    = 3'd5;

localparam MAX    =  32767;
localparam MIN    = -32767;

//================================================================
//   REG/WIRE
//================================================================
//FSM
reg [2:0] curr_state,next_state;
//mem
reg signed [31:0] in_reg [0:11];
//input
reg  [1:0]  mode_r;
reg  [11:0] op_flag;
//global
reg  [3:0]  counter;
//alu
reg  [2:0]  op_w;
reg  [3:0]  alu_cnt;
reg  [3:0]  comp_valid;
 
//flag
wire start_flag = !in_valid && counter != 'd0;
wire is_op = op_flag[alu_cnt];
reg  cal_done;
reg  out_done;

//IO
reg  signed [31:0] number_A_w;
reg  signed [31:0] number_B_w;
wire [2:0] op = curr_state == CAL ? op_w : 'd7;
wire signed [31:0] alu_o;

//sort
wire signed [31:0] comp_layer_0[0:3];
wire signed [31:0] comp_layer_1[0:3];
wire signed [31:0] comp_layer_2[0:3];
wire signed [31:0] comp_layer_3[0:1];

assign comp_layer_0[0] = comp_valid[0]  ? in_reg[8]  : mode_r[0] ? MAX : MIN;//big min
assign comp_layer_0[1] = comp_valid[1]  ? in_reg[9]  : mode_r[0] ? MAX : MIN;//    min
assign comp_layer_0[2] = comp_valid[2]  ? in_reg[10] : mode_r[0] ? MAX : MIN;//big 0 
assign comp_layer_0[3] = comp_valid[3]  ? in_reg[11] : mode_r[0] ? MAX : MIN;//    7

assign comp_layer_1[0] = comp_layer_0[0] > comp_layer_0[1] ? comp_layer_0[0] : comp_layer_0[1];//big MIN
assign comp_layer_1[1] = comp_layer_0[0] > comp_layer_0[1] ? comp_layer_0[1] : comp_layer_0[0];//    MIN
assign comp_layer_1[2] = comp_layer_0[2] > comp_layer_0[3] ? comp_layer_0[2] : comp_layer_0[3];//big 7
assign comp_layer_1[3] = comp_layer_0[2] > comp_layer_0[3] ? comp_layer_0[3] : comp_layer_0[2];//    0

assign comp_layer_2[0] = comp_layer_1[0] > comp_layer_1[2] ? comp_layer_1[0] : comp_layer_1[2];//big 7
assign comp_layer_2[1] = comp_layer_1[0] > comp_layer_1[2] ? comp_layer_1[2] : comp_layer_1[0];//    min
assign comp_layer_2[2] = comp_layer_1[1] > comp_layer_1[3] ? comp_layer_1[1] : comp_layer_1[3];//    0
assign comp_layer_2[3] = comp_layer_1[1] > comp_layer_1[3] ? comp_layer_1[3] : comp_layer_1[1];//small min

assign comp_layer_3[0] = comp_layer_2[1] > comp_layer_2[2] ? comp_layer_2[1] : comp_layer_2[2];//big
assign comp_layer_3[1] = comp_layer_2[1] > comp_layer_2[2] ? comp_layer_2[2] : comp_layer_2[1];//small

//================================================================
//   FSM
//================================================================
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        curr_state <= IDLE;
    end 
    else begin
        curr_state <= next_state;
    end
end

always @(*) begin
    case (curr_state)
        IDLE : next_state = start_flag ? CAL : IDLE;
        CAL  : next_state = cal_done   ? !mode_r[1] ? SORT : OUT : CAL ;
        SORT : next_state = OUT;
        OUT  : next_state = out_done ? IDLE : OUT;
        default : next_state = IDLE;
    endcase
end

//================================================================
//   OUT
//================================================================

//output
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        out <= 'd0;
    end 
    else if(curr_state == OUT) begin
        case (mode_r)
            2'd0:out <= in_reg[counter];
            2'd1:out <= in_reg[counter];
            2'd2:out <= in_reg[0];
            2'd3:out <= in_reg[counter_sub1];
            default : out <= MAX;
        endcase
    end
    else begin
        out <= 'd0;
    end
end

//out_valid
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        out_valid <= 0;
    end 
    else if(curr_state == OUT) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end

//================================================================
//   In
//================================================================

//mode_r
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        mode_r <= 'd0;
    end 
    else if(in_valid && counter == 'd0) begin
        mode_r <= mode;
    end
end

//op_flag
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        op_flag <= 'd0;
    end 
    else if(in_valid) begin
        op_flag[counter] <= operator;
    end
    else if(curr_state == CAL) begin
        op_flag[counter] <= 0;
    end
    else if(curr_state == OUT) begin
        op_flag <= 'd0;
    end
end

//in_reg
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        for (i = 0; i < 12; i=i+1) begin
            in_reg[i] <= 'd0;
        end
    end 
    else if(in_valid) begin
        in_reg[counter] <= in;
    end
    else if(curr_state == CAL) begin
        case (mode_r)
            2'd0:in_reg[alu_cnt] <= alu_o;
            2'd1:in_reg[alu_cnt] <= alu_o;
            2'd2:begin
                if (is_op) begin
                    in_reg[alu_cnt] <= alu_o;
                    for (i = 0; i < 7; i=i+1) begin
                        if (i > alu_cnt) begin
                            in_reg[i] <= in_reg[i+2]; // 把原本是operator or operand 的地方設成0 (in_reg在一開始初始化的時候全部都會是0)
                        end 
                    end
                end
            end
            2'd3:begin
                if (is_op) begin
                    in_reg[alu_cnt] <= alu_o;
                    for (i = 0; i < 7; i=i+1) begin
                        if (i < alu_cnt) begin
                            if (i > 1) begin
                                in_reg[i] <= in_reg[i-2]; // 將前面的資料移動
                            end
                            else begin
                                in_reg[i] <= 'd0; // 把in_reg[0], in_reg[1] set to 0
                            end
                        end
                    end 
                end
            end 
            default : in_reg[0] <= MAX;
        endcase
    end
    else if(curr_state == SORT) begin //big to small
        in_reg[8]  <= comp_layer_2[0];//1
        in_reg[9]  <= comp_layer_3[0];//2
        in_reg[10] <= comp_layer_3[1];//3
        in_reg[11] <= comp_layer_2[3];//4
    end
    else if(curr_state == IDLE && !start_flag) begin
        for (i = 0; i < 12; i=i+1) begin
            in_reg[i] <= 'd0;
        end
    end
end

//================================================================
//   DESIGN
//================================================================

wire [3:0] counter_add1 = counter + 'd1;
wire [3:0] counter_sub1 = counter - 'd1;
wire [3:0] counter_sub2 = counter - 'd2;
wire [3:0] counter_sub3 = counter - 'd3;

//counter
always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        counter <= 'd0;
    end 
    else if(in_valid) begin
        counter <= counter_add1;
    end
    else if(curr_state == SORT) begin
        if(mode_r[0]) counter <= 'd11;
        else          counter <= 'd8 ;
    end
    else if(out_done) begin
        counter <= 'd0;
    end
    else if(curr_state == OUT) begin
        if(mode_r[0]) counter <= counter_sub1;
        else          counter <= counter_add1;
    end
    else if(curr_state == CAL) begin
        if(!mode_r[1]) begin
            counter <= counter_sub3;
        end
    end
end 

always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        comp_valid <= 'd0;
    end 
    else if(curr_state == CAL) begin
        comp_valid[alu_cnt[1:0]] <= 1;
    end
    else if(curr_state == IDLE) begin
        comp_valid <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
        alu_cnt <= 'd11;
    end 
    else if(curr_state == IDLE && start_flag) begin
        if (mode_r == 'd2) begin
            alu_cnt <= counter - 'd2;
        end
        else if(mode_r == 'd3) begin
            alu_cnt <= 'd2;
        end
    end
    else if(curr_state == CAL && !cal_done) begin
        if(mode_r == 'd3) begin
            alu_cnt <= alu_cnt + 'd1;
        end
        else begin
            alu_cnt <= alu_cnt - 'd1;
        end
    end
    else if(curr_state == OUT && !out_done) begin
        alu_cnt <= alu_cnt + 'd1;
    end
end

always @(*) begin 
    if (curr_state == CAL) begin
        case (mode_r)
            2'd0 : number_A_w = in_reg[counter_sub2];
            2'd1 : number_A_w = in_reg[counter_sub3];
            2'd2 : number_A_w = in_reg[alu_cnt+'d1];
            2'd3 : number_A_w = in_reg[alu_cnt-'d2];
            default : number_A_w = 'd0;
        endcase
    end
    else begin
        number_A_w = 'd0;
    end
end

always @(*) begin 
    if (curr_state == CAL) begin
        case (mode_r)
            2'd0 : number_B_w = in_reg[counter_sub1];
            2'd1 : number_B_w = in_reg[counter_sub2];
            2'd2 : number_B_w = in_reg[alu_cnt+'d2];
            2'd3 : number_B_w = in_reg[alu_cnt-'d1];
            default : number_B_w = 'd0;
        endcase
    end
    else begin
        number_B_w = 'd0;
    end
end

always @(*) begin 
    if (curr_state == CAL) begin
        case (mode_r)
            2'd0 : op_w = in_reg[counter_sub3];
            2'd1 : op_w = in_reg[counter_sub1];
            2'd2 : op_w = in_reg[alu_cnt];
            2'd3 : op_w = in_reg[alu_cnt];
            default : op_w = 'd7;
        endcase
    end
    else begin
        op_w = 'd0;
    end
end

always @(*) begin
    if (!mode_r[1]) begin
        cal_done = counter == 'd3 ? 1 : 0;
    end
    else begin
        cal_done = counter == 'd0 || op_flag == 'd0; 
    end
    case (mode_r)
        2'd0 : cal_done = counter == 'd3;
        2'd1 : cal_done = counter == 'd3;
        2'd2 : cal_done = alu_cnt == 'd0 || op_flag == 'd0;
        2'd3 : cal_done = alu_cnt == counter_sub1 || op_flag == 'd0;
        default : /* default */;
    endcase
end

always @(*) begin 
    if (curr_state == OUT) begin
        if (!mode_r[1]) begin
            out_done = alu_cnt == 'd11;
        end
        else begin
            out_done = 1;
        end
    end
    else begin
        out_done = 0;
    end
end

//================================================================
//   I/O
//================================================================

ALU inst_ALU
    (
        .clk      (clk),
        .rst_n    (rst_n),
        .operand  (op),
        .number_A (number_A_w),
        .number_B (number_B_w),
        .out      (alu_o)
    );


endmodule

module ALU (
    input clk,    // Clock
    input rst_n,  // Asynchronous reset active low
    input [2:0] operand,
    input  signed [31:0]  number_A,
    input  signed [31:0]  number_B,
    output reg signed [31:0]  out
);
wire signed [31:0] temp[0:3];
assign temp[0] = number_A + number_B;
assign temp[1] = number_A - number_B;
assign temp[2] = number_A * number_B;
assign temp[3] = ~temp[0] + 'd1;

always @(*) begin 
    case (operand)
        3'd0 : out = temp[0];
        3'd1 : out = temp[1];
        3'd2 : out = number_A * number_B;
        3'd3 : out = temp[0][31] ? temp[3] : temp[0];
        default : out = 'd0;
    endcase
end

endmodule 
