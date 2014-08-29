function toolbox_test
% function toolbox_test
%
% This function is used to test the XML Toolbox for Matlab.
%

% Copyright (C) 2002-2005, University of Southampton
% Author: Dr Marc Molinari <m.molinari@soton.ac.uk>
% $Revision: 1.1 $ $Date: 2005/04/15 17:12:14 $ $Tag$

INFO = ver('Matlab');
VER  = str2num(INFO.Version);

N=1; % test index (gets increased with every run)

% =========================================
comm = 'double';
c = -5.789;
dotest(c, N, comm); N=N+1; clear c;

comm='empty double';
c = [];
dotest(c, N, comm); N=N+1; clear c;

comm='double array';
c = [-10:0.75:10];
dotest(c, N, comm); N=N+1; clear c;

comm='double array 2 dim';
c = [-5:5; 10:20];
dotest(c, N, comm); N=N+1; clear c;

comm='double array 3 dim';
c(1,1,:) = [-10:10];
c(2,2,:) = [100:120];
c(3,3,:) = [-1.0:0.1:1];
dotest(c, N, comm); N=N+1; clear c;

comm='large double';
c = 999999999999999;
dotest(c, N, comm); N=N+1; clear c;

comm='small negative double';
c = -0.0000000000001;
dotest(c, N, comm); N=N+1; clear c;

% =========================================
comm='char';
c = 'z';
dotest(c, N, comm); N=N+1; clear c;

comm='empty char';
c = [''];
dotest(c, N, comm); N=N+1; clear c;

comm='single space';
c = [' '];
dotest(c, N, comm); N=N+1; clear c;

comm='several spaces';
c = ['              '];
dotest(c, N, comm); N=N+1; clear c;

comm='non-xml characters, <&''"> with leading and trailing spaces';
c = [' <&''"> '];
dotest(c, N, comm); N=N+1; clear c;

comm='char array / string';
c = 'Hello World! Look out of the window';
dotest(c, N, comm); N=N+1; clear c;

comm='char array / string with leading+trailing space';
c = ' This has a leading and trailing space. ';
dotest(c, N, comm); N=N+1; clear c;

comm='funny ascii characters';
c = 'Funny chars: !$^&*()_+=-@#{}[];:,./\?';
dotest(c, N, comm); N=N+1; clear c;

comm='char array';
c = ['abcdefg'; ...
     'hijklmn'];
dotest(c, N, comm); N=N+1; clear c;

% =========================================
comm='complex';
c = -7.14 + 2.03i;
dotest(c, N, comm); N=N+1; clear c;

comm='pure imaginary';
c = 8i;
dotest(c, N, comm); N=N+1; clear c;

comm='complex array';
a = [-10:0.75:10];
b = [10:-0.75:-10];
c = a+b*i;
dotest(c, N, comm); N=N+1; clear a b c;

comm='complex array 2 dim';
a = [-5:5; 10:20];
b = [-5:5; 10:20];
c = a+b*i;
dotest(c, N, comm); N=N+1; clear a b c;

% =========================================
comm='sparse';
c = sparse(4,5,1);
dotest(c, N, comm); N=N+1; clear c;

comm='empty sparse';
c = sparse(10,7,0);
dotest(c, N, comm); N=N+1; clear c;

comm='complex sparse';
c = sparse(20,40,4+2i);
dotest(c, N, comm); N=N+1; clear c;

% =========================================
comm='empty struct';
if (VER <= 5.3)
  % Matlab up to V. 5.3 does not like empty structs
  c = [];
else
  c = struct([]);
end
dotest(c, N, comm); N=N+1; clear c;

comm='struct';
c.A = 1;
c.B = 2;
dotest(c, N, comm); N=N+1; clear c;

comm='struct with arrays';
c.A = [1 2 3 4 5 6];
c.B = [10 20; 30 40; 50 60; 70 80; 90 100];
c.C = [9 8 7 6 5 4 3 2 1]'; % transposed
dotest(c, N, comm); N=N+1; clear c;

comm='struct with chars';
c.A = 'a b c d e f g';
c.B = 'zz yy xx ww vv uu';
c.C = ['hippopotamus']'; % transposed
dotest(c, N, comm); N=N+1; clear c;

comm='struct with sparse';
c.A = sparse(100,100,42);
c.B = sparse(1,1,0);
c.C.s = sparse(eye(4));
dotest(c, N, comm); N=N+1; clear c;

comm='substructures';
c.A.a.b = 1;
c.A.b.c = 'cAbc';
c.B = [5 5 5 5];
if (VER <= 5.3)
  % Matlab up to V. 5.3 does not like empty structs
  c.C.elongated_name = [];
else
  c.C.elongated_name = struct([]);
end
c.D.complex = [1+i 2+2i 3+3i];
dotest(c, N, comm); N=N+1; clear c;


% =========================================
comm='cell - empty double';
c = {[]};
dotest(c, N, comm); N=N+1; clear c;

comm='cell - empty char';
c = {''};
dotest(c, N, comm); N=N+1; clear c;

comm='cell - char with spaces only';
c = {'          '};
dotest(c, N, comm); N=N+1; clear c;

comm='cell - empty double, char, double';
c = {[], '', []};
dotest(c, N, comm); N=N+1; clear c;

if (VER>5.3)
  comm='cell - empty struct, double';
  c = {struct([]), []};
  dotest(c, N, comm); N=N+1; clear c;
end

comm='cell with 3 empty cells';
c = { {} {} {} };
dotest(c, N, comm); N=N+1; clear c;

comm='cell numeric';
c = {177};
dotest(c, N, comm); N=N+1; clear c;

comm='cell complex';
c = {101-99i};
dotest(c, N, comm); N=N+1; clear c;

comm='cell alphanumeric';
c = {'aabbccdd'};
dotest(c, N, comm); N=N+1; clear c;

comm='cell structure';
a.b.c = [1 2 3];
a.b.d = 'Hello World!';
c = {a};
dotest(c, N, comm); N=N+1; clear c a;

comm='cell containing empty char field';
c = {'the next one is empty', '', 'the previous one is empty'};
dotest(c, N, comm); N=N+1; clear c;

comm='cell containing empty double field';
c = {'the next one is empty', [], 'the previous one is empty'};
dotest(c, N, comm); N=N+1; clear c;

comm='cell mixed';
c = { 'abc', 987, 'def', 654, 'ghijklmno', 10000, 9999-i };
dotest(c, N, comm); N=N+1; clear c;

comm='cell of cells';
c = { {'abc', 987}, {'def', 654}, {'ghijklmno', 10000}, {-1-i} };
dotest(c, N, comm); N=N+1; clear c;

comm='array of cells';
c{1,1} = { {'abc', 987}, {'def', 654}, {'ghijklmno', 10000} };
c{2,1} = { 'second row', 22222222222, 0.9222i };
dotest(c, N, comm); N=N+1; clear c;

% =========================================
comm='combination of all types';
c(1,1).a = 9e-9;
c(1,1).b = 'aaa';
c(1,1).c = {'bbb', [10 20 30], 'ccccccccccc'};
c(1,1).d.e.f.g.h = [10 20 30; 40 50 60; 70 80 90; 100 110 120];
c(1,1).e = sparse([1 2 4 5], [1 2 4 5], [1 1 1 1]);
c(1,2).c = [22+33i; 44-55i; -66+77i; -88+99i];
c(2,2).a.x(2).y(3).z = 'this is cool';
c(2,2).b = 7e-7;
c(2,2).d.hello.world.hitchhiker.galaxy = 42;
c(2,2).e = { sparse(4,7,1), ' check this out with spaces ', pi };
dotest(c, N, comm); N=N+1; clear c;

return



% ========================================
% ========================================
function dotest(c, N, comm)
% c is variable, N is id number and comm is comment.

if nargin<3, comm=''; end

% name based routines:
tsave_n(N, c);
str_c = xml_format(c);
%x = tload_n(N);
% % %str_x = xml_var2xml(x);
% % str_x = xml_format(x);
% % 
% % if (~strcmp( class(c), class(x)) | ...
% %     ~strcmp( str_c, str_x ) )
% %   disp(['Test ', num2str(N), ' (V.1.x) ***FAILED*** ("', comm, '")  <=====================']);
% %   return
% % else
% %   disp(['Test ', num2str(N), ' (V.1.x)    passed    ("', comm, '")']);
% % end

% test format from previous versions:
% save in type-based (1.x) version
%tsave_t(N, c);
str_c = xml_format(c);
% load with name-based (2.0) version
x = tload_n(N);
str_x = xml_format(x);

if (~strcmp( class(c), class(x)) | ...
    ~strcmp( str_c, str_x ) )
  disp(['Test ', num2str(N), ' (V.2.x,3.x) ***FAILED*** ("', comm, '")  <=====================']);
  return
else
  disp(['Test ', num2str(N), ' (V.2.x,3.x)    passed    ("', comm, '")']);
end

return


% ========================================
% ========================================
function tsave_t(N, c)
% saves variable c in file test_t_N.xml in old format of V.1.x
%xml_oldsave( ['test_t_', num2str(N), '.xml'], c );
str = xml_format_old(c);
fid = fopen(['test_t_', num2str(N), '.xml'], 'w');
fprintf( fid, '%s', str);
fclose(fid);

% ========================================
% ========================================
function tsave_n(N, c)
% saves variable c in file test_n_N.xml
% xml_save( ['test_n_', num2str(N), '.xml'], c );
str = xml_format(c);
fid = fopen(['test_n_', num2str(N), '.xml'], 'w');
fprintf( fid, '%s', str);
fclose(fid);

% % ========================================
% % ========================================
% function c = tload_t(N)
% % loads variable c in file test_t_N.xml
% c = xml_load( ['test_t_', num2str(N), '.xml'] );

% ========================================
% ========================================
function c = tload_n(N)
% loads variable c in file test_n_N.xml
str = fileread(['test_n_', num2str(N), '.xml']);
c = xml_parse(str);
