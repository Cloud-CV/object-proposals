%% Compile RP mex file
function setupRandomizedPrim(rppath)
	mexDir = 'cmex';
	mexDir = (fullfile(rppath, mexDir))

	if(exist(mexDir, 'dir') ~= 0)
	 [~,~,~]= rmdir(mexDir, 's');
	end
	mkdir (rppath, 'cmex')
        currDir = pwd;
	disp('Compiling RP mex file...');

	% Release:
	eval(sprintf('mex %s %s -outdir %s', fullfile(rppath, 'src/RP_mex.cpp'),fullfile(rppath, 'src/stopwatch/Stopwatch.cpp'), mexDir));
	% Debug:
	% mex -g fullpath(rppath, 'src/RP_mex.cpp') fullpath(rppath, '/src/stopwatch/Stopwatch.cpp') -outdir mexDir
	

	%% Generate configuration files:
	currDir = pwd;

	disp('Generating configuration files...');
	GenerateRPConfig(rppath);
	GenerateRPConfig_4segs(rppath);
end
