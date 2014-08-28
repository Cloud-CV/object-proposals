function writeSupplementResultsLatex(ours, geom, ncuts)

gtdir = './figs/supp/gt/';
ourdir = './figs/supp/result/';
ncutdir = './figs/supp/ncut/';
geomdir = './figs/supp/geom/';

nf = numel(ours);

[sval, sind] = sort([ours(:).conservation], 'descend');
ours = ours(sind);
geom = geom(sind);
ncuts = ncuts(sind);

fn = {ours(:).imname};

outname = './results/suppfig.tex';

fid = fopen(outname, 'w');
for f = 1:nf
    
    if mod(f-1, 6)==0
        fprintf(fid, '\\begin{figure*} \n');
        fprintf(fid, '\\begin{center} \n');                
        fprintf(fid, '\\begin{tabular}{cccc}\n');
    end
    
    fprintf(fid, '\\includegraphics[clip=true,trim=1in 3in 1in 3in, height=1.2in]');
    fprintf(fid, ['{' gtdir]); 
    fprintf(fid, [strtok(fn{f}, '.') '_gt.pdf}  &  \\hspace{-.15in} \n ']);
    fprintf(fid, '\\includegraphics[clip=true,trim=1in 3in 1in 3in, height=1.2in]');
    fprintf(fid, ['{' ourdir]); 
    fprintf(fid, [strtok(fn{f}, '.') '_res.pdf} & \\hspace{-.15in} \n ']);
    fprintf(fid, '\\includegraphics[clip=true,trim=1in 3in 1in 3in, height=1.2in]');
    fprintf(fid, ['{' geomdir]); 
    fprintf(fid, [strtok(fn{f}, '.') '_res.pdf} & \\hspace{-.15in} \n ']);
    fprintf(fid, '\\includegraphics[clip=true,trim=1in 3in 1in 3in, height=1.2in]');
    fprintf(fid, ['{' ncutdir]); 
    fprintf(fid, [strtok(fn{f}, '.') '_res.pdf} \\\\ \n']);    
    fprintf(fid, ['Gt: (%.2f, %.2f) & Ours: (%.2f,%.2f) & Geom: (%.2f,%.2f) & Ncuts: (%.2f,%.2f) \\\\ \n'], ...
       0, 1, ours(f).efficiency, ours(f).conservation, ...
       geom(f).efficiency, geom(f).conservation, ncuts(f).efficiency, ncuts(f).conservation);

   if (mod(f, 6)==0 || f==nf)
        fprintf(fid, '\\end{tabular} \n');
        fprintf(fid, '\\end{center} \n');                
        %fprintf(fid, '\\caption{}\n');
        fprintf(fid, '\\end{figure*}\n');
    end
end
fclose(fid);



