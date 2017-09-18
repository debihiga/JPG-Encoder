function [output, DCY] = huffman(output, DU, DC, HT_DC, HT_AC, category, bitcode)
    
    M16zeroes = HT_AC(hex2dec('F0')+1,:);
    
    EOB = HT_AC(1,:);
   
    % Encode DC
    % http://www.impulseadventure.com/photo/jpeg-huffman-coding.html
    % https://users.ece.utexas.edu/~ryerraballi/MSB/pdfs/M4L1.pdf
    % http://www.dmi.unict.it/~battiato/EI_MOBILE0708/JPEG%20(Bruna).pdf
    % Differential Pulse Code Modulation (DPCM): 
    % Encode the difference between the current and previous 8x8 block.
    % Example:
    % DC(1) = 4 (actual)
    % DC    = 2 (previous)
    % Diff = DU(1)-DC = 2
    % pos = 32767+Diff = 32769
    % category(pos+1) = 2
    % HT_DC(category(pos+1)+1,:) = [3 3]
    % bitcode(pos+1,:) = [2 2]
     
    Diff = DU(1) - DC;
    DC = DU(1);

    if(Diff==0) 
        output = writeBits(output, HT_DC(1,:)); % Diff might be 0
    else
        pos = 32767+Diff;
        output = writeBits(output, HT_DC(category(pos+1)+1,:));
        output = writeBits(output, bitcode(pos+1,:));
    end
    
    
    % Encode ACs
    end0pos = 63;       % was const... which is crazy
    while( (end0pos>0)&&(DU(end0pos+1)==0) )
        end0pos = end0pos-1;
    end
    %end0pos = first element in reverse order !=0
    if( end0pos == 0) 
        output = writeBits(output, EOB);
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
        if( nrzeroes >= 16 )
            lng = floor(bitsra(nrzeroes,4));
            for nrmarker=1 : lng
                output = writeBits(output, M16zeroes);
            end
            nrzeroes = bitand(nrzeroes, hex2dec('F'));
        end
        pos = 32767+DU(i+1);
        output = writeBits(output, HT_AC(floor(bitsll(nrzeroes,4))+category(pos+1)+1,:));
        output = writeBits(output, bitcode(pos+1,:));
        i = i+1;
    end
    if( end0pos~=63 )
        output = writeBits(output, EOB);
    end
    DCY = DC;

end