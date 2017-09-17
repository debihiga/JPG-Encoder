function out = writeWord(out, value)
    
    msb = bitand(floor(bitsra(value,8)), hex2dec('FF'));    % (value>>8)&0xFF
    lsb = bitand(value, hex2dec('FF'));                     % value&0xFF
    
    out = writeByte(out, msb);
    out = writeByte(out, lsb);
end