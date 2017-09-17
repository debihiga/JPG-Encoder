
function [QT_Y, QT_CbCr, ZigZag] = initQT(quality)

    scale_factor = getScaleFactor(quality);

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

    
    Q1 = [
        16  11  10  16  24  40  51  61 ...
        12  12  14  19  26  58  60  55 ...
        14  13  16  24  40  57  69  56 ...
        14  17  22  29  51  87  80  62 ...
        18  22  37  56  68  109 103 77 ...
        24  35  55  64  81  104 113 92 ...
        49  64  78  87  103 121 120 101 ...
        72  92  95  98  112 100 103 99
        ];
    QT_Y = zeros(1,64);   
    for i=1 : 64   
        t = floor((Q1(i)*scale_factor+50)/100);
        if t < 1
            t = 1;
        elseif t > 255
            t = 255;
        end
        QT_Y(ZigZag(i)) = t;
        %QY(i) = t; se ve peor
    end

    Q2 = [
        17  18  24  47  99  99  99  99 ...
        18  21  26  66  99  99  99  99 ...
        24  26  56  99  99  99  99  99 ...
        47  66  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99 ...
        99  99  99  99  99  99  99  99
        ];
    QT_CbCr = zeros(1,64);
    for i=1 : 64
        t = floor((Q2(i)*scale_factor+50)/100);
        if t < 1
            t = 1;
        elseif t > 255
            t = 255;
        end    
        QT_CbCr(ZigZag(i)) = t;
        %QT_CbCr(i) = t; se ve peor
    end
        
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

function array = add1ToArray(array)
    [rows, cols] = size(array);
    for i=1 : cols
        array(i) = array(i) + 1;
    end
    % MATLAB empieza los indices con 1... asi que tengo que sumarle a todo
    % un 1.
end