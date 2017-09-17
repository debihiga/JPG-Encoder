% https://digitalexploration.wordpress.com/2009/11/17/jpeg-header-definitions/
% SOF: Start Of Frame.
% This is a marker to indicate the start of a frame. There can be only one.
function out = writeSOF(out, width, height)
    out = writeWord(out, hex2dec('FFC0'));      % SOF marker.
    out = writeWord(out, 17);                   % Length of data.
    out = writeByte(out, 8);                    % Data precision.
    out = writeWord(out, height);               % Image height in pixels.
    out = writeWord(out, width);                % Image width in pixels.
    out = writeByte(out, 3);                    % N components.
    out = writeByte(out, 1);                    % Component 1 id: 1 (Y)
    out = writeByte(out, hex2dec('11'));        % Component 1 horizontal and vertical sampling (HVY)
    out = writeByte(out, 0);                    % Component 1 quantization table id (QTY) - see DQT.
    out = writeByte(out, 2);                    % Component 2 id: 2 (Cb)
    out = writeByte(out, hex2dec('11'));        % Component 2 horizontal and vertical sampling (HVCb)
    out = writeByte(out, 1);                    % Component 2 quantization table id (QTCb) - see DQT.
    out = writeByte(out, 3);                    % Component 3 id: 3 (Cr)
    out = writeByte(out, hex2dec('11'));        % Component 3 horizontal and vertical sampling (HVCr)
    out = writeByte(out, 1);                    % Component 3 quantization table id (QTCr) - see DQT.
end
