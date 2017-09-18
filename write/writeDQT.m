% https://digitalexploration.wordpress.com/2009/11/17/jpeg-header-definitions/
% DQT: Define Quantization Table.
% This segment defines the Quantization tables to be used. 
% All of the Quantization tables are defined in this one definition.
function out = writeDQT(out, QY, QCbCr)

    out = writeWord(out, hex2dec('FFDB'));  % DQT marker.
    out = writeWord(out, 132);              % Length of data.
    
    out = writeByte(out, 0);                % Identifier (0000: 1 byte per element so 64 bytes per table, 0000: table#0)
    for r=1 : 8
        for c=1 : 8
            out = writeByte(out, QY(r,c));
        end
    end
    
    out = writeByte(out, 1);                % Identifier (0000: 1 byte per element so 64 bytes per table, 0001: table#1)
    for r=1 : 8
        for c=1 : 8
            out = writeByte(out, QCbCr(r,c));
        end
    end
    
end
