clc;
clear;
close all;

N = 64;
Fs = 64000;
n = 0:N-1;

% Generate input signal
x = 1000*cos(2*pi*3*n/N) + 800*cos(2*pi*5*n/N);
x_int = round(x);

fprintf('Input Samples:\n');

for k = 1:N
    fprintf('Sample %2d = %d\n', k-1, x_int(k));
end

% Generate Q15 twiddle factors
TW_N = 32;
SCALE = 32768;

twiddle_real = zeros(1,TW_N);
twiddle_imag = zeros(1,TW_N);

for k = 0:TW_N-1

    twiddle_real(k+1) = round(SCALE*cos(2*pi*k/TW_N));
    twiddle_imag(k+1) = round(-SCALE*sin(2*pi*k/TW_N));

    if twiddle_real(k+1) > 32767
        twiddle_real(k+1) = 32767;
    elseif twiddle_real(k+1) < -32768
        twiddle_real(k+1) = -32768;
    end

    if twiddle_imag(k+1) > 32767
        twiddle_imag(k+1) = 32767;
    elseif twiddle_imag(k+1) < -32768
        twiddle_imag(k+1) = -32768;
    end
end

fprintf('\nTwiddle Factors:\n');

for k = 0:TW_N-1
    fprintf('k=%2d  Real=%6d  Imag=%6d\n', ...
        k, twiddle_real(k+1), twiddle_imag(k+1));
end

% Calculate 64-point MATLAB FFT
X_matlab = fft(x_int, N);
X_mag_matlab = abs(X_matlab);

fprintf('\nMATLAB FFT Results:\n');

for k = 0:N-1
    fprintf('Bin=%2d  Real=%10.2f  Imag=%10.2f  Magnitude=%10.2f\n', ...
        k, ...
        real(X_matlab(k+1)), ...
        imag(X_matlab(k+1)), ...
        X_mag_matlab(k+1));
end

% Find maximum peak
[peak_value, peak_index] = max(X_mag_matlab);
peak_bin = peak_index - 1;

fprintf('\nMATLAB Maximum Peak:\n');
fprintf('Peak Bin       = %d\n', peak_bin);
fprintf('Peak Magnitude = %.2f\n', peak_value);

% RTL magnitude for comparison
RTL_mag = X_mag_matlab;

% Plot
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