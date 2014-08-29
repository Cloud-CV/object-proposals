%XML_LOAD Loads XML file and return contents as Matlab structure or variable
%
% SYNTAX     V = xml_load( filename )
%            V = xml_load( filename, attswitch )
%
% INPUT
%  filename   filename of xml file to load (if extension .xml is omitted,
%             xml_load tries to append it if the file cannot be found).
%             This file should have been saved with xml_save().
%             If it's a non-Matlab XML file, please use e.g.
%             xmlstr = fileread(filename); V = xml_parseany(xmlstr);
%  attswitch  optional, default='on':
%             'on' takes attributes idx,size,type into account for
%                  creating corresponding Matlab data types
%             'off' ignores attributes in XML element headers
%
% OUTPUT
%   V        Matlab structure or variable
%
% SEE ALSO
%   xml_save, xml_format, xml_formatany, xml_parse, xml_parseany, xml_help, (xmlread, xmlwrite)
 
% Copyright (C) 2002-2005, University of Southampton
% Author: Dr Marc Molinari <m.molinari@soton.ac.uk>
% $Revision: 1.1 $ $Date: 2005/04/15 17:12:14 $ $Tag$
 
