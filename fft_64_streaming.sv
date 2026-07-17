`timescale 1ns / 1ps
module fft_64_streaming(
input logic clk, rst, valid_in,
input  logic signed [15:0] sample_in,

output logic ready, valid_out,
output logic signed [21:0] fft_real,
output logic signed [21:0] fft_imag
);


logic signed [31:0] s0r [0:63];// to store real part of stage 0
logic signed [31:0] s0i [0:63];// to store imaginary part of stage 0
logic signed [31:0] s1r [0:63];
logic signed [31:0] s1i [0:63];
logic signed [31:0] s2r [0:63];
logic signed [31:0] s2i [0:63];
logic signed [31:0] s3r [0:63];
logic signed [31:0] s3i [0:63];
logic signed [31:0] s4r [0:63];
logic signed [31:0] s4i [0:63];
logic signed [31:0] s5r [0:63];
logic signed [31:0] s5i [0:63];
logic signed [31:0] s6r [0:63];
logic signed [31:0] s6i [0:63];

logic signed [15:0] sample_buffer [0:63];
logic [5:0] sample_count;
logic [5:0] output_count;


logic signed [31:0] tw_r;
logic signed [31:0] tw_i;
logic signed [15:0] twiddle_real [0:31];
logic signed [15:0] twiddle_imag [0:31];

//==============================
// Multiplier Pipeline Registers
//==============================

// Stage-1 : Raw multiplier outputs
logic signed [47:0] mult_rr1;
logic signed [47:0] mult_rr2;
logic signed [47:0] mult_ii1;
logic signed [47:0] mult_ii2;

// Stage-2 : Final complex multiplication
logic signed [47:0] mult_r;
logic signed [47:0] mult_i;

// Butterfly temporary registers
logic signed [31:0] upper_r;
logic signed [31:0] upper_i;
logic signed [31:0] lower_r;
logic signed [31:0] lower_i;


typedef enum logic [5:0]{
IDLE      = 6'd0,
RECEIVE   = 6'd1,
LOAD      = 6'd2,
STAGE1    = 6'd3,
STAGE2    = 6'd4,
MULT3      = 6'd5,
MULT3_ADD  = 6'd6,
SCALE3     = 6'd7,
BUTTER3    = 6'd8,
STORE3     = 6'd9,

MULT4      = 6'd10,
MULT4_ADD  = 6'd11,
SCALE4     = 6'd12,
BUTTER4    = 6'd13,
STORE4     = 6'd14,

MULT5      = 6'd15,
MULT5_ADD  = 6'd16,
SCALE5     = 6'd17,
BUTTER5    = 6'd18,
STORE5     = 6'd19,

MULT6      = 6'd20,
MULT6_ADD  = 6'd21,
SCALE6     = 6'd22,
BUTTER6    = 6'd23,
STORE6     = 6'd24,

SEND       = 6'd25
} state_t;
state_t state;


integer i;

int butterfly3, group3;
int butterfly4, group4;
int butterfly5, group5;
int butterfly6, group6;    


initial begin

    // k = 0
    twiddle_real[0]  = 16'sd32767;
    twiddle_imag[0]  = 16'sd0;

    // k = 1
    twiddle_real[1]  = 16'sd32609;
    twiddle_imag[1]  = -16'sd3212;

    // k = 2
    twiddle_real[2]  = 16'sd32137;
    twiddle_imag[2]  = -16'sd6393;

    // k = 3
    twiddle_real[3]  = 16'sd31356;
    twiddle_imag[3]  = -16'sd9512;

    // k = 4
    twiddle_real[4]  = 16'sd30273;
    twiddle_imag[4]  = -16'sd12539;

    // k = 5
    twiddle_real[5]  = 16'sd28898;
    twiddle_imag[5]  = -16'sd15446;

    // k = 6
    twiddle_real[6]  = 16'sd27245;
    twiddle_imag[6]  = -16'sd18204;

    // k = 7
    twiddle_real[7]  = 16'sd25329;
    twiddle_imag[7]  = -16'sd20787;

    // k = 8
    twiddle_real[8]  = 16'sd23170;
    twiddle_imag[8]  = -16'sd23170;

    // k = 9
    twiddle_real[9]  = 16'sd20787;
    twiddle_imag[9]  = -16'sd25329;

    // k = 10
    twiddle_real[10] = 16'sd18204;
    twiddle_imag[10] = -16'sd27245;

    // k = 11
    twiddle_real[11] = 16'sd15446;
    twiddle_imag[11] = -16'sd28898;

    // k = 12
    twiddle_real[12] = 16'sd12539;
    twiddle_imag[12] = -16'sd30273;

    // k = 13
    twiddle_real[13] = 16'sd9512;
    twiddle_imag[13] = -16'sd31356;

    // k = 14
    twiddle_real[14] = 16'sd6393;
    twiddle_imag[14] = -16'sd32137;

    // k = 15
    twiddle_real[15] = 16'sd3212;
    twiddle_imag[15] = -16'sd32609;

    // k = 16
    twiddle_real[16] = 16'sd0;
    twiddle_imag[16] = -16'sd32767;

    // k = 17
    twiddle_real[17] = -16'sd3212;
    twiddle_imag[17] = -16'sd32609;

    // k = 18
    twiddle_real[18] = -16'sd6393;
    twiddle_imag[18] = -16'sd32137;

    // k = 19
    twiddle_real[19] = -16'sd9512;
    twiddle_imag[19] = -16'sd31356;

    // k = 20
    twiddle_real[20] = -16'sd12539;
    twiddle_imag[20] = -16'sd30273;

    // k = 21
    twiddle_real[21] = -16'sd15446;
    twiddle_imag[21] = -16'sd28898;

    // k = 22
    twiddle_real[22] = -16'sd18204;
    twiddle_imag[22] = -16'sd27245;

    // k = 23
    twiddle_real[23] = -16'sd20787;
    twiddle_imag[23] = -16'sd25329;

    // k = 24
    twiddle_real[24] = -16'sd23170;
    twiddle_imag[24] = -16'sd23170;

    // k = 25
    twiddle_real[25] = -16'sd25329;
    twiddle_imag[25] = -16'sd20787;

    // k = 26
    twiddle_real[26] = -16'sd27245;
    twiddle_imag[26] = -16'sd18204;

    // k = 27
    twiddle_real[27] = -16'sd28898;
    twiddle_imag[27] = -16'sd15446;

    // k = 28
    twiddle_real[28] = -16'sd30273;
    twiddle_imag[28] = -16'sd12539;

    // k = 29
    twiddle_real[29] = -16'sd31356;
    twiddle_imag[29] = -16'sd9512;

    // k = 30
    twiddle_real[30] = -16'sd32137;
    twiddle_imag[30] = -16'sd6393;

    // k = 31
    twiddle_real[31] = -16'sd32609;
    twiddle_imag[31] = -16'sd3212;

end

//bit reversal
function automatic [5:0] bit_reverse(input [5:0] x);//earlier x5 is MSB
begin
    bit_reverse = {x[0],x[1],x[2],x[3],x[4],x[5]};// here at after reversal x0 becomes our MSB
end
endfunction


always_ff @(posedge clk or posedge rst) begin
if(rst) begin
state <= IDLE;
ready <= 1;
valid_out <= 0;
sample_count <= 0;
output_count <= 0;
fft_real <= 0;
fft_imag <= 0;
tw_r <= 0;
tw_i <= 0;
mult_r <= 0;
mult_i <= 0;
group3 <= 0;
butterfly3 <= 0;
group4 <= 0;
butterfly4 <= 0;
group5 <= 0;
butterfly5 <= 0;
group6 <= 0;
butterfly6 <= 0;
upper_r <= 0;
upper_i <= 0;
lower_r <= 0;
lower_i <= 0;


end else begin
case(state)
IDLE: begin

    ready <= 1'b1;
    valid_out <= 1'b0;

    if(valid_in) begin
        sample_buffer[0] <= sample_in;
        sample_count <= 6'd1;
        state <= RECEIVE;
    end

end


RECEIVE: begin
ready <= 1'b1;
if(valid_in) begin
sample_buffer[sample_count] <= sample_in;
if(sample_count == 6'd63) begin
sample_count <= 0;
ready <= 1'b0;
state <= LOAD;
end else begin
sample_count <= sample_count + 1;
end
end
end

LOAD: begin
for(i=0;i<64;i=i+1) begin
   s0r[bit_reverse(i)] <= sample_buffer[i];
   s0i[bit_reverse(i)] <= 32'sd0;
end

state <= STAGE1;
end

STAGE1: begin
for(i=0;i<64;i=i+2) begin
s1r[i] <= s0r[i] + s0r[i+1];
s1r[i+1] <= s0r[i] - s0r[i+1];
s1i[i] <= s0i[i] + s0i[i+1];
s1i[i+1] <= s0i[i] - s0i[i+1];
end
state <= STAGE2;
end 

STAGE2: begin
for(int group = 0; group < 64; group = group + 4) begin
// Butterfly (0,2),(4,6),(10,12)..... : W64^0 = 1
s2r[group]   <= s1r[group]   + s1r[group+2];
s2r[group+2] <= s1r[group]   - s1r[group+2];
s2i[group]   <= s1i[group]   + s1i[group+2];
s2i[group+2] <= s1i[group]   - s1i[group+2];
// Butterfly (1,3),(5,7),(9,11).... : W64^16 = -j
s2r[group+1] <= s1r[group+1] + s1i[group+3];
s2i[group+1] <= s1i[group+1] - s1r[group+3];
s2r[group+3] <= s1r[group+1] - s1i[group+3];
s2i[group+3] <= s1i[group+1] + s1r[group+3];
end

group3 <= 0;
butterfly3 <= 0;
state <= MULT3;
end


MULT3: begin

    mult_rr1 <= s2r[(group3<<3)+4+butterfly3] *
                twiddle_real[butterfly3<<3];

    mult_rr2 <= s2i[(group3<<3)+4+butterfly3] *
                twiddle_imag[butterfly3<<3];

    mult_ii1 <= s2r[(group3<<3)+4+butterfly3] *
                twiddle_imag[butterfly3<<3];

    mult_ii2 <= s2i[(group3<<3)+4+butterfly3] *
                twiddle_real[butterfly3<<3];

    state <= MULT3_ADD;

end


MULT3_ADD: begin

    mult_r <= mult_rr1 - mult_rr2;

    mult_i <= mult_ii1 + mult_ii2;

    state <= SCALE3;

end

SCALE3: begin
tw_r <= 32'( (mult_r + 48'sd16384) >>> 15 );
tw_i <= 32'( (mult_i + 48'sd16384) >>> 15 );
state <= BUTTER3;
end

BUTTER3: begin
    upper_r <= s2r[(group3<<3)+butterfly3] + tw_r;
    upper_i <= s2i[(group3<<3)+butterfly3] + tw_i;
    lower_r <= s2r[(group3<<3)+butterfly3] - tw_r;
    lower_i <= s2i[(group3<<3)+butterfly3] - tw_i;
    state <= STORE3;
end

STORE3: begin
    s3r[(group3<<3)+butterfly3] <= upper_r;
    s3i[(group3<<3)+butterfly3] <= upper_i;
    s3r[(group3<<3)+4+butterfly3] <= lower_r;
    s3i[(group3<<3)+4+butterfly3] <= lower_i;
    
    if(butterfly3 < 3) begin
        butterfly3 <= butterfly3 + 1;
        state <= MULT3;
    end else begin
        butterfly3 <= 0;
        if(group3 < 7) begin
            group3 <= group3 + 1;
            state <= MULT3;
        end else begin
            group4 <= 0;
            butterfly4 <= 0;
            state <= MULT4;
        end
    end
end


MULT4: begin

    mult_rr1 <= s3r[(group4<<4)+8+butterfly4] *
                twiddle_real[butterfly4<<2];

    mult_rr2 <= s3i[(group4<<4)+8+butterfly4] *
                twiddle_imag[butterfly4<<2];

    mult_ii1 <= s3r[(group4<<4)+8+butterfly4] *
                twiddle_imag[butterfly4<<2];

    mult_ii2 <= s3i[(group4<<4)+8+butterfly4] *
                twiddle_real[butterfly4<<2];

    state <= MULT4_ADD;

end

MULT4_ADD: begin

    mult_r <= mult_rr1 - mult_rr2;

    mult_i <= mult_ii1 + mult_ii2;

    state <= SCALE4;

end


SCALE4: begin
tw_r <= 32'( (mult_r + 48'sd16384) >>> 15 );
tw_i <= 32'( (mult_i + 48'sd16384) >>> 15 );
state <= BUTTER4;
end


BUTTER4: begin
    upper_r <= s3r[(group4<<4)+butterfly4] + tw_r;
    upper_i <= s3i[(group4<<4)+butterfly4] + tw_i;
    lower_r <= s3r[(group4<<4)+butterfly4] - tw_r;
    lower_i <= s3i[(group4<<4)+butterfly4] - tw_i;
    state <= STORE4;
end


STORE4: begin
    s4r[(group4<<4)+butterfly4] <= upper_r;
    s4i[(group4<<4)+butterfly4] <= upper_i;
    s4r[(group4<<4)+8+butterfly4] <= lower_r;
    s4i[(group4<<4)+8+butterfly4] <= lower_i;

    if(butterfly4 < 7) begin
        butterfly4 <= butterfly4 + 1;
        state <= MULT4;
    end else begin
        butterfly4 <= 0;
        if(group4 < 3) begin
            group4 <= group4 + 1;
            state <= MULT4;
        end else begin
            group5 <= 0;
            butterfly5 <= 0;
            state <= MULT5;
        end
    end
end

MULT5: begin

    mult_rr1 <= s4r[(group5<<5)+16+butterfly5] *
                twiddle_real[butterfly5<<1];

    mult_rr2 <= s4i[(group5<<5)+16+butterfly5] *
                twiddle_imag[butterfly5<<1];

    mult_ii1 <= s4r[(group5<<5)+16+butterfly5] *
                twiddle_imag[butterfly5<<1];

    mult_ii2 <= s4i[(group5<<5)+16+butterfly5] *
                twiddle_real[butterfly5<<1];

    state <= MULT5_ADD;

end


MULT5_ADD: begin

    mult_r <= mult_rr1 - mult_rr2;

    mult_i <= mult_ii1 + mult_ii2;

    state <= SCALE5;

end


SCALE5: begin
tw_r <= 32'( (mult_r + 48'sd16384) >>> 15 );
tw_i <= 32'( (mult_i + 48'sd16384) >>> 15 );
state <= BUTTER5;
end


BUTTER5: begin
    upper_r <= s4r[(group5<<5)+butterfly5] + tw_r;
    upper_i <= s4i[(group5<<5)+butterfly5] + tw_i;
    lower_r <= s4r[(group5<<5)+butterfly5] - tw_r;
    lower_i <= s4i[(group5<<5)+butterfly5] - tw_i;
    state <= STORE5;
end


STORE5: begin
    s5r[(group5<<5)+butterfly5] <= upper_r;
    s5i[(group5<<5)+butterfly5] <= upper_i;
    s5r[(group5<<5)+16+butterfly5] <= lower_r;
    s5i[(group5<<5)+16+butterfly5] <= lower_i;

    if(butterfly5 < 15) begin
        butterfly5 <= butterfly5 + 1;
        state <= MULT5;
    end else begin
        butterfly5 <= 0;
        if(group5 < 1) begin
            group5 <= group5 + 1;
            state <= MULT5;
        end else begin
            group6 <= 0;
            butterfly6 <= 0;
            state <= MULT6;
        end
    end
end


MULT6: begin

    mult_rr1 <= s5r[(group6<<6)+32+butterfly6] *
                twiddle_real[butterfly6];

    mult_rr2 <= s5i[(group6<<6)+32+butterfly6] *
                twiddle_imag[butterfly6];

    mult_ii1 <= s5r[(group6<<6)+32+butterfly6] *
                twiddle_imag[butterfly6];

    mult_ii2 <= s5i[(group6<<6)+32+butterfly6] *
                twiddle_real[butterfly6];

    state <= MULT6_ADD;

end


MULT6_ADD: begin

    mult_r <= mult_rr1 - mult_rr2;

    mult_i <= mult_ii1 + mult_ii2;

    state <= SCALE6;

end


SCALE6: begin
tw_r <= 32'( (mult_r + 48'sd16384) >>> 15 );
tw_i <= 32'( (mult_i + 48'sd16384) >>> 15 );
state <= BUTTER6;
end


BUTTER6: begin
upper_r <= s5r[butterfly6] + tw_r;
upper_i <= s5i[butterfly6] + tw_i;
lower_r <= s5r[butterfly6] - tw_r;
lower_i <= s5i[butterfly6] - tw_i;
state <= STORE6;
end


STORE6: begin
s6r[butterfly6] <= upper_r;
s6i[butterfly6] <= upper_i;
s6r[32+butterfly6] <= lower_r;
s6i[32+butterfly6] <= lower_i;
if(butterfly6 < 31) begin
butterfly6 <= butterfly6 + 1;
state <= MULT6;
end else begin
butterfly6 <= 0;
group6 <= 0;
fft_real <= 0;
fft_imag <= 0;
output_count <= 0;
state <= SEND;
end
end

SEND: begin
    ready     <= 1'b0;
    valid_out <= 1'b1;
    fft_real <= s6r[output_count];
    fft_imag <= s6i[output_count];

    if(output_count == 6'd63) begin
        output_count <= 6'd0;
        sample_count <= 6'd0;
        butterfly3 <= 0;
        group3     <= 0;
        butterfly4 <= 0;
        group4     <= 0;
        butterfly5 <= 0;
        group5     <= 0;
        butterfly6 <= 0;
        group6     <= 0;
        state <= IDLE;
    end
    else begin
        output_count <= output_count + 1;
    end
end

default: begin
    state <= IDLE;
end


endcase
end
end
endmodule

