`timescale 1ns / 1ps
module freq_estimate(
    input  logic clk, rst, peak_valid,
    input  logic [5:0] peak1_bin,
    input  logic [5:0] peak2_bin,
    input  logic [5:0] peak3_bin,
    input  logic [5:0] peak4_bin,
    output logic signed [15:0] peak1_freq,
    output logic signed [15:0] peak2_freq,
    output logic signed [15:0] peak3_freq,
    output logic signed [15:0] peak4_freq,
    output logic freq_valid
);

parameter integer FFT_SIZE    = 64;
parameter integer SAMPLE_RATE = 64000;
localparam integer BIN_RESOLUTION = SAMPLE_RATE / FFT_SIZE;

always_ff @(posedge clk or posedge rst)begin
if(rst) begin
peak1_freq <= 0;
peak2_freq <= 0;
peak3_freq <= 0;
peak4_freq <= 0;
freq_valid <= 0;
end else begin
freq_valid <= 0;
if(peak_valid) begin
//Peak1
if(peak1_bin < FFT_SIZE/2)
    peak1_freq <= peak1_bin * BIN_RESOLUTION;
else
    peak1_freq <= ($signed({1'b0,peak1_bin}) - FFT_SIZE) * BIN_RESOLUTION;
//Peak2
if(peak2_bin < FFT_SIZE/2)
    peak2_freq <= peak2_bin * BIN_RESOLUTION;
else
    peak2_freq <= ($signed({1'b0,peak2_bin}) - FFT_SIZE) * BIN_RESOLUTION;
//Peak3
if(peak3_bin < FFT_SIZE/2)
    peak3_freq <= peak3_bin * BIN_RESOLUTION;
else
    peak3_freq <= ($signed({1'b0,peak3_bin}) - FFT_SIZE) * BIN_RESOLUTION;
//Peak4
if(peak4_bin < FFT_SIZE/2)
    peak4_freq <= peak4_bin * BIN_RESOLUTION;
else
    peak4_freq <= ($signed({1'b0,peak4_bin}) - FFT_SIZE) * BIN_RESOLUTION;

freq_valid <= 1'b1;
end
end
end

endmodule
