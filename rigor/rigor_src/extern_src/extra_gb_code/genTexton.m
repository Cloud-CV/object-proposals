function map = genTexton(img)

data = load('unitex_6_1_2_1.4_2_64.mat');
[L, ~, ~] = rgb2lab(img);
[fim] = fbRun(data.fb,L);
[map] = assignTextons(fim,data.tex);
