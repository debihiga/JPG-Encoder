function [  QTY, QTCbCr, ZigZag, ...
            YDC_HT,     std_dc_luminance_nrcodes,   std_dc_luminance_values, ...
            YAC_HT,     std_ac_luminance_nrcodes,   std_ac_luminance_values, ...
            UVDC_HT,    std_dc_chrominance_nrcodes, std_dc_chrominance_values, ...
            UVAC_HT,    std_ac_chrominance_nrcodes, std_ac_chrominance_values, ...
            bitcode, category] = init(quality)

    addpath(genpath('/write/'));
    
    % Quantization
    
    addpath(genpath('/quantization/'));
    [QTY, QTCbCr, ZigZag] = initQT(quality);

    % Huffman
    
    addpath(genpath('/huffman/'));    
    [   YDC_HT,     std_dc_luminance_nrcodes,   std_dc_luminance_values, ...
        YAC_HT,     std_ac_luminance_nrcodes,   std_ac_luminance_values, ...
        UVDC_HT,    std_dc_chrominance_nrcodes, std_dc_chrominance_values, ...
        UVAC_HT,    std_ac_chrominance_nrcodes, std_ac_chrominance_values] = initHT();
    
    [bitcode, category] = initCategoryNumber();
end

function [bitcode, category] = initCategoryNumber()
    
    bitcode = [];
    category = zeros(1,65535);
    nrlower = 1;
    nrupper = 2;
    
    for cat=1 : 15
        % Positive numbers
        for nr=nrlower : nrupper-1
            category(32767+nr+1) = cat;
            bitcode(32767+nr+1,2) = cat;
            bitcode(32767+nr+1,1) = nr;
        end
        % Negative numbers
        for nrneg=-(nrupper-1) : -nrlower
            category(32767+nrneg+1) = cat;
            bitcode(32767+nrneg+1,2) = cat;
            bitcode(32767+nrneg+1,1) = nrupper-1+nrneg;
        end
        nrlower = nrlower*2;
        nrupper = nrupper*2;
    end
end