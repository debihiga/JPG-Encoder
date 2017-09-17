% https://digitalexploration.wordpress.com/2009/11/17/jpeg-header-definitions/
% http://dev.exiv2.org/projects/exiv2/wiki/The_Metadata_in_JPEG_files
% APPn: APPlication specific.
% Not to be confused with comments, 
% this marker identifies applications information that 
% is not defined in the official standard.
% The APP0 marker is special however and 
% holds information specific to the JFIF and EXIF implementations of the jpeg. 
% From what I can tell the jpeg standard was too vague so 
% some guy came up with the JFIF standard and it stuck, 
% EXIF is newer but definitely sticking, 
% especially with digital cameras. 
function out = writeAPP0(out)
    out = writeWord(out, hex2dec('FFE0')); % APP0 marker.
    out = writeWord(out, 16);              % Length of data.
    out = writeByte(out, hex2dec('4A'));   % J              |
    out = writeByte(out, hex2dec('46'));   % F              |_ Identifier
    out = writeByte(out, hex2dec('49'));   % I              |
    out = writeByte(out, hex2dec('46'));   % F              |
    out = writeByte(out, 0);               % = "JFIF",'\0'  |
    out = writeByte(out, 1);               % Major revisions. |_ Version
    out = writeByte(out, 1);               % Minor revisions. |
    out = writeByte(out, 0);               % Units (0: no units, X and Y specify the pixel aspect ratio)
    out = writeWord(out, 1);               % Xdensity (horizontal pixel density)
    out = writeWord(out, 1);               % Ydensity (vertical pixel density)
    out = writeByte(out, 0);               % Xthumbnail (0: no thumbnail)
    out = writeByte(out, 0);               % Ythumbnail (0: no thumbnail)
end
