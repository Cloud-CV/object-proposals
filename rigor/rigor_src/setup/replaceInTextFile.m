function replaceInTextFile(filepath, re_file, replace_txt, dir_rpl_txt)
% Replaces text in a file via regexp, and then writes it to disk
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

fd = fopen(filepath, 'r');
str = fread(fd);
str = char(str');
% str = str{1};
% str = cellfun(@(x) sprintf('%s\n', x), str, 'UniformOutput',false);
% str = horzcat(str{:});
fclose(fd);

if exist('dir_rpl_txt','var') && dir_rpl_txt
    replace_txt = strrep(replace_txt, '\', '\\');
end
str = regexprep(str, re_file, replace_txt);
fd = fopen(filepath, 'w');
fprintf(fd, '%s', str);
fclose(fd);
end