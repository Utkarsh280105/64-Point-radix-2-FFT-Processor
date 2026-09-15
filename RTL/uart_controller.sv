`timescale 1ns / 1ps
module uart_controller(
    input  logic clk,
    input  logic rst,
    input  logic freq_valid,
    input  logic [5:0] peak1_bin,
    input  logic [5:0] peak2_bin,
    input  logic [5:0] peak3_bin,
    input  logic [5:0] peak4_bin,
    input  logic signed [15:0] peak1_freq,
    input  logic signed [15:0] peak2_freq,
    input  logic signed [15:0] peak3_freq,
    input  logic signed [15:0] peak4_freq,
    input  logic [43:0] peak1_value,
    input  logic [43:0] peak2_value,
    input  logic [43:0] peak3_value,
    input  logic [43:0] peak4_value,
    
    input  logic busy,
    output logic wr_en,
    output logic [7:0] data_in
);

localparam integer PACKET_SIZE = 31;

logic [7:0] tx_packet [0:PACKET_SIZE-1];
logic [5:0] tx_index;

typedef enum logic [2:0]{
    IDLE,
    LOAD_PACKET,
    SEND_BYTE,
    WAIT_BUSY,
    NEXT_BYTE
} state_t;
state_t state;

always_ff @(posedge clk or posedge rst)
begin
if(rst)
begin
state    <= IDLE;
tx_index <= 6'd0;
wr_en    <= 1'b0;
data_in  <= 8'd0;
end else begin

wr_en <= 1'b0;
case(state)

IDLE:
begin
tx_index <= 6'd0;
if(freq_valid)
state <= LOAD_PACKET;
end


LOAD_PACKET: begin
///HEADER
tx_packet[0] <= 8'hAA;
tx_packet[1] <= 8'h55;
//PEAK1
tx_packet[2] <= {2'b00,peak1_bin};
tx_packet[3] <= peak1_freq[7:0];
tx_packet[4] <= peak1_freq[15:8];
tx_packet[5] <= peak1_value[7:0];
tx_packet[6] <= peak1_value[15:8];
tx_packet[7] <= peak1_value[23:16];
tx_packet[8] <= peak1_value[31:24];
//PEAK2
tx_packet[9]  <= {2'b00,peak2_bin};
tx_packet[10] <= peak2_freq[7:0];
tx_packet[11] <= peak2_freq[15:8];
tx_packet[12] <= peak2_value[7:0];
tx_packet[13] <= peak2_value[15:8];
tx_packet[14] <= peak2_value[23:16];
tx_packet[15] <= peak2_value[31:24];
//PEAK3
tx_packet[16] <= {2'b00,peak3_bin};
tx_packet[17] <= peak3_freq[7:0];
tx_packet[18] <= peak3_freq[15:8];
tx_packet[19] <= peak3_value[7:0];
tx_packet[20] <= peak3_value[15:8];
tx_packet[21] <= peak3_value[23:16];
tx_packet[22] <= peak3_value[31:24];
//PEAK4
tx_packet[23] <= {2'b00,peak4_bin};
tx_packet[24] <= peak4_freq[7:0];
tx_packet[25] <= peak4_freq[15:8];
tx_packet[26] <= peak4_value[7:0];
tx_packet[27] <= peak4_value[15:8];
tx_packet[28] <= peak4_value[23:16];
tx_packet[29] <= peak4_value[31:24];
//ERROR CHECK
tx_packet[30] <= 8'hAA^8'h55^ {2'b00, peak1_bin}^ peak1_freq[7:0]^ peak1_freq[15:8]^ peak1_value[7:0]^
                 peak1_value[15:8]^ peak1_value[23:16]^ peak1_value[31:24]^ {2'b00, peak2_bin}^
                 peak2_freq[7:0]^ peak2_freq[15:8]^ peak2_value[7:0]^ peak2_value[15:8]^
                 peak2_value[23:16]^ peak2_value[31:24]^ {2'b00, peak3_bin}^ peak3_freq[7:0]^
                 peak3_freq[15:8]^ peak3_value[7:0]^ peak3_value[15:8]^ peak3_value[23:16]^
                 peak3_value[31:24]^ {2'b00, peak4_bin}^ peak4_freq[7:0]^ peak4_freq[15:8]^
                 peak4_value[7:0]^ peak4_value[15:8]^ peak4_value[23:16]^ peak4_value[31:24]; 
                   
tx_index <= 0;
state <= SEND_BYTE;
end


SEND_BYTE: begin
data_in <= tx_packet[tx_index];
wr_en <= 1'b1;
state <= WAIT_BUSY;
end


WAIT_BUSY: begin
if(busy)
state <= NEXT_BYTE;
end


NEXT_BYTE: begin
if(!busy) begin
if(tx_index == PACKET_SIZE-1) begin
state <= IDLE;
end else begin
tx_index <= tx_index + 1;
state <= SEND_BYTE;
end
end
end
endcase
end
end

endmodule
