% filename -> .tiff image.
function JPG_encode_decode(filename, quality)
    
    close all;
    
    setMatrices(quality);
    im = imread(filename);
    %figure; image(im(505:512,1:8,:)); axis image;
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
    
    global jpec_zz
    jpec_zz = [	0   1   8   16  9   2   3   10
                17  24  32  25  18  11  4   5
                12  19  26  33  40  48  41  34
                27  20  13  6   7   14  21  28
                35  42  49  56  57  50  43  36
                29  22  15  23  30  37  44  51
                58  59  52  45  38  31  39  46
                53  60  61  54  47  55  62  63]'+1;

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
    n_blocks = 0;
    for r=1 : N : rows
        for c=1 : N : cols
            aux = dct2(Y(r:r+N-1, c:c+N-1));
            Y_compressed(r:r+N-1, c:c+N-1) = round(aux./Ql);
            aux = dct2(Cb(r:r+N-1, c:c+N-1));
            Cb_compressed(r:r+N-1, c:c+N-1) = round(aux./Qc);
            aux = dct2(Cr(r:r+N-1, c:c+N-1));
            Cr_compressed(r:r+N-1, c:c+N-1) = round(aux./Qc);
            n_blocks = n_blocks+1;
            if(n_blocks==3214||n_blocks==1786||n_blocks==4085||n_blocks==2696||n_blocks==672)
				n_blocks
				Y_compressed(r:r+N-1, c:c+N-1)
                Cb_compressed(r:r+N-1, c:c+N-1)
                Cr_compressed(r:r+N-1, c:c+N-1)
            end
        end
    end
    n_blocks
    
    im_compressed = zeros(size(im), 'double');  % Store image in double to save precision.
    im_compressed(:,:,1) = Y_compressed;
    im_compressed(:,:,2) = Cb_compressed;
    im_compressed(:,:,3) = Cr_compressed;

    % Mat -> Blocks.
     [rows, cols] = size(Y_compressed);
%     n_rows_blocks = rows/8;          % # of rows of blocks 8x8.
%     n_cols_blocks = cols/8;          % # of cols of blocks 8x8.
%     % https://www.mathworks.com/help/matlab/ref/repmat.html
%     dim_rows = repmat(8, [1 n_rows_blocks]);
%     dim_cols = repmat(8, [1 n_cols_blocks]);
%     % https://www.mathworks.com/help/matlab/ref/mat2cell.html
%     Y_blocks = mat2cell(Y, dim_cols, dim_rows);
    n_blocks = (rows/8)*(cols/8);
    r = 1;
    c = 1;
    for i=1 : 1 : n_blocks
        cell = Y_compressed(r:r+N-1, c:c+N-1);
        Y_compressed_blocks{i} = reshape(cell,[1,N*N]);
        c = c + N;
        if(c>=cols)
            c = 1;
            r = r + N;
        end
    end
    
    % Block #25(5*5)  row #1 col #25 (starting with 1) (sample=512x512 -> 64x64 blocks)
    Y_compressed_blocks{25} = [
        160     0       -3      -2      0       0       0       0
        -75     -2      -1      0       0       0       0       0
        -69     -5      -2      0       0       0       0       0
        -59     -5      -3      0       0       0       0       0
        -34     -2      0       0       0       0       0       0
        -28     -1      0       0       0       0       0       0
        -8      0       0       0       0       0       0       0
        -2      0       0       0       0       0       0       0]';
    % Block #200(20*10) row #4 col #8
    Y_compressed_blocks{200} = [
        -146    -82     -17     -20     -16     3       2       0
        17      10      -24     8       -11     4       0       0
        -36     21      0       3       3       0       0       0
        -4      -8      14      -6      3       0       0       0
        -6      5       -3      -1      0       0       0       0
        -5      1       0       0       0       0       0       0
        0       0       0       0       0       0       0       0
        0       0       0       0       0       0       0       0]';
    % Block #250(25*10) row #4 col #58
    Y_compressed_blocks{250} = [
        -206    -91     76      1       -9      1       0       0
        55      -64     32      -2      -4      1       0       0
        6       -12     5       0       0       0       0       0
        -6      7       0       -3      2       -1      0       0
        -4      7       -2      0       0       0       0       0
        1       0       0       0       -1      0       0       0
        0       0       0       0       0       0       0       0
        0       0       0       0       0       0       0       0]';
    
    %reshape(Y_compressed_blocks{250},[8,8])
    
    % ZZ.
    % TODO: despues implementarlo dentro del anterior for for.
    for i=1 : 1 : n_blocks
        Y_zz_blocks{i} = zigzag(Y_compressed_blocks{25});
    end
    
    reshape(Y_zz_blocks{25},[8,8])'
    
%     figure(1); imshow(im_compressed);
%     figure(2); imshow(Y_compressed);
%     figure(3); imshow(Cb_compressed);
%     figure(4); imshow(Cr_compressed);

end

function zigzag_block = zigzag(block)
    global jpec_zz
    global N
    zigzag_block = zeros(1,N*N);
    for i=1 : 1 : N*N
        zigzag_block(i) = block(jpec_zz(i));
        % if ((e->block.zz[i] = e->block.quant[jpec_zz[i]])) e->block.len = i + 1;
    end
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