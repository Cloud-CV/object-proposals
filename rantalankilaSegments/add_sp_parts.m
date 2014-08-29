function all_parts = add_sp_parts(sp, sp_list)
% Sp are made of parts of original superpixelation. This function gives the
% list of combined parts of a collection of sp.

all_parts = [];

for i = sp_list
    all_parts = [all_parts, sp{i}.parts]; 
end