function JPEG_encode_decode(filename, quality)
    
    close all;
    
    setMatrices(quality);
    im = imread(filename);
    figure; image(im(505:512,1:8,:)); axis image;
    figure; image(im); axis image;
    im_compressed = JPEG_encode(im);
    im_decompressed = JPEG_decode(im_compressed);
    figure, image(im_decompressed); axis image;
    
end

function setMatrices(quality)
    
    global N    % Block size.
    N = 8;  
    
    global Ql   % Luminance quantization matrix.
    Ql = [  16 11 10 16 24 40 51 61;
            12 12 14 19 26 58 60 55;
            14 13 16 24 40 57 69 56;
            14 17 22 29 51 87 80 62;
            18 22 37 56 68 109 103 77;
            24 35 55 64 81 104 113 92;
            49 64 78 87 103 121 120 101; 
            72 92 95 98 112 100 103 99];
    
    global Qc   % Chrominance quantization matrix.
    Qc = [  17 18 24 47 99 99 99 99; 
            18 21 26 66 99 99 99 99; 
            24 26 56 99 99 99 99 99; 
            47 66 99 99 99 99 99 99; 
            99 99 99 99 99 99 99 99; 
            99 99 99 99 99 99 99 99; 
            99 99 99 99 99 99 99 99; 
            99 99 99 99 99 99 99 99];
    
    global alpha    % Quality factor.
    if quality>=1 && quality<=50
        alpha = 50/quality;
    elseif quality>=50 && quality<=100
        alpha = 2 - quality/50;
    end
    
    Ql = Ql*alpha;
    Qc = Qc*alpha;

end

function im_compressed = JPEG_encode(im)

    global N
    global Ql
    global Qc
        
    % Pad image.
    [rows, cols] = size(im);
    rows_rounded = ceil(rows/N);
    cols_rounded = ceil(cols/N);
    rows_pad = (rows_rounded*N) - rows;
    cols_pad = (cols_rounded*N) - cols;
    im = padarray(im,[rows_pad cols_pad],0,'post');

    im_ycbcr = rgb2ycbcr(im);
    figure; imshow(im_ycbcr);
    Y = im_ycbcr(:, :, 1);
    figure; image(im_ycbcr(505:512,1:8,1)); colormap gray; axis image;
    figure; imshow(Y); axis image;
    Cb = im_ycbcr(:, :, 2);
    Cr = im_ycbcr(:, :, 3);

    [rows, cols] = size(Y);
    Y_compressed = zeros(rows, cols, 'double');
    Cb_compressed = zeros(rows, cols, 'double');
    Cr_compressed = zeros(rows, cols, 'double');

    % DCT + quantization.
    for r=1 : N : rows
        for c=1 : N : cols
            aux = dct2(Y(r:r+N-1, c:c+N-1));
            Y_compressed(r:r+N-1, c:c+N-1) = round(aux./Ql);
            aux = dct2(Cb(r:r+N-1, c:c+N-1));
            Cb_compressed(r:r+N-1, c:c+N-1) = round(aux./Qc);
            aux = dct2(Cr(r:r+N-1, c:c+N-1));
            Cr_compressed(r:r+N-1, c:c+N-1) = round(aux./Qc);
        end
    end
    
    im_compressed = zeros(size(im), 'double');  % Store image in double to save precision.
    im_compressed(:,:,1) = Y_compressed;
    im_compressed(:,:,2) = Cb_compressed;
    im_compressed(:,:,3) = Cr_compressed;
    
%     figure(1); imshow(im_compressed);
%     figure(2); imshow(Y_compressed);
%     figure(3); imshow(Cb_compressed);
%     figure(4); imshow(Cr_compressed);

end

function im_decompressed = JPEG_decode(im_compressed)

    global N
    global Ql
    global Qc

    Y_compressed = im_compressed(:,:,1);
    Cb_compressed = im_compressed(:,:,2);
    Cr_compressed = im_compressed(:,:,3);
    
    [rows, cols] = size(Y_compressed);
    Y = zeros(rows, cols, 'uint8');
    Cb = zeros(rows, cols, 'uint8');
    Cr = zeros(rows, cols, 'uint8');
    
    for r=1 : N : rows
        for c=1 : N : cols
            aux = Y_compressed(r:r+N-1, c:c+N-1).*Ql;
            Y(r:r+N-1, c:c+N-1) = round(idct2(aux));
            aux = Cb_compressed(r:r+N-1, c:c+N-1).*Qc;
            Cb(r:r+N-1, c:c+N-1) = round(idct2(aux));
            aux = Cr_compressed(r:r+N-1, c:c+N-1).*Qc;
            Cr(r:r+N-1, c:c+N-1) = round(idct2(aux));
        end
    end
    
    im_ycbcr = zeros(rows, cols, 3, 'uint8');
    im_ycbcr(:,:,1) = Y;
    im_ycbcr(:,:,2) = Cb;
    im_ycbcr(:,:,3) = Cr;
    
    im_decompressed = ycbcr2rgb(im_ycbcr);
    
%     figure(5); imshow(im_decompressed);
%     figure(6); imshow(Y);
%     figure(7); imshow(Cb);
%     figure(8); imshow(Cr);
    
end