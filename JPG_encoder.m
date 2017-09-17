% filename -> .tiff image.
function JPG_encoder(filename, quality)
    
    close all;
    
    global QT_Y
    global QT_CbCr
    global ZigZag
    
    global HT_Y_DC
    global HT_Y_DC_NVALUES
    global HT_Y_DC_VALUES
    
    global HT_Y_AC
    global HT_Y_AC_NVALUES
    global HT_Y_AC_VALUES
    
    global HT_CBCR_DC
    global HT_CBCR_DC_NVALUES
    global HT_CBCR_DC_VALUES
    
    global HT_CBCR_AC
    global HT_CBCR_AC_NVALUES
    global HT_CBCR_AC_VALUES
    
    global bitcode
    global category
    
    [   QT_Y, QT_CbCr, ZigZag, ...
        HT_Y_DC,     HT_Y_DC_NVALUES,   HT_Y_DC_VALUES, ...
        HT_Y_AC,     HT_Y_AC_NVALUES,   HT_Y_AC_VALUES, ...
        HT_CBCR_DC,    HT_CBCR_DC_NVALUES, HT_CBCR_DC_VALUES, ...
        HT_CBCR_AC,    HT_CBCR_AC_NVALUES, HT_CBCR_AC_VALUES, ...
        bitcode, category] = init(quality);

    image = imread(filename);   
    
    % Pad image.
    [rows, cols] = size(image);
    rows_rounded = ceil(rows/8);
    cols_rounded = ceil(cols/8);
    rows_pad = (rows_rounded*8) - rows;
    cols_pad = (cols_rounded*8) - cols;
    image = padarray(image,[rows_pad cols_pad],0,'post');
    [height, width, channels] = size(image);

    % Initialize output.
    global jpeg_file
    jpeg_file = [];
    writeBits(); % init this function's persistent variables.

    % Add JPEG headers
    jpeg_file = writeWord(jpeg_file, hex2dec('FFD8')); % SOI
    jpeg_file = writeAPP0(jpeg_file);
    jpeg_file = writeDQT(jpeg_file, QT_Y, QT_CbCr);
    jpeg_file = writeSOF(jpeg_file, width, height);    
    jpeg_file = writeDHT(jpeg_file, HT_Y_DC_NVALUES,   HT_Y_DC_VALUES, ...
                                HT_Y_AC_NVALUES,   HT_Y_AC_VALUES, ...
                                HT_CBCR_DC_NVALUES, HT_CBCR_DC_VALUES, ...
                                HT_CBCR_AC_NVALUES, HT_CBCR_AC_VALUES);
    jpeg_file = writeSOS(jpeg_file);
    
    im_ycbcr = my_rgb2ycbcr(image);
    %figure; imshow(im_ycbcr);
    Y = im_ycbcr(:, :, 1);
    %figure; image(im_ycbcr(505:512,1:8,1)); colormap gray; axis image;
    %figure; imshow(Y); axis image;
    Cb = im_ycbcr(:, :, 2);
    Cr = im_ycbcr(:, :, 3);

    % DCT + quantization.
    global n_blocks
    n_blocks = 0;
    DCY = 0;
    DCU = 0;
    DCV = 0;
    for r=1 : 8 : height
        for c=1 : 8 : width
            DCY = processDU(Y(r:r+8-1, c:c+8-1),  QT_Y,     DCY, HT_Y_DC, HT_Y_AC);
            DCU = processDU(Cb(r:r+8-1, c:c+8-1), QT_CbCr,  DCU, HT_CBCR_DC, HT_CBCR_AC);
            DCV = processDU(Cr(r:r+8-1, c:c+8-1), QT_CbCr,  DCV, HT_CBCR_DC, HT_CBCR_AC);
            n_blocks = n_blocks+1;
        end
    end
    
%     ycbcr = generateYCbCr(image);
%                      
%     global n_blocks
%     n_blocks = 0;
%     
%     while(y < height)
%         
%         x = 0;
%         
%         while(x < tripleWidth)
%             
%             start = tripleWidth * y + x;
%             p = start;
% 
%             YDU = zeros(1,64);
%             UDU = zeros(1,64);
%             VDU = zeros(1,64);
%       
%             YDU2 = zeros(1,64);
%             UDU2 = zeros(1,64);
%             VDU2 = zeros(1,64);
%             
%             for pos=0 : 63
%                 
%                 row = floor(bitsra(pos,3));    % /8
%                 col = bitand(pos,7)*3;  % %8
%                 p = start + ( row * tripleWidth ) + col;
% 
%                 if(y+row >= height)     % padding bottom
%                     p = p-(tripleWidth*(y+1+row-height));
%                     a = 1
%                 end
% 
%                 if(x+col >= tripleWidth)  % padding right
%                     p = p-((x+col) - tripleWidth +4);
%                     b = 1
%                 end
% 
% %                 r = rgb(p+1);
%                 YDU(pos+1) = ycbcr(p+1) - 121;  % Por alguna razon, les tengo que restar este valor. Sino no da como el original.
% %                 if(n_blocks==0)
% %                     YDU2
% %                 end
%                 p = p+1;
% %                 g = rgb(p+1);
%                 UDU(pos+1) = ycbcr(p+1) - 131;
% %                 if(n_blocks==0)
% %                     UDU2
% %                 end
%                 p = p+1;
% %                 b = rgb(p+1);
%                 VDU(pos+1) = ycbcr(p+1) - 122;
% %                 if(n_blocks==88)
% %                     VDU2
% %                 end
%                 p = p+1;
% 
%             end
% 
%             %if(x==48 && y==16) 
%             %    YDU
%             %end
%             
%             
%             DCY = processDU(YDU, QT_Y, DCY, HT_Y_DC, HT_Y_AC);
%             DCU = processDU(UDU, QT_CbCr, DCU, HT_CBCR_DC, HT_CBCR_AC);
%             DCV = processDU(VDU, QT_CbCr, DCV, HT_CBCR_DC, HT_CBCR_AC);
% 
% %             if(n_blocks==0)
% %                 jpeg_file
% %             end
%             
%             x = x+(8*3);
%             n_blocks = n_blocks+1;
%         end
%         
%         y = y+8;
%         
%     end

    global bytepos
    % Do the bit alignment of the EOI marker
    % tengo q traerme bytepos de writebits o pensar en algo.
    if( bytepos >= 0 )
        fillbits = zeros(1,2);
        fillbits(2) = bytepos+1;
        fillbits(1) = bitsll(bytepos+1,1)-1;
        jpeg_file = writeBits(jpeg_file, fillbits);
    end

    jpeg_file = writeWord(jpeg_file, hex2dec('FFD9')); % EOI (End of Image)
    
    fileID = fopen('test.jpg','w');
    fwrite(fileID,jpeg_file);
    fclose(fileID);
    %jpeg_file
end

%
% DCY = processDU(YDU, fdtbl_Y, DCY, HT_Y_DC, HT_Y_AC);
%
% CDU: 8x8 block (Y, Cb, Cr)
% fdtb1: quantization matrix(Y, Cb, Cr).
% DC: 8x8 empty block.
% HTDC: Huffman table (DC)
% HTAC: Huffman table (AC)
%
function DCY = processDU(CDU, fdtbl, DC, HTDC, HTAC)

    global n_blocks

    EOB = HTAC(1,:);
    M16zeroes = HTAC(hex2dec('F0')+1,:);
    I16 = 16;
    I63 = 63;
    I64 = 64;
    %DU_DCT = fDCTQuant(CDU, fdtbl);
    DU_DCT = DCTnQuant(CDU, fdtbl);
%     if(n_blocks==0)
%         DU_DCT
%     end
%     if(n_blocks==0)
%         DU_DCT
%         DU_DCT2
%     end
    
    % ZigZag reorder
    global ZigZag
    DU = zeros(1,64);
    for j=0 : I64-1
        DU(ZigZag(j+1))=DU_DCT(j+1);
    end


    
%     if(n_blocks==0)
%         n_blocks
%         Diff
%         DC
%     end

    global category
    global bitcode

    global jpeg_file
    
    % Encode DC
    % http://www.impulseadventure.com/photo/jpeg-huffman-coding.html
    % https://users.ece.utexas.edu/~ryerraballi/MSB/pdfs/M4L1.pdf
    % http://www.dmi.unict.it/~battiato/EI_MOBILE0708/JPEG%20(Bruna).pdf
    % Differential Pulse Code Modulation (DPCM): 
    % Encode the difference between the current and previous 8x8 block.
    % Example:
    % DC(1) = 4 (actual)
    % DC    = 2 (previous)
    % Diff = DU(1)-DC = 2
    % pos = 32767+Diff = 32769
    % category(pos+1) = 2
    % HTDC(category(pos+1)+1,:) = [3 3]
    % bitcode(pos+1,:) = [2 2]
     
    Diff = DU(1) - DC;
    DC = DU(1);

    if(Diff==0) 
        jpeg_file = writeBits(jpeg_file, HTDC(1,:)); % Diff might be 0
    else
        pos = 32767+Diff;
        jpeg_file = writeBits(jpeg_file, HTDC(category(pos+1)+1,:));
        jpeg_file = writeBits(jpeg_file, bitcode(pos+1,:));
%         if(n_blocks==179)
%             DU(1)
%             DC
%             Diff
%             category(pos+1)
%             HTDC(category(pos+1)+1,:)
%             bitcode(pos+1,:)
%         end
    end
    
    
    % Encode ACs
    end0pos = 63;       % was const... which is crazy
    while( (end0pos>0)&&(DU(end0pos+1)==0) )
        end0pos = end0pos-1;
    end
    %end0pos = first element in reverse order !=0
    global bytepos
    global bytenew
    if( end0pos == 0) 
%         if(n_blocks==0)
%             bytepos
%             bytenew
%         end
            
        jpeg_file = writeBits(jpeg_file, EOB);
% 
%         if(n_blocks==0)
%             jpeg_file
%         end
        DCY = DC;
        return;
    end

    i = 1;
    while( i<=end0pos )
        startpos = i;
        while(DU(i+1)==0 && (i<=end0pos))
            i = i+1;            
        end
        nrzeroes = i-startpos;
        if( nrzeroes >= I16 )
            lng = floor(bitsra(nrzeroes,4));
            for nrmarker=1 : lng
                jpeg_file = writeBits(jpeg_file, M16zeroes);
            end
            nrzeroes = bitand(nrzeroes, hex2dec('F'));
        end
        pos = 32767+DU(i+1);
        jpeg_file = writeBits(jpeg_file, HTAC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:));
%         if(n_blocks==53)
%             HTAC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:)
%             bitcode(pos+1,:)
%         end
        jpeg_file = writeBits(jpeg_file, bitcode(pos+1,:));
        i = i+1;
    end
    if( end0pos~=I63 )
        jpeg_file = writeBits(jpeg_file, EOB);
    end
    DCY = DC;
    
end

function dct_quant = DCTnQuant(data, quant_table) 

    data_aux = dct2(data/2);
    data_aux = reshape(data_aux',1,64);
    
    % Quantization.
    dct_quant = zeros(1,64,'double');
    for i=1 : 64
        dct_quant(i) = round(data_aux(i)./quant_table(i));
    end
    
end

function ycbcr = my_rgb2ycbcr(rgb)
%     ycbcr = rgb2ycbcr(rgb);
%     % https://stackoverflow.com/questions/18917585/why-to-minus-128-from-u-v-compent-of-yuv420p-for-converting-it-from-yuv420p-to-r
%     % http://what-when-how.com/introduction-to-video-and-image-processing/conversion-between-rgb-and-yuvycbcr-introduction-to-video-and-image-processing/
%     % https://www.mathworks.com/help/images/ref/rgb2ycbcr.html
%     % Y is in the range [16/255, 235/255], and Cb and Cr are in the range [16/255, 240/255].
%     [height, width, channels] = size(ycbcr);
%     for r=1 : height
%         for c=1 : width
%             ycbcr(r,c,1) = ycbcr(r,c,1);
%             ycbcr(r,c,2) = ycbcr(r,c,2) - 131;
%             ycbcr(r,c,3) = ycbcr(r,c,3) - 122;
%         end
%     end
    [height, width, channels] = size(rgb);
    ycbcr = zeros(height, width, channels);
    for r=1 : height
        for c=1 : width
            ycbcr(r,c,1) = ((( 0.29900)*rgb(r,c,1)+( 0.58700)*rgb(r,c,2)+( 0.11400)*rgb(r,c,3)))-121;
            ycbcr(r,c,2) = (((-0.16874)*rgb(r,c,1)+(-0.33126)*rgb(r,c,2)+( 0.50000)*rgb(r,c,3)))-131;
            ycbcr(r,c,3) = ((( 0.50000)*rgb(r,c,1)+(-0.41869)*rgb(r,c,2)+(-0.08131)*rgb(r,c,3)))-122;
        end
    end

end