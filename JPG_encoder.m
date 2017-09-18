function JPG_encoder(filename, quality)
    
    close all;
    
    global QT_Y
    global QT_CbCr
    
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
    
    [   QT_Y, QT_CbCr, ...
        HT_Y_DC,     HT_Y_DC_NVALUES,   HT_Y_DC_VALUES, ...
        HT_Y_AC,     HT_Y_AC_NVALUES,   HT_Y_AC_VALUES, ...
        HT_CBCR_DC,    HT_CBCR_DC_NVALUES, HT_CBCR_DC_VALUES, ...
        HT_CBCR_AC,    HT_CBCR_AC_NVALUES, HT_CBCR_AC_VALUES, ...
        bitcode, category] = init(quality);
    image = imread(filename);   
    
    % Initialize bit writer
    global output
    output = [];
    global bytenew
    global bytepos
    writeBits(); % init this function's persistent variables.

    % Add JPEG headers
    [height, width, channels] = size(image);
    output = writeWord(output, hex2dec('FFD8')); % SOI
    output = writeAPP0(output);
    output = writeDQT(output, QT_Y, QT_CbCr);
    output = writeSOF(output, width, height);    
    output = writeDHT(output, HT_Y_DC_NVALUES,   HT_Y_DC_VALUES, ...
                                HT_Y_AC_NVALUES,   HT_Y_AC_VALUES, ...
                                HT_CBCR_DC_NVALUES, HT_CBCR_DC_VALUES, ...
                                HT_CBCR_AC_NVALUES, HT_CBCR_AC_VALUES);
    output = writeSOS(output);
    
    ycbcr = my_rgb2ycbcr(image);
                         
    DC_Y = 0;
    DC_Cb = 0;
    DC_Cr = 0;    
    N = 8;
    for r=1 : N : height
        for c=1 : N : width
            DC_Y  = process(ycbcr(r:r+N-1, c:c+N-1, 1), QT_Y,    DC_Y,  HT_Y_DC,    HT_Y_AC);
            DC_Cb = process(ycbcr(r:r+N-1, c:c+N-1, 2), QT_CbCr, DC_Cb, HT_CBCR_DC, HT_CBCR_AC);
            DC_Cr = process(ycbcr(r:r+N-1, c:c+N-1, 3), QT_CbCr, DC_Cr, HT_CBCR_DC, HT_CBCR_AC);
        end
    end
    
    % Do the bit alignment of the EOI marker
    if( bytepos >= 0 )
        fillbits = zeros(1,2);
        fillbits(2) = bytepos+1;
        fillbits(1) = bitsll(bytepos+1,1)-1;
        output = writeBits(output, fillbits);
    end

    output = writeWord(output, hex2dec('FFD9')); % EOI (End of Image)
    
    fileID = fopen('test.jpg','w');
    fwrite(fileID,output);
    fclose(fileID);
end

function DC_new = process(block, QT, DC_last, HT_DC, HT_AC)

    global output
    global category
    global bitcode
    dct_quant = DCTnQuant(block, QT);   
    zigzagged = zigzag(dct_quant);
    [output, DC_new] = huffman(output, zigzagged, DC_last, HT_DC, HT_AC, category, bitcode);
    
end