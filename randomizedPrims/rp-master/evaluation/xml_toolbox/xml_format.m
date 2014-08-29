%XML_FORMAT  Convert a Matlab variable or struct into an XML string.
%
% SYNTAX:       xmlstr = xml_format(v, [attswitch], [name] )
%
% INPUT
%   v           Matlab variable type "struct", "char", "double"(numeric),
%               "complex", "sparse", "cell", or "logical"(boolean)
%   attswitch   optional, default='on':
%               'on' writes header attributes idx,size,type for
%                    identification by Matlab when parsing in XML later
%               'off' writes "plain" XML without header attributes
%   name        optional, give root element a specific name, eg. 'project'
%
% OUTPUT
%   xmlstr      string, containing XML description of variable V
%
% SEE ALSO
%   xml_help, xml_formatany, xml_parse, xml_load, xml_save, (xmlread, xmlwrite)
 
% Copyright (C) 2002-2005, University of Southampton
% Author: Dr Marc Molinari <m.molinari@soton.ac.uk>
% $Revision: 1.1 $ $Date: 2005/04/15 17:12:14 $ $Tag$
 
