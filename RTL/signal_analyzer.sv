`timescale 1ns / 1ps 
module signal_analyzer#(
    parameter integer SAMPLE_RATE = 64000,
    parameter integer FFT_SIZE    = 64
)(
    input  logic clk, rst, valid_in,
    input  logic signed [15:0] sample_in,
    output logic ready, peak_valid,
    output logic [43:0] peak1_value,
    output logic [43:0] peak2_value,
    output logic [43:0] peak3_value,
    output logic [43:0] peak4_value,
    output logic [5:0] peak1_bin,
    output logic [5:0] peak2_bin,
    output logic [5:0] peak3_bin,
    output logic [5:0] peak4_bin,
    output logic signed [21:0] fft_real_out,
    output logic signed [21:0] fft_imag_out,
    output logic fft_valid_out,
    output logic signed [15:0] peak1_freq,
    output logic signed [15:0] peak2_freq,
    output logic signed [15:0] peak3_freq,
    output logic signed [15:0] peak4_freq,
    output logic freq_valid
);


logic valid_fft;
logic signed [21:0] fft_real;
logic signed [21:0] fft_imag;
logic valid_mag;
logic [43:0] magnitude_sq;

assign fft_real_out  = fft_real;
assign fft_imag_out  = fft_imag;
assign fft_valid_out = valid_fft;


fft_64_streaming A1(
    .clk(clk),
    .rst(rst),
    .sample_in(sample_in),
    .valid_in(valid_in),
    .ready(ready),
    .valid_out(valid_fft),
    .fft_real(fft_real),
    .fft_imag(fft_imag)
);

magnitude_calc A2(
    .clk(clk),
    .rst(rst),
    .valid_in(valid_fft),
    .fft_real(fft_real),
    .fft_imag(fft_imag),
    .valid_out(valid_mag),
    .magnitude_sq(magnitude_sq)
);

peak_detector A3(
    .clk(clk),
    .rst(rst),
    .valid_in(valid_mag),
    .magnitude_sq(magnitude_sq),
    .peak1_value(peak1_value),
    .peak2_value(peak2_value),
    .peak3_value(peak3_value),
    .peak4_value(peak4_value),
    .peak1_bin(peak1_bin),
    .peak2_bin(peak2_bin),
    .peak3_bin(peak3_bin),
    .peak4_bin(peak4_bin),
    .peak_valid(peak_valid)
);

freq_estimate #(
    .FFT_SIZE(FFT_SIZE),
    .SAMPLE_RATE(SAMPLE_RATE)
) A4(
    .clk(clk),
    .rst(rst),
    .peak_valid(peak_valid),
    .peak1_bin(peak1_bin),
    .peak2_bin(peak2_bin),
    .peak3_bin(peak3_bin),
    .peak4_bin(peak4_bin),
    .peak1_freq(peak1_freq),
    .peak2_freq(peak2_freq),
    .peak3_freq(peak3_freq),
    .peak4_freq(peak4_freq),
    .freq_valid(freq_valid)
);
endmodule
