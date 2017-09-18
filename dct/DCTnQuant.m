function dct_quant = DCTnQuant(block, QT) 

    dct_quant = round(dct2(block)./QT);
    
end