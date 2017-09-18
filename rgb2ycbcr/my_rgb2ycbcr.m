function ycbcr = my_rgb2ycbcr(rgb)
% http://what-when-how.com/introduction-to-video-and-image-processing/conversion-between-rgb-and-yuvycbcr-introduction-to-video-and-image-processing/
%     ycbcr = rgb2ycbcr(rgb);
    [height, width, channels] = size(rgb);
    ycbcr = zeros(height, width, channels, 'double');   
    for r=1 : height
        for c=1 : width
            ycbcr(r,c,1) = (( 0.29900)*double(rgb(r,c,1))+( 0.58700)*double(rgb(r,c,2))+( 0.11400)*double(rgb(r,c,3)))-128; %-0x80
            ycbcr(r,c,2) =  (-0.16874)*double(rgb(r,c,1))+(-0.33126)*double(rgb(r,c,2))+( 0.50000)*double(rgb(r,c,3));
            ycbcr(r,c,3) =  ( 0.50000)*double(rgb(r,c,1))+(-0.41869)*double(rgb(r,c,2))+(-0.08131)*double(rgb(r,c,3));
        end
    end
end