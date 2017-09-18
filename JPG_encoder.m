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
    
    % Initialize bit writer
    global byteout
    byteout = [];
    global bytenew
    global bytepos
    writeBits(); % init this function's persistent variables.

    % Add JPEG headers
    [height, width, channels] = size(image);
    byteout = writeWord(byteout, hex2dec('FFD8')); % SOI
    byteout = writeAPP0(byteout);
    byteout = writeDQT(byteout, QT_Y, QT_CbCr);
    byteout = writeSOF(byteout, width, height);    
    byteout = writeDHT(byteout, HT_Y_DC_NVALUES,   HT_Y_DC_VALUES, ...
                                HT_Y_AC_NVALUES,   HT_Y_AC_VALUES, ...
                                HT_CBCR_DC_NVALUES, HT_CBCR_DC_VALUES, ...
                                HT_CBCR_AC_NVALUES, HT_CBCR_AC_VALUES);
    byteout = writeSOS(byteout);
    
    % Encode 8x8 macroblocks
    DCY = 0;
    DCU = 0;
    DCV = 0; 
    % creo que son global
    %bytenew = 0;
    %bytepos = 7;

    quadWidth = width*4;
    tripleWidth = width*3;

    y = 0;

   % rgb = generateRGB(image);
    ycbcr = generateYCbCr(image);
                     
    global n_blocks
    n_blocks = 0;
    
    while(y < height)
        
        x = 0;
        
        while(x < tripleWidth)
            
            start = tripleWidth * y + x;
            p = start;

            YDU = zeros(1,64);
            UDU = zeros(1,64);
            VDU = zeros(1,64);
      
            YDU2 = zeros(1,64);
            UDU2 = zeros(1,64);
            VDU2 = zeros(1,64);
            
            for pos=0 : 63
                
                row = floor(bitsra(pos,3));    % /8
                col = bitand(pos,7)*3;  % %8
                p = start + ( row * tripleWidth ) + col;

                if(y+row >= height)     % padding bottom
                    p = p-(tripleWidth*(y+1+row-height));
                    a = 1
                end

                if(x+col >= tripleWidth)  % padding right
                    p = p-((x+col) - tripleWidth +4);
                    b = 1
                end

%                 r = rgb(p+1);
                YDU(pos+1) = ycbcr(p+1) - 121;  % Por alguna razon, les tengo que restar este valor. Sino no da como el original.
%                 if(n_blocks==0)
%                     YDU2
%                 end
                p = p+1;
%                 g = rgb(p+1);
                UDU(pos+1) = ycbcr(p+1) - 131;
%                 if(n_blocks==0)
%                     UDU2
%                 end
                p = p+1;
%                 b = rgb(p+1);
                VDU(pos+1) = ycbcr(p+1) - 122;
%                 if(n_blocks==88)
%                     VDU2
%                 end
                p = p+1;

            end

            %if(x==48 && y==16) 
            %    YDU
            %end
            
            
            DCY = processDU(YDU, QT_Y, DCY, HT_Y_DC, HT_Y_AC);
            DCU = processDU(UDU, QT_CbCr, DCU, HT_CBCR_DC, HT_CBCR_AC);
            DCV = processDU(VDU, QT_CbCr, DCV, HT_CBCR_DC, HT_CBCR_AC);

%             if(n_blocks==0)
%                 byteout
%             end
            
            x = x+(8*3);
            n_blocks = n_blocks+1;
        end
        
        y = y+8;
        
    end

    % Do the bit alignment of the EOI marker
    if( bytepos >= 0 )
        fillbits = zeros(1,2);
        fillbits(2) = bytepos+1;
        fillbits(1) = bitsll(bytepos+1,1)-1;
        byteout = writeBits(byteout, fillbits);
    end

    byteout = writeWord(byteout, hex2dec('FFD9')); % EOI (End of Image)
    
    fileID = fopen('test.jpg','w');
    fwrite(fileID,byteout);
    fclose(fileID);
    %byteout
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

    global byteout
    
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
        byteout = writeBits(byteout, HTDC(1,:)); % Diff might be 0
    else
        pos = 32767+Diff;
        byteout = writeBits(byteout, HTDC(category(pos+1)+1,:));
        byteout = writeBits(byteout, bitcode(pos+1,:));
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
            
        byteout = writeBits(byteout, EOB);
% 
%         if(n_blocks==0)
%             byteout
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
                byteout = writeBits(byteout, M16zeroes);
            end
            nrzeroes = bitand(nrzeroes, hex2dec('F'));
        end
        pos = 32767+DU(i+1);
        byteout = writeBits(byteout, HTAC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:));
%         if(n_blocks==53)
%             HTAC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:)
%             bitcode(pos+1,:)
%         end
        byteout = writeBits(byteout, bitcode(pos+1,:));
        i = i+1;
    end
    if( end0pos~=I63 )
        byteout = writeBits(byteout, EOB);
    end
    DCY = DC;
    
end

function dct_quant = DCTnQuant(data, quant_table) 

    global n_blocks
    data_aux = dct2(reshape(data,8,8)');
    data_aux = reshape(data_aux',1,64);
    
    % Quantize/descale the coefficients
    dct_quant = zeros(1,64);
    for i=0 : 63
    
        % Apply the quantization and scaling factor & Round to nearest integer
        dct_quant(i+1) = round(data_aux(i+1)./quant_table(i+1));
%         if (fdctquant > 0.0)
%             dct_quant(i+1) = floor(value+0.5);
%         else
%             dct_quant(i+1) = ceil(value-0.5);
%         end
        %outputfDCTQuant(i] = fround(fdctquant);

    end
    
end


% Porque en el codigo de javascript se ve que la imagen esta guardada pixel
% por pixel con los valores r, g y b consecutivos.
% Para aprovechar, convierto aca a YCbCr.
function ycbcr = generateYCbCr(image)

    image_ycbcr = rgb2ycbcr(image);
    [height, width, channels] = size(image_ycbcr);
    ycbcr = zeros(1,height*width*channels);
    
    i = 1;
    for row=1 : height
        for col=1 : width
            ycbcr(i) = image_ycbcr(row,col,1);
            i = i+1;
            ycbcr(i) = image_ycbcr(row,col,2);
            i = i+1;
            ycbcr(i) = image_ycbcr(row,col,3);
            i = i+1;
        end
    end
    
    %rgb(1:64)
    
end



