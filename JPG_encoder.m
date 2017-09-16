% filename -> .tiff image.
function JPG_encoder(filename, quality)
    
    close all;
    
    init();
    image = imread(filename);
    encode(image, quality);
    
end

function encode(image, quality)

    setQuality(quality);

    % Initialize bit writer
    global byteout
    byteout = [];
    global bytenew
    bytenew = 0;
    global bytepos
    bytepos = 7;

    % Add JPEG headers
    writeWord(hex2dec('FFD8')); % SOI
    writeAPP0();
    writeDQT();

    [height, width, channels] = size(image);
    writeSOF0(width, height);
    writeDHT();
    writeSOS();
    
    % Encode 8x8 macroblocks
    DCY = 0;
    DCU = 0;
    DCV = 0; 
    % creo que son global
    bytenew = 0;
    bytepos = 7;

    quadWidth = width*4;
    tripleWidth = width*3;

    y = 0;

    rgb = generateRGB(image);
    ycbcr = generateYCbCr(image);
    global RGB_YUV_TABLE
    
    global fdtbl_Y
    global fdtbl2_Y
    global YDC_HT
    global YAC_HT            
    
    global fdtbl_UV
    global fdtbl2_UV
    global UVDC_HT
    global UVAC_HT
                     
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

                r = rgb(p+1);
                YDU(pos+1) = ycbcr(p+1) - 121;  % Por alguna razon, les tengo que restar este valor. Sino no da como el original.
%                 if(n_blocks==0)
%                     YDU2
%                 end
                p = p+1;
                g = rgb(p+1);
                UDU(pos+1) = ycbcr(p+1) - 131;
%                 if(n_blocks==0)
%                     UDU2
%                 end
                p = p+1;
                b = rgb(p+1);
                VDU(pos+1) = ycbcr(p+1) - 122;
%                 if(n_blocks==88)
%                     VDU2
%                 end
                p = p+1;

                % use lookup table (slightly faster)
%                 YDU(pos+1) = floor(bitsra((RGB_YUV_TABLE(r+1)      + RGB_YUV_TABLE(g+256+1)  + RGB_YUV_TABLE(b+512+1)),16))-128;
%                 if(n_blocks==0)
%                     YDU
%                 end
%                 UDU(pos+1) = floor(bitsra((RGB_YUV_TABLE(r+768+1)  + RGB_YUV_TABLE(g+1024+1) + RGB_YUV_TABLE(b+1280+1)),16))-128;
%                 if(n_blocks==0)
%                     UDU
%                 end                
%                 VDU(pos+1) = floor(bitsra((RGB_YUV_TABLE(r+1280+1) + RGB_YUV_TABLE(g+1536+1) + RGB_YUV_TABLE(b+1792+1)),16))-128;
%                 if(n_blocks==88)
%                     VDU
%                 end 
%                 
%                 YDU(pos+1) = floor(ycbcr(p+1));
%                 p = p+1;
%                 UDU(pos+1) = floor(ycbcr(p+1));
%                 p = p+1;
%                 VDU(pos+1) = floor(ycbcr(p+1));
%                 p = p+1;

            end

            %if(x==48 && y==16) 
            %    YDU
            %end
            
            
            DCY = processDU(YDU, fdtbl2_Y, DCY, YDC_HT, YAC_HT);
            DCU = processDU(UDU, fdtbl2_Y, DCU, UVDC_HT, UVAC_HT);
            DCV = processDU(VDU, fdtbl2_Y, DCV, UVDC_HT, UVAC_HT);

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
        writeBits(fillbits);
    end

    writeWord(hex2dec('FFD9')); % EOI (End of Image)
    
    fileID = fopen('test.jpg','w');
    fwrite(fileID,byteout);
    fclose(fileID);
    %byteout
end

%
% DCY = processDU(YDU, fdtbl_Y, DCY, YDC_HT, YAC_HT);
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

    Diff = DU(1) - DC;
    DC = DU(1);

    
%     if(n_blocks==0)
%         n_blocks
%         Diff
%         DC
%     end
    
    % Encode DC
    global category
    global bitcode
    if(Diff==0) 
        writeBits(HTDC(1,:)); % Diff might be 0
    else
        pos = 32767+Diff;
        writeBits(HTDC(category(pos+1)+1,:));
        writeBits(bitcode(pos+1,:));
    end

    % Encode ACs
    end0pos = 63;       % was const... which is crazy
    while( (end0pos>0)&&(DU(end0pos+1)==0) )
        end0pos = end0pos-1;
    end
    %end0pos = first element in reverse order !=0
    global byteout
    global bytepos
    global bytenew
    if( end0pos == 0) 
%         if(n_blocks==0)
%             bytepos
%             bytenew
%         end
            
        writeBits(EOB);
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
                writeBits(M16zeroes);
            end
            nrzeroes = bitand(nrzeroes, hex2dec('F'));
        end
        pos = 32767+DU(i+1);
        writeBits(HTAC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:));
%         if(n_blocks==53)
%             HTAC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:)
%             bitcode(pos+1,:)
%         end
        writeBits(bitcode(pos+1,:));
        i = i+1;
    end
    if( end0pos~=I63 )
        writeBits(EOB);
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

function outputfDCTQuant = fDCTQuant(data, fdtbl)
       
    % https://www.nayuki.io/res/fast-discrete-cosine-transform-algorithms/FastDct.js
    % Pass 1: process rows.
    dataOff = 1;
    I8 = 8;
    I64 = 64;

    for i=0 : I8-1

        d0 = data(dataOff); 
        d1 = data(dataOff+1); 
        d2 = data(dataOff+2); 
        d3 = data(dataOff+3); 
        d4 = data(dataOff+4); 
        d5 = data(dataOff+5); 
        d6 = data(dataOff+6); 
        d7 = data(dataOff+7);

        tmp0 = d0 + d7;
        tmp7 = d0 - d7; 
        tmp1 = d1 + d6;
        tmp6 = d1 - d6; 
        tmp2 = d2 + d5; 
        tmp5 = d2 - d5; 
        tmp3 = d3 + d4; 
        tmp4 = d3 - d4;

        % Even part
        tmp10 = tmp0 + tmp3;            % phase 2
        tmp13 = tmp0 - tmp3; 
        tmp11 = tmp1 + tmp2;
        tmp12 = tmp1 - tmp2;

        data(dataOff) = tmp10 + tmp11;      % phase 3 
        data(dataOff+4) = tmp10 - tmp11;

        z1 = (tmp12 + tmp13) * 0.707106781; % c4
        data(dataOff+2) = tmp13 + z1;       % phase 5
        data(dataOff+6) = tmp13 - z1;

        % Odd part 
        tmp10 = tmp4 + tmp5;                % phase 2 
        tmp11 = tmp5 + tmp6; 
        tmp12 = tmp6 + tmp7;

        % The rotator is modified from fig 4-8 to avoid extra negations.
        z5 = (tmp10 - tmp12) * 0.382683433; % c6
        z2 = 0.541196100 * tmp10 + z5;      % c2-c6 
        z4 = 1.306562965 * tmp12 + z5;      % c2+c6
        z3 = tmp11 * 0.707106781;           % c4

        z11 = tmp7 + z3;                    % phase 5 
        z13 = tmp7 - z3;

        data(dataOff+5) = z13 + z2;         % phase 6
        data(dataOff+3) = z13 - z2; 
        data(dataOff+1) = z11 + z4;
        data(dataOff+7) = z11 - z4;

        dataOff = dataOff+8;                       % advance pointer to next row
    end

%     global n_blocks
%     if(n_blocks==672)
%         data
%     end
    
    % Pass 2: process columns. 
    dataOff = 1;
    for i=0 : I8-1

        d0 = data(dataOff);
        d1 = data(dataOff + 8);
        d2 = data(dataOff + 16);
        d3 = data(dataOff + 24);
        d4 = data(dataOff + 32);
        d5 = data(dataOff + 40);
        d6 = data(dataOff + 48);
        d7 = data(dataOff + 56);

        tmp0p2 = d0 + d7;
        tmp7p2 = d0 - d7;
        tmp1p2 = d1 + d6;
        tmp6p2 = d1 - d6;
        tmp2p2 = d2 + d5;
        tmp5p2 = d2 - d5;
        tmp3p2 = d3 + d4;
        tmp4p2 = d3 - d4;

        % Even part
        tmp10p2 = tmp0p2 + tmp3p2;                  % phase 2 
        tmp13p2 = tmp0p2 - tmp3p2;
        tmp11p2 = tmp1p2 + tmp2p2;
        tmp12p2 = tmp1p2 - tmp2p2;

        data(dataOff) = tmp10p2 + tmp11p2;          % phase 3 
        data(dataOff+32) = tmp10p2 - tmp11p2;

        z1p2 = (tmp12p2 + tmp13p2) * 0.707106781;   % c4 
        data(dataOff+16) = tmp13p2 + z1p2;          % phase 5 
        data(dataOff+48) = tmp13p2 - z1p2;

        % Odd part
        tmp10p2 = tmp4p2 + tmp5p2;                  % phase 2
        tmp11p2 = tmp5p2 + tmp6p2;
        tmp12p2 = tmp6p2 + tmp7p2;

        % The rotator is modified from fig 4-8 to avoid extra negations. 
        z5p2 = (tmp10p2 - tmp12p2) * 0.382683433;   % c6 
        z2p2 = 0.541196100 * tmp10p2 + z5p2;        % c2-c6 
        z4p2 = 1.306562965 * tmp12p2 + z5p2;        % c2+c6 
        z3p2 = tmp11p2 * 0.707106781;               % c4 
        z11p2 = tmp7p2 + z3p2;                      % phase 5
        z13p2 = tmp7p2 - z3p2;

        data(dataOff+40) = z13p2 + z2p2;            % phase 6
        data(dataOff+24) = z13p2 - z2p2;
        data(dataOff+ 8) = z11p2 + z4p2;
        data(dataOff+56) = z11p2 - z4p2;

        dataOff = dataOff+1;                        % advance pointer to next column
    
    end
    
%     global n_blocks
%     if(n_blocks==672)
%         data
%     end
    
    
    % Quantize/descale the coefficients
    outputfDCTQuant = zeros(1,64);
    for i=0 : I64-1
    
        % Apply the quantization and scaling factor & Round to nearest integer
        fdctquant = data(i+1)*fdtbl(i+1);
        if (fdctquant > 0.0)
            outputfDCTQuant(i+1) = floor(fdctquant+0.5);
        else
            outputfDCTQuant(i+1) = ceil(fdctquant-0.5);
        end
        %outputfDCTQuant(i] = fround(fdctquant);

    end
    
%     global n_blocks
%     if(n_blocks==672)
%         outputfDCTQuant
%     end
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

function rgb = generateRGB(image)

    [height, width, channels] = size(image);
    rgb = zeros(1,height*width*channels);
    
    i = 1;
    for row=1 : height
        for col=1 : width
            rgb(i) = image(row,col,1);
            i = i+1;
            rgb(i) = image(row,col,2);
            i = i+1;
            rgb(i) = image(row,col,3);
            i = i+1;
        end
    end
    
    %rgb(1:64)
    
end

function setQuality(quality)

    if quality <= 0
        quality = 1;
    elseif quality > 100
        quality = 100;
    end
    
    sf = 0;     % alpha
    
    if quality < 50
        sf = floor(5000 / quality);
    else 
        sf = floor(200 - quality*2);
    end
        
    initQuantTables(sf);

    %fprintf('quality: %d\n', quality)
end

function array = add1ToArray(array)
    [rows, cols] = size(array);
    for i=1 : cols
        array(i) = array(i) + 1;
    end
    % MATLAB empieza los indices con 1... asi que tengo que sumarle a todo
    % un 1.
end

function initQuantTables(sf)

    % Q1
    YQT = [
        16  11  10  16  24  40  51  61 ...
        12  12  14  19  26  58  60  55 ...
        14  13  16  24  40  57  69  56 ...
        14  17  22  29  51  87  80  62 ...
        18  22  37  56  68  109 103 77 ...
        24  35  55  64  81  104 113 92 ...
        49  64  78  87  103 121 120 101 ...
        72  92  95  98  112 100 103 99
        ];
    
    global YTable
    YTable = zeros(1,64);
    
    global ZigZag
    ZigZag = [
        0   1   5   6   14  15  27  28 ...
        2   4   7   13  16  26  29  42 ...
        3   8   12  17  25  30  41  43 ...
        9   11  18  24  31  40  44  53 ...
        10  19  23  32  39  45  52  54 ...
        20  22  33  38  46  51  55  60 ...
        21  34  37  47  50  56  59  61 ...
        35  36  48  49  57  58  62  63
        ];
    ZigZag = add1ToArray(ZigZag);
    
    for i=1 : 64
    
        t = floor((YQT(i)*sf+50)/100);
        if t < 1
            t = 1;
        elseif t > 255
            t = 255;
        end
                
        YTable(ZigZag(i)) = t;
    
    end

    % Qc
    UVQT = [
        17  18  24  47  99  99  99  99 ...
        18  21  26  66  99  99  99  99 ...
        24  26  56  99  99  99  99  99 ...
        47  66  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99
        ];

    global UVTable
    UVTable = zeros(1,64);

    for i=1 : 64
    
        t = floor((UVQT(i)*sf+50)/100);
        if t < 1
            t = 1;
        elseif t > 255
            t = 255;
        end
                
        UVTable(ZigZag(i)) = t;
    
    end
    
    % https://github.com/briandonahue/FluxJpeg.Core/blob/master/FJCore/FDCT.cs
    % aanScaleFactor 
    % https://github.com/dragon66/icafe/blob/master/src/com/icafe4j/image/util/DCT.java
    aasf = [
        1.0 1.387039845 1.306562965 1.175875602 ...
        1.0 0.785694958 0.541196100 0.275899379
        ];

    global fdtbl_Y
    fdtbl_Y = zeros(1,64);
    global fdtbl_UV
    fdtbl_UV = zeros(1,64);

    k = 1;
   
    for row=1 : 8
    
        for col=1 : 8
        
            fdtbl_Y(k)  = (1.0 / (YTable(ZigZag(k)) * aasf(row) * aasf(col) * 8.0));
            fdtbl_UV(k) = (1.0 / (UVTable(ZigZag(k)) * aasf(row) * aasf(col) * 8.0));
            k = k+1;
        
        end
    
    end

    
    global fdtbl2_Y
    fdtbl2_Y = zeros(1,64);
    global fdtbl2_UV
    fdtbl2_UV = zeros(1,64);

    k = 1;
   
    for row=1 : 8
    
        for col=1 : 8
        
            fdtbl2_Y(k)  = YTable(ZigZag(k));
            fdtbl2_UV(k) = UVTable(ZigZag(k));
            k = k+1;
        
        end
    
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function writeBits(bs)

    global n_blocks

    global bytenew
    global bytepos
    value = bs(1);
    posval = bs(2)-1;
    while( posval >= 0 )
%          if(n_blocks==0)
%              bs
%              value
%              posval
%              bytenew
%              bytepos
%          end
        if( bitand(value, bitsll(1,posval))~=0 )
            bytenew = bitor(bytenew, bitsll(1, bytepos));
        end
%          if(n_blocks==0)
%              bytenew
%          end

        posval = posval-1;
        bytepos = bytepos-1;
        if(bytepos < 0)
            if(bytenew == hex2dec('FF'))
                writeByte(hex2dec('FF'));
                writeByte(0);
            else
%                 if(n_blocks==0)
%                     bytenew
%                 end
                writeByte(bytenew);
            end
            bytepos = 7;
            bytenew = 0;
        end
    end
end

function writeDHT()

    writeWord(hex2dec('FFC4')); % marker
    writeWord(hex2dec('1A2'));  % length

    writeByte(0);               % HTYDCinfo
    
    global std_dc_luminance_nrcodes
    for i=0 : 15
        writeByte(std_dc_luminance_nrcodes(i+1+1));
    end
    global std_dc_luminance_values
    for i=0 : 11
        writeByte(std_dc_luminance_values(i+1));
    end
    
    writeByte(hex2dec('10'));   % HTYACinfo

    global std_ac_luminance_nrcodes
    for i=0 : 15
        writeByte(std_ac_luminance_nrcodes(i+1+1));
    end

    global std_ac_luminance_values
    for i=0 : 161
        writeByte(std_ac_luminance_values(i+1));
    end

    writeByte(1);               % HTUDCinfo
    
    global std_dc_chrominance_nrcodes
    for i=0 : 15
        writeByte(std_dc_chrominance_nrcodes(i+1+1));
    end

    global std_dc_chrominance_values
    for i=0 : 11
        writeByte(std_dc_chrominance_values(i+1));
    end
    
    writeByte(hex2dec('11'));   % HTUACinfo

    global std_ac_chrominance_nrcodes
    for i=0 : 15
        writeByte(std_ac_chrominance_nrcodes(i+1+1));
    end
    
    global std_ac_chrominance_values
    for i=0 : 161
        writeByte(std_ac_chrominance_values(i+1));
    end
    
end

function writeSOS()
    writeWord(hex2dec('FFDA')); % marker (beggining of Start of Scan) 
    writeWord(12);              % length
    writeByte(3);               % nrofcomponents
    writeByte(1);               % IdY
    writeByte(0);               % HTY
    writeByte(2);               % IdU
    writeByte(hex2dec('11'));   % HTU
    writeByte(3);               % IdV
    writeByte(hex2dec('11'));   % HTV
    writeByte(0);               % Ss
    writeByte(hex2dec('3f'));   % Se
    writeByte(0);               % Bf
end

function writeSOF0(width, height)
    writeWord(hex2dec('FFC0'));     % marker
    writeWord(17);                  % length, truecolor YUV JPG
    writeByte(8);                   % precision
    writeWord(height);
    writeWord(width);
    writeByte(3);                   % nrofcomponents
    writeByte(1);                   % IdY
    writeByte(hex2dec('11'));       % HVY
    writeByte(0);                   % QTY
    writeByte(2);                   % IdU
    writeByte(hex2dec('11'));       % HVU
    writeByte(1);                   % QTU
    writeByte(3);                   % IdV
    writeByte(hex2dec('11'));       % HVV
    writeByte(1);                   % QTV
end
    
function writeDQT()

    writeWord(hex2dec('FFDB')); % marker
    writeWord(132);             % length
    writeByte(0);
    
    global YTable
    for i=1: 64
        writeByte(YTable(i));
    end
    
    writeByte(1);
    
    global UVTable
    for i=1 : 64
        writeByte(UVTable(i));
    end
    
end
            
function writeAPP0()
    writeWord(hex2dec('FFE0')); % marker
    writeWord(16);              % length
    writeByte(hex2dec('4A'));   % J
    writeByte(hex2dec('46'));   % F
    writeByte(hex2dec('49'));   % I
    writeByte(hex2dec('46'));   % F
    writeByte(0);               % = "JFIF",'\0'
    writeByte(1);               % versionhi
    writeByte(1);               % versionlo
    writeByte(0);               % xyunits
    writeWord(1);               % xdensity
    writeWord(1);               % ydensity
    writeByte(0);               % thumbnwidth
    writeByte(0);               % thumbnheight
end

% No se usa.
% function initCharLookupTable(){
%     var sfcc = String.fromCharCode;
%     for(var i=0; i < 256; i++){ ///// ACHTUNG // 255
%         clt[i] = sfcc(i);
%     }
% }
        
function writeWord(value)
    writeByte(bitand(floor(bitsra(value,8)), hex2dec('FF')));
    writeByte(bitand(value, hex2dec('FF')));
end

function writeByte(value)
     
    global byteout
    byteout = [byteout, value];  % write char directly instead of converting later
    % A diferencia del codigo en javascript, guardo en decimal y despues al
    % escribir se guarda en char.
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function init()
    % Create tables
    %initCharLookupTable();  % La funcion de Matlab char() hace esto.
    initHuffmanTbl();
    initCategoryNumber();
    initRGBYUVTable();
end

function initHuffmanTbl()
    
    global YDC_HT
    global std_dc_luminance_nrcodes
    global std_dc_luminance_values
    std_dc_luminance_nrcodes = [0 0 1 5 1 1 1 1 1 1 0 0 0 0 0 0 0];
    std_dc_luminance_values = [0 1 2 3 4 5 6 7 8 9 10 11];
    %std_dc_luminance_values = add1ToArray(std_dc_luminance_values);
    YDC_HT = computeHuffmanTbl(std_dc_luminance_nrcodes, std_dc_luminance_values);
    %YDC_HT
    
    global UVDC_HT
    global std_dc_chrominance_nrcodes
    global std_dc_chrominance_values
    std_dc_chrominance_nrcodes = [0 0 3 1 1 1 1 1 1 1 1 1 0 0 0 0 0];
    std_dc_chrominance_values = [0 1 2 3 4 5 6 7 8 9 10 11];
    %std_dc_chrominance_values = add1ToArray(std_dc_chrominance_values);
    UVDC_HT = computeHuffmanTbl(std_dc_chrominance_nrcodes, std_dc_chrominance_values);
    %UVDC_HT

    global YAC_HT
    global std_ac_luminance_nrcodes
    global std_ac_luminance_values
    std_ac_luminance_nrcodes = [0 0 2 1 3 3 2 4 3 5 5 4 4 0 0 1 hex2dec('7d')];
    std_ac_luminance_values = [
            hex2dec('01') hex2dec('02') hex2dec('03') hex2dec('00') hex2dec('04') hex2dec('11') hex2dec('05') hex2dec('12') ...
            hex2dec('21') hex2dec('31') hex2dec('41') hex2dec('06') hex2dec('13') hex2dec('51') hex2dec('61') hex2dec('07') ...
            hex2dec('22') hex2dec('71') hex2dec('14') hex2dec('32') hex2dec('81') hex2dec('91') hex2dec('a1') hex2dec('08') ...
            hex2dec('23') hex2dec('42') hex2dec('b1') hex2dec('c1') hex2dec('15') hex2dec('52') hex2dec('d1') hex2dec('f0') ...
            hex2dec('24') hex2dec('33') hex2dec('62') hex2dec('72') hex2dec('82') hex2dec('09') hex2dec('0a') hex2dec('16') ...
            hex2dec('17') hex2dec('18') hex2dec('19') hex2dec('1a') hex2dec('25') hex2dec('26') hex2dec('27') hex2dec('28') ...
            hex2dec('29') hex2dec('2a') hex2dec('34') hex2dec('35') hex2dec('36') hex2dec('37') hex2dec('38') hex2dec('39') ...
            hex2dec('3a') hex2dec('43') hex2dec('44') hex2dec('45') hex2dec('46') hex2dec('47') hex2dec('48') hex2dec('49') ...
            hex2dec('4a') hex2dec('53') hex2dec('54') hex2dec('55') hex2dec('56') hex2dec('57') hex2dec('58') hex2dec('59') ...
            hex2dec('5a') hex2dec('63') hex2dec('64') hex2dec('65') hex2dec('66') hex2dec('67') hex2dec('68') hex2dec('69') ...
            hex2dec('6a') hex2dec('73') hex2dec('74') hex2dec('75') hex2dec('76') hex2dec('77') hex2dec('78') hex2dec('79') ...
            hex2dec('7a') hex2dec('83') hex2dec('84') hex2dec('85') hex2dec('86') hex2dec('87') hex2dec('88') hex2dec('89') ...
            hex2dec('8a') hex2dec('92') hex2dec('93') hex2dec('94') hex2dec('95') hex2dec('96') hex2dec('97') hex2dec('98') ...
            hex2dec('99') hex2dec('9a') hex2dec('a2') hex2dec('a3') hex2dec('a4') hex2dec('a5') hex2dec('a6') hex2dec('a7') ...
            hex2dec('a8') hex2dec('a9') hex2dec('aa') hex2dec('b2') hex2dec('b3') hex2dec('b4') hex2dec('b5') hex2dec('b6') ...
            hex2dec('b7') hex2dec('b8') hex2dec('b9') hex2dec('ba') hex2dec('c2') hex2dec('c3') hex2dec('c4') hex2dec('c5') ...
            hex2dec('c6') hex2dec('c7') hex2dec('c8') hex2dec('c9') hex2dec('ca') hex2dec('d2') hex2dec('d3') hex2dec('d4') ...
            hex2dec('d5') hex2dec('d6') hex2dec('d7') hex2dec('d8') hex2dec('d9') hex2dec('da') hex2dec('e1') hex2dec('e2') ...
            hex2dec('e3') hex2dec('e4') hex2dec('e5') hex2dec('e6') hex2dec('e7') hex2dec('e8') hex2dec('e9') hex2dec('ea') ...
            hex2dec('f1') hex2dec('f2') hex2dec('f3') hex2dec('f4') hex2dec('f5') hex2dec('f6') hex2dec('f7') hex2dec('f8') ...
            hex2dec('f9') hex2dec('fa')
        ];
    %std_ac_luminance_values = add1ToArray(std_ac_luminance_values);
    YAC_HT = computeHuffmanTbl(std_ac_luminance_nrcodes, std_ac_luminance_values);
    %YAC_HT
    
    global UVAC_HT
    global std_ac_chrominance_nrcodes
    global std_ac_chrominance_values
    std_ac_chrominance_nrcodes = [0 0 2 1 2 4 4 3 4 7 5 4 4 0 1 2 hex2dec('77')];
    std_ac_chrominance_values = [
            hex2dec('00') hex2dec('01') hex2dec('02') hex2dec('03') hex2dec('11') hex2dec('04') hex2dec('05') hex2dec('21') ...
            hex2dec('31') hex2dec('06') hex2dec('12') hex2dec('41') hex2dec('51') hex2dec('07') hex2dec('61') hex2dec('71') ...
            hex2dec('13') hex2dec('22') hex2dec('32') hex2dec('81') hex2dec('08') hex2dec('14') hex2dec('42') hex2dec('91') ...
            hex2dec('a1') hex2dec('b1') hex2dec('c1') hex2dec('09') hex2dec('23') hex2dec('33') hex2dec('52') hex2dec('f0') ...
            hex2dec('15') hex2dec('62') hex2dec('72') hex2dec('d1') hex2dec('0a') hex2dec('16') hex2dec('24') hex2dec('34') ...
            hex2dec('e1') hex2dec('25') hex2dec('f1') hex2dec('17') hex2dec('18') hex2dec('19') hex2dec('1a') hex2dec('26') ...
            hex2dec('27') hex2dec('28') hex2dec('29') hex2dec('2a') hex2dec('35') hex2dec('36') hex2dec('37') hex2dec('38') ...
            hex2dec('39') hex2dec('3a') hex2dec('43') hex2dec('44') hex2dec('45') hex2dec('46') hex2dec('47') hex2dec('48') ...
            hex2dec('49') hex2dec('4a') hex2dec('53') hex2dec('54') hex2dec('55') hex2dec('56') hex2dec('57') hex2dec('58') ...
            hex2dec('59') hex2dec('5a') hex2dec('63') hex2dec('64') hex2dec('65') hex2dec('66') hex2dec('67') hex2dec('68') ...
            hex2dec('69') hex2dec('6a') hex2dec('73') hex2dec('74') hex2dec('75') hex2dec('76') hex2dec('77') hex2dec('78') ...
            hex2dec('79') hex2dec('7a') hex2dec('82') hex2dec('83') hex2dec('84') hex2dec('85') hex2dec('86') hex2dec('87') ...
            hex2dec('88') hex2dec('89') hex2dec('8a') hex2dec('92') hex2dec('93') hex2dec('94') hex2dec('95') hex2dec('96') ...
            hex2dec('97') hex2dec('98') hex2dec('99') hex2dec('9a') hex2dec('a2') hex2dec('a3') hex2dec('a4') hex2dec('a5') ...
            hex2dec('a6') hex2dec('a7') hex2dec('a8') hex2dec('a9') hex2dec('aa') hex2dec('b2') hex2dec('b3') hex2dec('b4') ...
            hex2dec('b5') hex2dec('b6') hex2dec('b7') hex2dec('b8') hex2dec('b9') hex2dec('ba') hex2dec('c2') hex2dec('c3') ...
            hex2dec('c4') hex2dec('c5') hex2dec('c6') hex2dec('c7') hex2dec('c8') hex2dec('c9') hex2dec('ca') hex2dec('d2') ...
            hex2dec('d3') hex2dec('d4') hex2dec('d5') hex2dec('d6') hex2dec('d7') hex2dec('d8') hex2dec('d9') hex2dec('da') ...
            hex2dec('e2') hex2dec('e3') hex2dec('e4') hex2dec('e5') hex2dec('e6') hex2dec('e7') hex2dec('e8') hex2dec('e9') ...
            hex2dec('ea') hex2dec('f2') hex2dec('f3') hex2dec('f4') hex2dec('f5') hex2dec('f6') hex2dec('f7') hex2dec('f8') ...
            hex2dec('f9') hex2dec('fa')
        ];
        %std_ac_chrominance_values = add1ToArray(std_ac_chrominance_values);
        UVAC_HT = computeHuffmanTbl(std_ac_chrominance_nrcodes, std_ac_chrominance_values);
        %UVAC_HT
end

function initCategoryNumber()
    
    global bitcode
    %bitcode = zeros(2,65535);
    bitcode = [];
    global category
    category = zeros(1,65535);
    nrlower = 1;
    nrupper = 2;
    
    for cat=1 : 15
        % Positive numbers
        for nr=nrlower : nrupper-1
            category(32767+nr+1) = cat;
            %bitcode(32767+nr+1) = ();
            bitcode(32767+nr+1,2) = cat;
            bitcode(32767+nr+1,1) = nr;
        end
        % Negative numbers
        for nrneg=-(nrupper-1) : -nrlower
            %if cat==15
            %    nrneg
            %end
            category(32767+nrneg+1) = cat;
            %bitcode(32767+nrneg) = ();
            bitcode(32767+nrneg+1,2) = cat;
            bitcode(32767+nrneg+1,1) = nrupper-1+nrneg;
        end
        %nrlower = nrlower*2;
        nrlower = bitsll(nrlower,1);
        %nrupper = nrupper*2;
        nrupper = bitsll(nrupper,1);
    end
    
%     category(1)
%     category(32769)
%     bitcode(1,:)
%     bitcode(32769,:)

end

function initRGBYUVTable()

    global RGB_YUV_TABLE
    RGB_YUV_TABLE = zeros(1,2048);
    for i=0 : 255
        RGB_YUV_TABLE(i+1)        =  19595 * i;
        RGB_YUV_TABLE(i+1+256)    =  38470 * i;
        RGB_YUV_TABLE(i+1+512)    =   7471 * i + hex2dec('8000');
        RGB_YUV_TABLE(i+1+768)    = -11059 * i;
        RGB_YUV_TABLE(i+1+1024)   = -21709 * i;
        RGB_YUV_TABLE(i+1+1280)   =  32768 * i + hex2dec('807FFF');
        RGB_YUV_TABLE(i+1+1536)   = -27439 * i;
        RGB_YUV_TABLE(i+1+1792)   = - 5329 * i;
    end

    %RGB_YUV_TABLE
end

function HT = computeHuffmanTbl(nrcodes, std_table)
    
    codevalue = 0;
    pos_in_table = 0;
    HT = [];
    
    for i=1 : 16
        for j=1 : nrcodes(i+1)
            %HT(std_table(pos_in_table)) = [];
            HT(std_table(pos_in_table+1)+1, 1) = codevalue; % Sumarle este 1 me arreglo algo...
            HT(std_table(pos_in_table+1)+1, 2) = i;
            pos_in_table = pos_in_table + 1;
            codevalue = codevalue + 1;
        end
        codevalue = codevalue*2;    
    end 
end