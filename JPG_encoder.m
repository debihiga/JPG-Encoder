% filename -> .tiff image.
function JPG_encoder(filename, quality)
    
    close all;
    
    init();
    image = imread(filename);
    encode(image, quality);
    
end

function encode(image, quality)

    setQuality(quality);

    % Initialize bit writer
    global byteout
    byteout = [];
    bytenew = 0;
    bytepos = 7;

    % Add JPEG headers
    writeWord(hex2dec('FFD8')); % SOI
    writeAPP0();
    writeDQT();
    [height, width] = size(image);
    writeSOF0(width, height);
    writeDHT();
    %writeSOS();
    
    fileID = fopen('test.bin','w');
    fwrite(fileID,byteout,'char');
    fclose(fileID);
    
end


% 
%             // Encode 8x8 macroblocks
%             var DCY=0;
%             var DCU=0;
%             var DCV=0;
% 
%             bytenew=0;
%             bytepos=7;
% 
%             this.encode.displayName = "_encode_";
% 
%             var imageData = image.data;
%             var width = image.width;
%             var height = image.height;
% 
%             var quadWidth = width*4;
%             var tripleWidth = width*3;
% 
%             var x, y = 0;
%             var r, g, b;
%             var start,p, col,row,pos;
% 			
% 			
%             while(y < height){
%                 x = 0;
%                 while(x < quadWidth){
% 					start = quadWidth * y + x;
% 					p = start;
% 					col = -1;
% 					row = 0;
% 
% 					for(pos=0; pos < 64; pos++){
% 						row = pos >> 3;// /8
% 						col = ( pos & 7 ) * 4; // %8
% 						p = start + ( row * quadWidth ) + col;
% 
% 						if(y+row >= height){ // padding bottom
% 							p-= (quadWidth*(y+1+row-height));
% 						}
% 
% 						if(x+col >= quadWidth){ // padding right
% 							p-= ((x+col) - quadWidth +4)
% 						}
% 
% 						r = imageData[ p++ ];
% 						g = imageData[ p++ ];
% 						b = imageData[ p++ ];
% 
% 						/* // calculate YUV values dynamically
% 						YDU[pos]=((( 0.29900)*r+( 0.58700)*g+( 0.11400)*b))-128; //-0x80
% 						UDU[pos]=(((-0.16874)*r+(-0.33126)*g+( 0.50000)*b));
% 						VDU[pos]=((( 0.50000)*r+(-0.41869)*g+(-0.08131)*b));
% 						*/
% 
% 						// use lookup table (slightly faster)
% 						YDU[pos] = ((RGB_YUV_TABLE[r]             + RGB_YUV_TABLE[(g +  256)>>0] + RGB_YUV_TABLE[(b +  512)>>0]) >> 16)-128;
% 						UDU[pos] = ((RGB_YUV_TABLE[(r +  768)>>0] + RGB_YUV_TABLE[(g + 1024)>>0] + RGB_YUV_TABLE[(b + 1280)>>0]) >> 16)-128;
% 						VDU[pos] = ((RGB_YUV_TABLE[(r + 1280)>>0] + RGB_YUV_TABLE[(g + 1536)>>0] + RGB_YUV_TABLE[(b + 1792)>>0]) >> 16)-128;
% 
% 					}
% 
% 					DCY = processDU(YDU, fdtbl_Y, DCY, YDC_HT, YAC_HT);
% 					DCU = processDU(UDU, fdtbl_UV, DCU, UVDC_HT, UVAC_HT);
% 					DCV = processDU(VDU, fdtbl_UV, DCV, UVDC_HT, UVAC_HT);
% 					x+=32;
% 					
% 					n_blocks = n_blocks+1;
% 				}
% 				y+=8;
% 			}
% 			console.log(n_blocks);
% 
%             ////////////////////////////////////////////////////////////////
% 
%             // Do the bit alignment of the EOI marker
%             if ( bytepos >= 0 ) {
%                 var fillbits = [];
%                 fillbits[1] = bytepos+1;
%                 fillbits[0] = (1<<(bytepos+1))-1;
%                 writeBits(fillbits);
%             }
% 
%             writeWord(0xFFD9); //EOI
% 
%             if(toRaw) {
%                 var len = byteout.length;
%                 var data = new Uint8Array(len);
% 
%                 for (var i=0; i<len; i++ ) {
%                     data[i] = byteout[i].charCodeAt();
%                 }
% 
%                 //cleanup
%                 byteout = [];
% 
%                 // benchmarking
%                 var duration = new Date().getTime() - time_start;
%                 console.log('Encoding time: '+ duration + 'ms');
% 
%                 return data;
%             }
% 
%             var jpegDataUri = 'data:image/jpeg;base64,' + btoa(byteout.join(''));
% 
%             byteout = [];
% 
%             // benchmarking
%             var duration = new Date().getTime() - time_start;
%             console.log('Encoding time: '+ duration + 'ms');
% 
%             return jpegDataUri
%     }

function init()
    % Create tables
    %initCharLookupTable();  % La funcion de Matlab char() hace esto.
    initHuffmanTbl();
    %initCategoryNumber();
    %initRGBYUVTable();
end

function initHuffmanTbl()
    
    global YDC_HT
    global std_dc_luminance_nrcodes
    global std_dc_luminance_values
    std_dc_luminance_nrcodes = [0 0 1 5 1 1 1 1 1 1 0 0 0 0 0 0 0];
    std_dc_luminance_values = [0 1 2 3 4 5 6 7 8 9 10 11];
    %std_dc_luminance_values = add1ToArray(std_dc_luminance_values);
    YDC_HT = computeHuffmanTbl(std_dc_luminance_nrcodes, std_dc_luminance_values);
    
    global UVDC_HT
    global std_dc_chrominance_nrcodes
    global std_dc_chrominance_values
    std_dc_chrominance_nrcodes = [0 0 3 1 1 1 1 1 1 1 1 1 0 0 0 0 0];
    std_dc_chrominance_values = [0 1 2 3 4 5 6 7 8 9 10 11];
    %std_dc_chrominance_values = add1ToArray(std_dc_chrominance_values);
    UVDC_HT = computeHuffmanTbl(std_dc_chrominance_nrcodes, std_dc_chrominance_values);

    global YAC_HT
    global std_ac_luminance_nrcodes
    global std_ac_luminance_values
    std_ac_luminance_nrcodes = [0 0 2 1 3 3 2 4 3 5 5 4 4 0 0 1 hex2dec('7d')];
    std_ac_luminance_values = [
            hex2dec('01') hex2dec('02') hex2dec('03') hex2dec('00') hex2dec('04') hex2dec('11') hex2dec('05') hex2dec('12') ...
            hex2dec('21') hex2dec('31') hex2dec('41') hex2dec('06') hex2dec('13') hex2dec('51') hex2dec('61') hex2dec('07') ...
            hex2dec('22') hex2dec('71') hex2dec('14') hex2dec('32') hex2dec('81') hex2dec('91') hex2dec('a1') hex2dec('08') ...
            hex2dec('23') hex2dec('42') hex2dec('b1') hex2dec('c1') hex2dec('15') hex2dec('52') hex2dec('d1') hex2dec('f0') ...
            hex2dec('24') hex2dec('33') hex2dec('62') hex2dec('72') hex2dec('82') hex2dec('09') hex2dec('0a') hex2dec('16') ...
            hex2dec('17') hex2dec('18') hex2dec('19') hex2dec('1a') hex2dec('25') hex2dec('26') hex2dec('27') hex2dec('28') ...
            hex2dec('29') hex2dec('2a') hex2dec('34') hex2dec('35') hex2dec('36') hex2dec('37') hex2dec('38') hex2dec('39') ...
            hex2dec('3a') hex2dec('43') hex2dec('44') hex2dec('45') hex2dec('46') hex2dec('47') hex2dec('48') hex2dec('49') ...
            hex2dec('4a') hex2dec('53') hex2dec('54') hex2dec('55') hex2dec('56') hex2dec('57') hex2dec('58') hex2dec('59') ...
            hex2dec('5a') hex2dec('63') hex2dec('64') hex2dec('65') hex2dec('66') hex2dec('67') hex2dec('68') hex2dec('69') ...
            hex2dec('6a') hex2dec('73') hex2dec('74') hex2dec('75') hex2dec('76') hex2dec('77') hex2dec('78') hex2dec('79') ...
            hex2dec('7a') hex2dec('83') hex2dec('84') hex2dec('85') hex2dec('86') hex2dec('87') hex2dec('88') hex2dec('89') ...
            hex2dec('8a') hex2dec('92') hex2dec('93') hex2dec('94') hex2dec('95') hex2dec('96') hex2dec('97') hex2dec('98') ...
            hex2dec('99') hex2dec('9a') hex2dec('a2') hex2dec('a3') hex2dec('a4') hex2dec('a5') hex2dec('a6') hex2dec('a7') ...
            hex2dec('a8') hex2dec('a9') hex2dec('aa') hex2dec('b2') hex2dec('b3') hex2dec('b4') hex2dec('b5') hex2dec('b6') ...
            hex2dec('b7') hex2dec('b8') hex2dec('b9') hex2dec('ba') hex2dec('c2') hex2dec('c3') hex2dec('c4') hex2dec('c5') ...
            hex2dec('c6') hex2dec('c7') hex2dec('c8') hex2dec('c9') hex2dec('ca') hex2dec('d2') hex2dec('d3') hex2dec('d4') ...
            hex2dec('d5') hex2dec('d6') hex2dec('d7') hex2dec('d8') hex2dec('d9') hex2dec('da') hex2dec('e1') hex2dec('e2') ...
            hex2dec('e3') hex2dec('e4') hex2dec('e5') hex2dec('e6') hex2dec('e7') hex2dec('e8') hex2dec('e9') hex2dec('ea') ...
            hex2dec('f1') hex2dec('f2') hex2dec('f3') hex2dec('f4') hex2dec('f5') hex2dec('f6') hex2dec('f7') hex2dec('f8') ...
            hex2dec('f9') hex2dec('fa')
        ];
    %std_ac_luminance_values = add1ToArray(std_ac_luminance_values);
    YAC_HT = computeHuffmanTbl(std_ac_luminance_nrcodes, std_ac_luminance_values);

    global UVAC_HT
    global std_ac_chrominance_nrcodes
    global std_ac_chrominance_values
    std_ac_chrominance_nrcodes = [0 0 2 1 2 4 4 3 4 7 5 4 4 0 1 2 hex2dec('77')];
    std_ac_chrominance_values = [
            hex2dec('00') hex2dec('01') hex2dec('02') hex2dec('03') hex2dec('11') hex2dec('04') hex2dec('05') hex2dec('21') ...
            hex2dec('31') hex2dec('06') hex2dec('12') hex2dec('41') hex2dec('51') hex2dec('07') hex2dec('61') hex2dec('71') ...
            hex2dec('13') hex2dec('22') hex2dec('32') hex2dec('81') hex2dec('08') hex2dec('14') hex2dec('42') hex2dec('91') ...
            hex2dec('a1') hex2dec('b1') hex2dec('c1') hex2dec('09') hex2dec('23') hex2dec('33') hex2dec('52') hex2dec('f0') ...
            hex2dec('15') hex2dec('62') hex2dec('72') hex2dec('d1') hex2dec('0a') hex2dec('16') hex2dec('24') hex2dec('34') ...
            hex2dec('e1') hex2dec('25') hex2dec('f1') hex2dec('17') hex2dec('18') hex2dec('19') hex2dec('1a') hex2dec('26') ...
            hex2dec('27') hex2dec('28') hex2dec('29') hex2dec('2a') hex2dec('35') hex2dec('36') hex2dec('37') hex2dec('38') ...
            hex2dec('39') hex2dec('3a') hex2dec('43') hex2dec('44') hex2dec('45') hex2dec('46') hex2dec('47') hex2dec('48') ...
            hex2dec('49') hex2dec('4a') hex2dec('53') hex2dec('54') hex2dec('55') hex2dec('56') hex2dec('57') hex2dec('58') ...
            hex2dec('59') hex2dec('5a') hex2dec('63') hex2dec('64') hex2dec('65') hex2dec('66') hex2dec('67') hex2dec('68') ...
            hex2dec('69') hex2dec('6a') hex2dec('73') hex2dec('74') hex2dec('75') hex2dec('76') hex2dec('77') hex2dec('78') ...
            hex2dec('79') hex2dec('7a') hex2dec('82') hex2dec('83') hex2dec('84') hex2dec('85') hex2dec('86') hex2dec('87') ...
            hex2dec('88') hex2dec('89') hex2dec('8a') hex2dec('92') hex2dec('93') hex2dec('94') hex2dec('95') hex2dec('96') ...
            hex2dec('97') hex2dec('98') hex2dec('99') hex2dec('9a') hex2dec('a2') hex2dec('a3') hex2dec('a4') hex2dec('a5') ...
            hex2dec('a6') hex2dec('a7') hex2dec('a8') hex2dec('a9') hex2dec('aa') hex2dec('b2') hex2dec('b3') hex2dec('b4') ...
            hex2dec('b5') hex2dec('b6') hex2dec('b7') hex2dec('b8') hex2dec('b9') hex2dec('ba') hex2dec('c2') hex2dec('c3') ...
            hex2dec('c4') hex2dec('c5') hex2dec('c6') hex2dec('c7') hex2dec('c8') hex2dec('c9') hex2dec('ca') hex2dec('d2') ...
            hex2dec('d3') hex2dec('d4') hex2dec('d5') hex2dec('d6') hex2dec('d7') hex2dec('d8') hex2dec('d9') hex2dec('da') ...
            hex2dec('e2') hex2dec('e3') hex2dec('e4') hex2dec('e5') hex2dec('e6') hex2dec('e7') hex2dec('e8') hex2dec('e9') ...
            hex2dec('ea') hex2dec('f2') hex2dec('f3') hex2dec('f4') hex2dec('f5') hex2dec('f6') hex2dec('f7') hex2dec('f8') ...
            hex2dec('f9') hex2dec('fa')
        ];
        %std_ac_chrominance_values = add1ToArray(std_ac_chrominance_values);
        UVAC_HT = computeHuffmanTbl(std_ac_chrominance_nrcodes, std_ac_chrominance_values);
end

function HT = computeHuffmanTbl(nrcodes, std_table)
    
    codevalue = 0;
    pos_in_table = 1;
    HT = [];
    
    for i=2 : 17
        for j=2 : nrcodes(i)+1
            %HT(std_table(pos_in_table)) = [];
            HT(std_table(pos_in_table)+1, 1) = codevalue;
            HT(std_table(pos_in_table)+1, 2) = i;
            pos_in_table = pos_in_table + 1;
            codevalue = codevalue + 1;
        end
        codevalue = codevalue*2;    
    end 
end
        
function writeDHT()

    writeWord(hex2dec('FFC4')); % marker
    writeWord(hex2dec('1A2'));  % length

    writeByte(0);               % HTYDCinfo
    
    global std_dc_luminance_nrcodes
    for i=1 : 16
        writeByte(std_dc_luminance_nrcodes(i+1));
    end
    global std_dc_luminance_values
    for i=1 : 11
        writeByte(std_dc_luminance_values(i));
    end
    
    writeByte(hex2dec('10'));   % HTYACinfo

    global std_ac_luminance_nrcodes
    for i=1 : 16
        writeByte(std_ac_luminance_nrcodes(i+1));
    end

    global std_ac_luminance_values
    for i=1 : 161
        writeByte(std_ac_luminance_values(i));
    end

    writeByte(1);               % HTUDCinfo
    
    global std_dc_chrominance_nrcodes
    for i=1 : 16
        writeByte(std_dc_chrominance_nrcodes(i+1));
    end

    global std_dc_chrominance_values
    for i=1 : 11
        writeByte(std_dc_chrominance_values(i));
    end
    
    writeByte(hex2dec('11'));   % HTUACinfo

    global std_ac_chrominance_nrcodes
    for i=1 : 16
        writeByte(std_ac_chrominance_nrcodes(i+1));
    end
    
    global std_ac_chrominance_values
    for i=1 : 161
        writeByte(std_ac_chrominance_values(i));
    end
    
end

function writeSOF0(width, height)
    writeWord(hex2dec('FFC0'));     % marker
    writeWord(17);                  % length, truecolor YUV JPG
    writeByte(8);                   % precision
    writeWord(height);
    writeWord(width);
    writeByte(3);                   % nrofcomponents
    writeByte(1);                   % IdY
    writeByte(hex2dec('11'));       % HVY
    writeByte(0);                   % QTY
    writeByte(2);                   % IdU
    writeByte(hex2dec('11'));       % HVU
    writeByte(1);                   % QTU
    writeByte(3);                   % IdV
    writeByte(hex2dec('11'));       % HVV
    writeByte(1);                   % QTV
end
    
function writeDQT()

    writeWord(hex2dec('FFDB')); % marker
    writeWord(132);             % length
    writeByte(0);
    
    global YTable
    for i=1: 64
        writeByte(YTable(i));
    end
    
    writeByte(1);
    
    global UVTable
    for i=1 : 64
        writeByte(UVTable(i));
    end
    
end
            
function writeAPP0()
    writeWord(hex2dec('FFE0')); % marker
    writeWord(16);              % length
    writeByte(hex2dec('4A'));   % J
    writeByte(hex2dec('46'));   % F
    writeByte(hex2dec('49'));   % I
    writeByte(hex2dec('46'));   % F
    writeByte(0);               % = "JFIF",'\0'
    writeByte(1);               % versionhi
    writeByte(1);               % versionlo
    writeByte(0);               % xyunits
    writeWord(1);               % xdensity
    writeWord(1);               % ydensity
    writeByte(0);               % thumbnwidth
    writeByte(0);               % thumbnheight
end

% No se usa.
% function initCharLookupTable(){
%     var sfcc = String.fromCharCode;
%     for(var i=0; i < 256; i++){ ///// ACHTUNG // 255
%         clt[i] = sfcc(i);
%     }
% }
        
function writeWord(value)
    writeByte(bitand(floor(bitsra(value,8)), hex2dec('FF')));
    writeByte(bitand(value, hex2dec('FF')));
end

function writeByte(value)
     
    global byteout
    byteout = [byteout, value];  % write char directly instead of converting later
    % A diferencia del codigo en javascript, guardo en decimal y despues al
    % escribir se guarda en char.
    
end

function setQuality(quality)

    if quality <= 0
        quality = 1;
    elseif quality > 100
        quality = 100;
    end
    
    sf = 0;     % alpha
    
    if quality < 50
        sf = floor(5000 / quality);
    else 
        sf = floor(200 - quality*2);
    end
        
    initQuantTables(sf);

    %fprintf('quality: %d\n', quality)
end

function array = add1ToArray(array)
    [rows, cols] = size(array);
    for i=1 : cols
        array(i) = array(i) + 1;
    end
    % MATLAB empieza los indices con 1... asi que tengo que sumarle a todo
    % un 1.
end

function initQuantTables(sf)

    % Q1
    YQT = [
        16  11  10  16  24  40  51  61 ...
        12  12  14  19  26  58  60  55 ...
        14  13  16  24  40  57  69  56 ...
        14  17  22  29  51  87  80  62 ...
        18  22  37  56  68  109 103 77 ...
        24  35  55  64  81  104 113 92 ...
        49  64  78  87  103 121 120 101 ...
        72  92  95  98  112 100 103 99
        ];
    
    global YTable
    YTable = zeros(1,64);
    
    global ZigZag
    ZigZag = [
        0   1   5   6   14  15  27  28 ...
        2   4   7   13  16  26  29  42 ...
        3   8   12  17  25  30  41  43 ...
        9   11  18  24  31  40  44  53 ...
        10  19  23  32  39  45  52  54 ...
        20  22  33  38  46  51  55  60 ...
        21  34  37  47  50  56  59  61 ...
        35  36  48  49  57  58  62  63
        ];
    ZigZag = add1ToArray(ZigZag);
    
    for i=1 : 64
    
        t = floor((YQT(i)*sf+50)/100);
        if t < 1
            t = 1;
        elseif t > 255
            t = 255;
        end
                
        YTable(ZigZag(i)) = t;
    
    end

    % Qc
    UVQT = [
        17  18  24  47  99  99  99  99 ...
        18  21  26  66  99  99  99  99 ...
        24  26  56  99  99  99  99  99 ...
        47  66  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99
        ];

    global UVTable
    UVTable = zeros(1,64);

    for i=1 : 64
    
        t = floor((UVQT(i)*sf+50)/100);
        if t < 1
            t = 1;
        elseif t > 255
            t = 255;
        end
                
        UVTable(ZigZag(i)) = t;
    
    end
    
    aasf = [
        1.0 1.387039845 1.306562965 1.175875602 ...
        1.0 0.785694958 0.541196100 0.275899379
        ];

    global fdtbl_Y
    fdtbl_Y = zeros(1,64);
    global fdtbl_UV
    fdtbl_UV = zeros(1,64);

    k = 1;
   
    for row=1 : 8
    
        for col=1 : 8
        
            fdtbl_Y(k)  = (1.0 / (YTable(ZigZag(k)) * aasf(row) * aasf(col) * 8.0));
            fdtbl_UV(k) = (1.0 / (UVTable(ZigZag(k)) * aasf(row) * aasf(col) * 8.0));
            k = k+1;
        
        end
    
    end

end
