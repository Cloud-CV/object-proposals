%XML_PARSE  parses XML string and returns corresponding Matlab structure.
%
% SYNTAX
%               V = xml_parse(xmlstr)
%               V = xml_parse(xmlstr, attswitch)
%               V = xml_parse(xmlstr, attswitch, S)
%
% Parses XML string str and returns matlab variable/structure.
% This is a non-validating parser!
%
% INPUT
%   str         xml string, possibly from file with function xml_load.m
%   att_switch  'on'- reads attributes, 'off'- ignores attributes
%   S           Optional. Variable which gets extended or whose
%               substructure parameters get overridden by entries in
%               the string. (may be removed in future versions)
%
% OUTPUT
%   V           Matlab variable or structure
%
% RELATED
%   xml_format, xml_formatany, xml_parseany, xml_load, xml_save, (xmlread, xmlwrite)
 
% Copyright (C) 2002-2005, University of Southampton
% Author: Dr Marc Molinari <m.molinari@soton.ac.uk>
% $Revision: 1.1 $ $Date: 2005/04/15 17:12:14 $ $Tag$
 
