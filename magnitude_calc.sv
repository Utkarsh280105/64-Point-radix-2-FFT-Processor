`timescale 1ns / 1ps
module magnitude_calc(
    input  logic clk, rst, valid_in,
    input  logic signed [21:0] fft_real,
    input  logic signed [21:0] fft_imag,
    output logic valid_out,
    output logic [43:0] magnitude_sq
);


logic [43:0] real_sq;
logic [43:0] imag_sq;

always_ff @(posedge clk or posedge rst) begin
if(rst) begin
valid_out    <= 0;
magnitude_sq <= 0;
end else begin
valid_out <= valid_in;
if(valid_in) begin
magnitude_sq <= ((fft_real * fft_real) + (fft_imag * fft_imag));
end
end
end
endmodule

