function [out] = writeBits(out, data)

    persistent byte_new;
    persistent byte_pos;
    
    if nargin==0
        byte_new = 0;
        byte_pos = 7;
        out = [];
    else
        bit_new = data(1);
        bit_pos = data(2)-1;
        while( bit_pos >= 0 )
            if( bitand(bit_new, bitsll(1,bit_pos)) )
                byte_new = bitor(byte_new, bitsll(1, byte_pos));
            end
            bit_pos = bit_pos-1;
            byte_pos = byte_pos-1;
            if(byte_pos < 0)
                if(byte_new == hex2dec('FF'))
                    out = writeByte(out, hex2dec('FF'));
                    out = writeByte(out, 0);
                    % If the huffman coding scheme needed to write a 0xFF byte, then it writes a 0xFF followed by a 0x00 -- a process known as adding a stuff byte.
                else
                    out = writeByte(out, byte_new);
                end
                byte_new = 0;
                byte_pos = 7;
            end
        end    
    end
end

