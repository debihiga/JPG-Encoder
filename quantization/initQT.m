
function [QT_Y, QT_CbCr] = initQT(quality)

    scale_factor = getScaleFactor(quality);
    
    Q1 = [
        16  11  10  16  24  40  51  61;
        12  12  14  19  26  58  60  55;
        14  13  16  24  40  57  69  56;
        14  17  22  29  51  87  80  62;
        18  22  37  56  68  109 103 77;
        24  35  55  64  81  104 113 92;
        49  64  78  87  103 121 120 101;
        72  92  95  98  112 100 103 99
        ];
    QT_Y = scale(Q1, scale_factor);

    Q2 = [
        17  18  24  47  99  99  99  99;
        18  21  26  66  99  99  99  99;
        24  26  56  99  99  99  99  99;
        47  66  99  99  99  99  99  99;
        99  99  99  99  99  99  99  99;
        99  99  99  99  99  99  99  99;
        99  99  99  99  99  99  99  99;
        99  99  99  99  99  99  99  99
        ];
      QT_CbCr = scale(Q2, scale_factor);
      
end

function scale_factor = getScaleFactor(quality)

    if quality <= 0
        quality = 1;
    elseif quality > 100
        quality = 100;
    end
    
    scale_factor = 0;     % alpha
    
    if quality < 50
        scale_factor = floor(5000 / quality);
    else 
        scale_factor = floor(200 - quality*2);
    end
    
end

function scaled = scale(matrix, factor)
    [height, width] = size(matrix);
    scaled = zeros(height, width);
    for r=1 : height
        for c=1 : width
            t = floor((matrix(r,c)*factor+50)/100);
            if t < 1
                t = 1;
            elseif t > 255
                t = 255;
            end
            scaled(r,c) = t;
        end
    end
end