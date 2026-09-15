`timescale 1ns / 1ps
module uart_sample_receiver(
    input  logic clk,
    input  logic rst,
    input  logic rdy,
    input  logic [7:0] data_out,
    output logic rdy_clr,
    output logic signed [15:0] sample_in,
    output logic valid_in
);

logic [7:0] high_byte;
logic [7:0] low_byte;
logic first_byte;
logic [6:0] sample_count;

always_ff @(posedge clk or posedge rst) begin
if(rst) begin
high_byte    <= 8'd0;
low_byte     <= 8'd0;
sample_in    <= 16'sd0;
valid_in     <= 1'b0;
rdy_clr      <= 1'b0;
first_byte   <= 1'b1;
sample_count <= 7'd0;
end else begin
valid_in <= 1'b0;
rdy_clr  <= 1'b0;

if(rdy) begin
rdy_clr <= 1'b1;
if(first_byte) begin
high_byte  <= data_out;
first_byte <= 1'b0;
end else begin
low_byte <= data_out;
sample_in <= {high_byte, data_out};
valid_in <= 1'b1;
first_byte <= 1'b1;
if(sample_count < 7'd63)
sample_count <= sample_count + 1'b1;
else
sample_count <= 7'd0;
end
end
end
end
endmodule
