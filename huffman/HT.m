% https://web.stanford.edu/class/ee398a/handouts/lectures/08-JPEG.pdf
HT_Y_DC_NVALUES = [0 0 1 5 1 1 1 1 1 1 0 0 0 0 0 0 0];
% Code lenght   #
% 0             0
% 1             0
% 2             1
% 3             5
% 4             1
% etc...

HT_Y_DC_VALUES = [0 1 2 3 4 5 6 7 8 9 10 11];

% HT_Y_DC =
% code word     code length
%      0        2
%      2        3
%      3        3
%      4        3
%      5        3
%      6        3
%     14        4
%     30        5
%     62        6
%    126        7
%    254        8
%    510        9

HT_Y_AC_NVALUES = [0 0 2 1 3 3 2 4 3 5 5 4 4 0 0 1 hex2dec('7d')];
HT_Y_AC_VALUES = [
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

% YAC_HT =
% 
%           10           4

%            0           2
%            1           2
%            4           3
%           11           4
%           26           5
%          120           7
%          248           8
%         1014          10
%        65410          16
%        65411          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%           12           4
%           27           5
%          121           7
%          502           9
%         2038          11
%        65412          16
%        65413          16
%        65414          16
%        65415          16
%        65416          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%           28           5
%          249           8
%         1015          10
%         4084          12
%        65417          16
%        65418          16
%        65419          16
%        65420          16
%        65421          16
%        65422          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%           58           6
%          503           9
%         4085          12
%        65423          16
%        65424          16
%        65425          16
%        65426          16
%        65427          16
%        65428          16
%        65429          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%           59           6
%         1016          10
%        65430          16
%        65431          16
%        65432          16
%        65433          16
%        65434          16
%        65435          16
%        65436          16
%        65437          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%          122           7
%         2039          11
%        65438          16
%        65439          16
%        65440          16
%        65441          16
%        65442          16
%        65443          16
%        65444          16
%        65445          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%          123           7
%         4086          12
%        65446          16
%        65447          16
%        65448          16
%        65449          16
%        65450          16
%        65451          16
%        65452          16
%        65453          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%          250           8
%         4087          12
%        65454          16
%        65455          16
%        65456          16
%        65457          16
%        65458          16
%        65459          16
%        65460          16
%        65461          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%          504           9
%        32704          15
%        65462          16
%        65463          16
%        65464          16
%        65465          16
%        65466          16
%        65467          16
%        65468          16
%        65469          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%          505           9
%        65470          16
%        65471          16
%        65472          16
%        65473          16
%        65474          16
%        65475          16
%        65476          16
%        65477          16
%        65478          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%          506           9
%        65479          16
%        65480          16
%        65481          16
%        65482          16
%        65483          16
%        65484          16
%        65485          16
%        65486          16
%        65487          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%         1017          10
%        65488          16
%        65489          16
%        65490          16
%        65491          16
%        65492          16
%        65493          16
%        65494          16
%        65495          16
%        65496          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%         1018          10
%        65497          16
%        65498          16
%        65499          16
%        65500          16
%        65501          16
%        65502          16
%        65503          16
%        65504          16
%        65505          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%         2040          11
%        65506          16
%        65507          16
%        65508          16
%        65509          16
%        65510          16
%        65511          16
%        65512          16
%        65513          16
%        65514          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%        65515          16
%        65516          16
%        65517          16
%        65518          16
%        65519          16
%        65520          16
%        65521          16
%        65522          16
%        65523          16
%        65524          16
%            0           0
%            0           0
%            0           0
%            0           0
%            0           0
%         2041          11
%        65525          16
%        65526          16
%        65527          16
%        65528          16
%        65529          16
%        65530          16
%        65531          16
%        65532          16
%        65533          16
%        65534          16

% file:///C:/Users/Debi/Downloads/P14AB08_JPEG_ALGORITH_BASELINE_ON_EMBEDDED_SYSTEMS.pdf
% HT_CBCR_DC =
% 
%            0           2
%            1           2
%            2           2
%            6           3
%           14           4
%           30           5
%           62           6
%          126           7
%          254           8
%          510           9
%         1022          10
%         2046          11
