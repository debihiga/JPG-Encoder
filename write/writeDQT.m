% https://digitalexploration.wordpress.com/2009/11/17/jpeg-header-definitions/
% DQT: Define Quantization Table.
% This segment defines the Quantization tables to be used. 
% All of the Quantization tables are defined in this one definition.
function out = writeDQT(out, QY, QCbCr)

    out = writeWord(out, hex2dec('FFDB'));  % DQT marker.
    out = writeWord(out, 132);              % Length of data.
    
    out = writeByte(out, 0);                % Identifier (0000: 1 byte per element so 64 bytes per table, 0000: table#0)
    QY_zigzaged = zigzag(QY);               % https://en.wikibooks.org/wiki/JPEG_-_Idea_and_Practice/The_header_part#The_Quantization_table_segment_DQT
    for i=1 : 64
        out = writeByte(out, QY_zigzaged(i));
    end
    
    out = writeByte(out, 1);                % Identifier (0000: 1 byte per element so 64 bytes per table, 0001: table#1)
    QCbCr_zigzaged = zigzag(QCbCr);         % https://en.wikibooks.org/wiki/JPEG_-_Idea_and_Practice/The_header_part#The_Quantization_table_segment_DQT
    for i=1 : 64
        out = writeByte(out, QCbCr_zigzaged(i));
    end
    
end
