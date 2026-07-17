`timescale 1ns / 1ps

module top_test();

logic clk;
logic rst;
logic signed [15:0] sample_in;
logic valid_in;
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
logic signed [21:0] fft_real_out;
logic signed [21:0] fft_imag_out;
logic fft_valid_out;
logic signed [15:0] peak1_freq;
logic signed [15:0] peak2_freq;
logic signed [15:0] peak3_freq;
logic signed [15:0] peak4_freq;
logic freq_valid;

signal_analyzer uut(
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

parameter integer FFT_SIZE = 64;
parameter integer SAMPLE_RATE = 64000;
localparam integer BIN_RESOLUTION = SAMPLE_RATE/FFT_SIZE;
            
always #5 clk = ~clk;


integer i;
integer fin;
integer fexp;
integer fout;
integer tolerance = 200000;

logic signed [15:0] input_mem [0:63];

logic [5:0]  exp_bin [0:3];
logic [43:0] exp_mag [0:3];


//////////////////////////////////////////////////////////////
// Comparison Function
//////////////////////////////////////////////////////////////

function automatic bit within_tolerance;
    input [43:0] rtl;
    input [43:0] matlab;
    input integer tol;
begin
    if(rtl > matlab)
        within_tolerance = ((rtl - matlab) <= tol);
    else
        within_tolerance = ((matlab - rtl) <= tol);
end
endfunction




//////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////

initial
begin

    clk       = 0;
    rst       = 1;
    valid_in  = 0;
    sample_in = 0;

    //--------------------------------------------------------
    // Initialize memories
    //--------------------------------------------------------

    for(i=0;i<64;i=i+1)
        input_mem[i] = 0;

    for(i=0;i<4;i=i+1) begin
        exp_bin[i] = 0;
        exp_mag[i] = 0;
    end

    //--------------------------------------------------------
    // Reset
    //--------------------------------------------------------

    #100;
    rst = 0;

    #20;

fout = $fopen("C:/Users/utkar/OneDrive/Desktop/fft_output.txt","w");
if(fout == 0)
begin
    $display("ERROR : Cannot create fft_output.txt");
    $finish;
end
    //--------------------------------------------------------
    // Read input_data.txt
    //--------------------------------------------------------

    fin = $fopen("C:/Users/utkar/OneDrive/Desktop/input_data.txt","r");
    if(fin == 0)
    begin
        $display("ERROR : Cannot open input_data.txt");
        $finish;
    end

    for(i=0;i<64;i=i+1)
        $fscanf(fin,"%d",input_mem[i]);

    $fclose(fin);

 

    //--------------------------------------------------------
    // Read expected_peaks.txt
    //--------------------------------------------------------

    fexp = $fopen("C:/Users/utkar/OneDrive/Desktop/expected_peaks.txt","r");

    if(fexp == 0)
    begin
        $display("ERROR : Cannot open expected_peaks.txt");
        $finish;
    end

    for(i=0;i<4;i=i+1)
        $fscanf(fexp,"%d %d",
                exp_bin[i],
                exp_mag[i]);

    $fclose(fexp);

    $display("");
$display("**FFT PARAMETERS**");
$display("FFT Size             : %0d",FFT_SIZE);
$display("Sampling Frequency   : %0d Hz",SAMPLE_RATE);
$display("Frequency Resolution : %0d Hz/bin",BIN_RESOLUTION);


    $display("");
    $display("**EXPECTED PEAKS LOADED**");

    for(i=0;i<4;i=i+1)
        $display("Peak%0d : Bin=%0d Magnitude=%0d",
                 i+1,
                 exp_bin[i],
                 exp_mag[i]);

    //--------------------------------------------------------
    // Wait until FFT is ready
    //--------------------------------------------------------

    wait(ready);

    //--------------------------------------------------------
    // Stream 64 samples
    //--------------------------------------------------------

    for(i=0;i<64;i=i+1)
    begin

        @(posedge clk);

        sample_in <= input_mem[i];
        valid_in  <= 1'b1;

    end

    @(posedge clk);

    valid_in  <= 1'b0;
    sample_in <= 16'sd0;

  wait(freq_valid);
@(posedge clk);

    $display("");
    $display("**RTL DETECTED PEAKS**");

    $display("Peak1 : Bin=%0d Magnitude=%0d",
             peak1_bin,
             peak1_value);

    $display("Peak2 : Bin=%0d Magnitude=%0d",
             peak2_bin,
             peak2_value);

    $display("Peak3 : Bin=%0d Magnitude=%0d",
             peak3_bin,
             peak3_value);

    $display("Peak4 : Bin=%0d Magnitude=%0d",
             peak4_bin,
             peak4_value);
             
  $display("");
$display("**ESTIMATED FREQUENCIES**");          
             
$display("Peak1 : Bin=%0d  Frequency=%0d Hz  Magnitude=%0d",
         peak1_bin,
         peak1_freq,
         peak1_value);

$display("Peak2 : Bin=%0d  Frequency=%0d Hz  Magnitude=%0d",
         peak2_bin,
         peak2_freq,
         peak2_value);

$display("Peak3 : Bin=%0d  Frequency=%0d Hz  Magnitude=%0d",
         peak3_bin,
         peak3_freq,
         peak3_value);

$display("Peak4 : Bin=%0d  Frequency=%0d Hz  Magnitude=%0d",
         peak4_bin,
         peak4_freq,
         peak4_value);

    //--------------------------------------------------------
// Automatic Verification
//--------------------------------------------------------

if( peak1_bin == exp_bin[0] &&
    peak2_bin == exp_bin[1] &&
    peak3_bin == exp_bin[2] &&
    peak4_bin == exp_bin[3] &&

    within_tolerance(peak1_value,exp_mag[0],tolerance) &&
    within_tolerance(peak2_value,exp_mag[1],tolerance) &&
    within_tolerance(peak3_value,exp_mag[2],tolerance) &&
    within_tolerance(peak4_value,exp_mag[3],tolerance))
begin

    $display("");
    $display("**MATLAB-DRIVEN VERIFICATION PASSED**");

    $display("");
    $display("**Magnitude Errors**");
    $display("Peak1 Error = %0d",
             (peak1_value>exp_mag[0]) ?
             (peak1_value-exp_mag[0]) :
             (exp_mag[0]-peak1_value));

    $display("Peak2 Error = %0d",
             (peak2_value>exp_mag[1]) ?
             (peak2_value-exp_mag[1]) :
             (exp_mag[1]-peak2_value));

    $display("Peak3 Error = %0d",
             (peak3_value>exp_mag[2]) ?
             (peak3_value-exp_mag[2]) :
             (exp_mag[2]-peak3_value));

    $display("Peak4 Error = %0d",
             (peak4_value>exp_mag[3]) ?
             (peak4_value-exp_mag[3]) :
             (exp_mag[3]-peak4_value));

end
else
begin

    $display("");
    $display("**MATLAB-DRIVEN VERIFICATION FAILED**");

    $display("");

    $display("Expected:");
    $display("Peak1 Bin=%0d Mag=%0d",exp_bin[0],exp_mag[0]);
    $display("Peak2 Bin=%0d Mag=%0d",exp_bin[1],exp_mag[1]);
    $display("Peak3 Bin=%0d Mag=%0d",exp_bin[2],exp_mag[2]);
    $display("Peak4 Bin=%0d Mag=%0d",exp_bin[3],exp_mag[3]);

    $display("");

    $display("Detected:");
    $display("Peak1 Bin=%0d Mag=%0d",peak1_bin,peak1_value);
    $display("Peak2 Bin=%0d Mag=%0d",peak2_bin,peak2_value);
    $display("Peak3 Bin=%0d Mag=%0d",peak3_bin,peak3_value);
    $display("Peak4 Bin=%0d Mag=%0d",peak4_bin,peak4_value);

end

$fclose(fout);
    $finish;

end

//--------------------------------------------------------
// Save FFT output to file
//--------------------------------------------------------
always @(posedge clk)
begin
    if(fft_valid_out)
    begin
        $fdisplay(fout,"%0d %0d",
                  fft_real_out,
                  fft_imag_out);
    end
end
endmodule