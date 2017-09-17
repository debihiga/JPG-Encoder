% https://digitalexploration.wordpress.com/2009/11/17/jpeg-header-definitions/
% SOS: Start Of Scan.
% This is the last header before the compressed image data.
function out = writeSOS(out)
    out = writeWord(out, hex2dec('FFDA')); % SOS marker. 
    out = writeWord(out, 12);              % Length of data.
    out = writeByte(out, 3);               % N components.
    out = writeByte(out, 1);               % Component 1 id (Y)
    out = writeByte(out, 0);               % Component 1 Huffman table id (HTY)
    out = writeByte(out, 2);               % Component 2 id (Cb)
    out = writeByte(out, hex2dec('11'));   % Component 2 Huffman table id (HTCb)
    out = writeByte(out, 3);               % Component 3 id (Cr)
    out = writeByte(out, hex2dec('11'));   % Component 3 Huffman table id (HTCr)
    out = writeByte(out, 0);               % Spectral selection start.
    out = writeByte(out, hex2dec('3f'));   % Spectral selection end.
    out = writeByte(out, 0);               % Successive approximation.
end