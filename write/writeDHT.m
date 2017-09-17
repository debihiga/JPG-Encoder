% https://digitalexploration.wordpress.com/2009/11/17/jpeg-header-definitions/
% DHT: Define Huffman Table.
% This segment defines the Huffman tables to be used to decompress the jpeg data. 
%
% (1) Number of values for each bit length (16 bytes)
% The position of each byte represents the bit length of the Huffman table and 
% each byte value is the number of values for that bit length. 
% For example, if the data is 0x000105 then there will be 
% 0 values with a bit length of 1, 
% 1 value with a bit length of 2 and 
% 5 values with a bit length of 3.  
%
% (2) Actual values (*Sum of values above* bytes)
% Length is equal to the sum of the values in (1). 
% So for the example above 0x000105 would translate to 6 bytes.
function out = writeDHT(out, ht_y_dc_nvalues, ht_y_dc_values, ... 
                             ht_y_ac_nvalues, ht_y_ac_values, ...
                             ht_cbcr_dc_nvalues, ht_cbcr_dc_values, ... 
                             ht_cbcr_ac_nvalues, ht_cbcr_ac_values)

    out = writeWord(out, hex2dec('FFC4'));  % DHT marker.
    out = writeWord(out, hex2dec('1A2'));   % Length of data.

    out = writeByte(out, 0);                % Table identifier (0000: DC, 0000: Y)
    for i=1 : 16                            % Number of values for each bit lenght (see 1)
        out = writeByte(out, ht_y_dc_nvalues(i+1));
    end
    for i=1 : 12                            % Actual values (see 2)
        out = writeByte(out, ht_y_dc_values(i));
    end
    
    out = writeByte(out, hex2dec('10'));    % Table identifier (0001: AC, 0000: Y)
    for i=1 : 16                            % Number of values for each bit lenght (see 1)
        out = writeByte(out, ht_y_ac_nvalues(i+1));
    end 
    for i=1 : 162                           % Actual values (see 2)
        out = writeByte(out, ht_y_ac_values(i));
    end

    out = writeByte(out, 1);                % Table identifier (0000: DC, 0001: CbCr)
    for i=1 : 16                            % Number of values for each bit lenght (see 1)
        out = writeByte(out, ht_cbcr_dc_nvalues(i+1));
    end
    for i=1 : 12                            % Actual values (see 2)
        out = writeByte(out, ht_cbcr_dc_values(i));
    end
    
    out = writeByte(out, hex2dec('11'));    % Table identifier (0001: AC, 0001: CbCr)
    for i=1 : 16                            % Number of values for each bit lenght (see 1)
        out = writeByte(out, ht_cbcr_ac_nvalues(i+1));
    end
    for i=1 : 162                           % Actual values (see 2)
        out = writeByte(out, ht_cbcr_ac_values(i));
    end
    
end
