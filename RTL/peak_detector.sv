`timescale 1ns / 1ps
module peak_detector(
input logic clk, rst, valid_in,
input logic [43:0] magnitude_sq,
output logic [43:0] peak1_value,
output logic [43:0] peak2_value,
output logic [43:0] peak3_value,
output logic [43:0] peak4_value,
output logic [5:0] peak1_bin,
output logic [5:0] peak2_bin,
output logic [5:0] peak3_bin,
output logic [5:0] peak4_bin,
output logic peak_valid
);

logic [5:0] current_bin;


always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        peak1_value <= 0;
        peak2_value <= 0;
        peak3_value <= 0;
        peak4_value <= 0;

        peak1_bin <= 0;
        peak2_bin <= 0;
        peak3_bin <= 0;
        peak4_bin <= 0;

        peak_valid <= 0;
        current_bin <= 0;
    end
    else begin

        peak_valid <= 0;

        if(valid_in) begin

       if(current_bin == 6'd0) begin

    peak1_value <= magnitude_sq;
    peak1_bin   <= 6'd0;

    peak2_value <= 44'd0;
    peak2_bin   <= 6'd0;

    peak3_value <= 44'd0;
    peak3_bin   <= 6'd0;

    peak4_value <= 44'd0;
    peak4_bin   <= 6'd0;

end
else if(magnitude_sq > peak1_value) begin

    // Shift existing peaks down
    peak4_value <= peak3_value;
    peak4_bin   <= peak3_bin;

    peak3_value <= peak2_value;
    peak3_bin   <= peak2_bin;

    peak2_value <= peak1_value;
    peak2_bin   <= peak1_bin;

    // New largest peak
    peak1_value <= magnitude_sq;
    peak1_bin   <= current_bin;

end
else if(magnitude_sq > peak2_value) begin

    // Shift Peak2 -> Peak3 -> Peak4
    peak4_value <= peak3_value;
    peak4_bin   <= peak3_bin;

    peak3_value <= peak2_value;
    peak3_bin   <= peak2_bin;

    // New Peak2
    peak2_value <= magnitude_sq;
    peak2_bin   <= current_bin;

end
else if(magnitude_sq > peak3_value) begin

    // Shift Peak3 -> Peak4
    peak4_value <= peak3_value;
    peak4_bin   <= peak3_bin;

    // New Peak3
    peak3_value <= magnitude_sq;
    peak3_bin   <= current_bin;

end
else if(magnitude_sq > peak4_value) begin

    peak4_value <= magnitude_sq;
    peak4_bin   <= current_bin;

end
            if(current_bin == 6'd63) begin
                peak_valid  <= 1'b1;
                current_bin <= 6'd0;
            end
            else begin
                current_bin <= current_bin + 1;
            end

        end
    end
end
endmodule
