%XML_FORMATANY  Formats a matlab variable into an XML string.
%
% SYNTAX
%             xmlstr = xml_formatany(V)
%             xmlstr = xml_formatany(V, rootname )
%
% INPUT
%   V         Matlab variable or structure.
%             The data types we can deal with are:
%              char, numeric, complex, struct, sparse, cell, logical/boolean
%              -> struct fields named ATTRIBUTE (user-definable) get converted into XML attribute
%             Not handled are data types:
%              function_handle, single, intxx, uintxx, java objects
%
%  rootname   optional, give root element a specific name, eg. 'books'
%
% OUTPUT
%   xmlstr    string, containing XML description of variable V
%
% SPECIAL FIELDNAMES
%   .ATTRIBUTE.              define additional attributes by using subfields, eg V.ATTRIBUTE.type='mydbtype'
%   .CONTENT                 define content if attribute field given (all capitals)
%   .ATTRIBUTE.NAMESPACE     define namespace (all capitals)
%   .ATTRIBUTE.TAGNAME       define element tag name (if not an allowed Matlab fieldname in struct)  e.g.: v.any.ATTRIBUTE.TAGNAME = 'xml-gherkin'
%
% SEE ALSO
%   xml_help, xml_parse, xml_parseany, xml_load, xml_save, (xmlread, xmlwrite)
 
% Copyright (C) 2002-2005, University of Southampton
% Author: Dr Marc Molinari <m.molinari@soton.ac.uk>
% $Revision: 1.1 $ $Date: 2005/04/15 17:12:14 $ $Tag$
 
