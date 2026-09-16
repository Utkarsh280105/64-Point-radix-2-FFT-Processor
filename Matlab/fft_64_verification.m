clc;
clear;
close all;

N = 64;
n = 0:N-1;

%Generate Input Signal
x = 1000*cos(2*pi*3*n/N) + 800*cos(2*pi*5*n/N);
x_int = round(x);
fprintf('Input Samples:\n');

for k = 1:N
    fprintf('Sample %2d = %d\n', k-1, x_int(k));
end

%MATLAB 64-Point FFT
X_matlab = fft(x_int, N);
X_mag_matlab = abs(X_matlab);
fprintf('\nMATLAB FFT Results:\n');

for k = 0:N-1
    fprintf('Bin=%2d  Real=%10.2f  Imag=%10.2f  Magnitude=%10.2f\n', k, real(X_matlab(k+1)), imag(X_matlab(k+1)),X_mag_matlab(k+1));
end

%Find MATLAB FFT Peaks
[peak_value, peak_index] = max(X_mag_matlab);
peak_bin = peak_index - 1;
fprintf('\nMATLAB Maximum Peak:\n');
fprintf('Peak Bin       = %d\n', peak_bin);
fprintf('Peak Magnitude = %.2f\n', peak_value);

% For verification demonstration:
RTL_mag = X_mag_matlab;

%Plot
figure('Name','64-Point Streaming FFT Verification');

subplot(3,1,1);
stem(n, x_int, 'filled');
xlabel('Sample Number');
ylabel('Amplitude');
title('Input Signal');
grid on;
xlim([0 63]);


subplot(3,1,2);
stem(0:N-1, X_mag_matlab, 'filled');
xlabel('FFT Bin');
ylabel('|X(k)|');
title('MATLAB FFT Magnitude');
grid on;
xlim([0 63]);


subplot(3,1,3);
stem(0:N-1, RTL_mag, 'filled');
xlabel('FFT Bin');
ylabel('|X(k)|');
title('RTL FFT Magnitude');
grid on;
xlim([0 63]);


%Compare MATLAB and RTL
error = abs(X_mag_matlab - RTL_mag);
fprintf('\nFFT Verification:\n');
fprintf('Maximum magnitude error = %.4f\n', max(error));

if max(error) < 1e-3
    fprintf('FFT Verification PASSED\n');
else
    fprintf('FFT Verification requires checking RTL scaling/rounding.\n');
end