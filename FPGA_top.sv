`timescale 1ns / 1ps
module FPGA_top(
    input  logic clk,
    input  logic rst,
    input  logic uart_rx,
    output logic uart_tx
);
    
logic signed [15:0] sample_in;
logic   valid_in;    
logic ready;
logic peak_valid;
logic [43:0] peak1_value;
logic [43:0] peak2_value;
logic [43:0] peak3_value;
logic [43:0] peak4_value;
logic [5:0] peak1_bin;
logic [5:0] peak2_bin;
logic [5:0] peak3_bin;
logic [5:0] peak4_bin;
logic freq_valid;
logic signed [15:0] peak1_freq;
logic signed [15:0] peak2_freq;
logic signed [15:0] peak3_freq;
logic signed [15:0] peak4_freq;
logic signed [21:0] fft_real_out;
logic signed [21:0] fft_imag_out;
logic fft_valid_out;

logic       wr_en;
logic       busy;
logic       rdy;
logic       rdy_clr;
logic [7:0] data_in;
logic [7:0] data_out;


signal_analyzer SA(
    .clk(clk),
    .rst(rst),
    .sample_in(sample_in),
    .valid_in(valid_in),
    .ready(ready),
    .peak_valid(peak_valid),
    .peak1_value(peak1_value),
    .peak2_value(peak2_value),
    .peak3_value(peak3_value),
    .peak4_value(peak4_value),
    .peak1_bin(peak1_bin),
    .peak2_bin(peak2_bin),
    .peak3_bin(peak3_bin),
    .peak4_bin(peak4_bin),
    .fft_real_out(fft_real_out),
    .fft_imag_out(fft_imag_out),
    .fft_valid_out(fft_valid_out),
    .peak1_freq(peak1_freq),
    .peak2_freq(peak2_freq),
    .peak3_freq(peak3_freq),
    .peak4_freq(peak4_freq),
    .freq_valid(freq_valid)
);

uart_protocol UP(
    .clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .wr_en(wr_en),
    .rdy_clr(rdy_clr),
    .data_in(data_in),
    .busy(busy),
    .rdy(rdy),
    .data_out(data_out)
);

uart_controller UC(
    .clk(clk),
    .rst(rst),
    .freq_valid(freq_valid),
    .peak1_bin(peak1_bin),
    .peak2_bin(peak2_bin),
    .peak3_bin(peak3_bin),
    .peak4_bin(peak4_bin),
    .peak1_freq(peak1_freq),
    .peak2_freq(peak2_freq),
    .peak3_freq(peak3_freq),
    .peak4_freq(peak4_freq),
    .peak1_value(peak1_value),
    .peak2_value(peak2_value),
    .peak3_value(peak3_value),
    .peak4_value(peak4_value),
    .busy(busy),
    .wr_en(wr_en),
    .data_in(data_in)
);

uart_sample_receiver USR(
    .clk(clk),
    .rst(rst),
    .rdy(rdy),
    .data_out(data_out),
    .rdy_clr(rdy_clr),
    .sample_in(sample_in),
    .valid_in(valid_in)
);

endmodule
