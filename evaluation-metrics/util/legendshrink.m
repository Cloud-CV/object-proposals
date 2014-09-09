function legendshrink(s,align,lg)
% LEGENDSHRINK Shrink the legend lines
%
%   This is important for small plots because the size of the lines is
%   constant irrespective of the physical size of the figure. Only works
%   for vertical legends, for now.
%
%   LEGENDSHRINK(S): adjusts the length of the lines in the legend by
%   scaling factor S < 1. (S = 0.6 if omitted.) All legends in the current
%   figure are affected.
%
%   LEGENDSHRING(S,ALIGN): as above aligning the legend text as specified:
%      ALIGN = 'left' | 'right' | 'centre' | 'best' (default)
%   Default ('best') aligning adapts the alignment based on the 'location'
%   of the legend. The first letter can be used as a shorthand for each.
%
%   LEGENDSHRINK(S,ALIGN,LG): as above for legend handle(s) LG.
%
%   If S or ALIGN are [] then default values are used.
%
% EXAMPLE
%   figure; hold on
%   plot(1:10,'.-'); 
%   plot(10:-1:1,'o-'); 
%   legend({'one' 'two'},'location','north')
%   legendshrink
%
%
% Please report bugs and feature requests for
% this package at the development repository:
%  <http://github.com/wspr/matlabpkg/>
%
% LEGENDSHRINK  v0.2  2009/22/06  Will Robertson
% Licence appended.


%% Input parsing
if nargin < 1 || isempty(s),     s = 0.6;        end
if nargin < 2 || isempty(align), align = 'best'; end
if nargin < 3
  % all legends in the current figure:
  lg = findobj(gcf,'Tag','legend');
end

if isempty(lg)
  warning('LEGENDSHRINK:nolegend',...
    'There is no legend to shrink. Exiting gracefully.');
  return
elseif length(lg) > 1
  % If there are multiple legends then re-call the function for each
  % individual legend handle:
  for ii = 1:length(lg)
    legendshrink(s,align,lg(ii))
  end
  return
end

%% Get parameters
% Will break if children are added to the legend axis. Damn.

lch = get(lg,'Children');
% this allows interaction with labelplot.m:
cch = findobj(lch,'-not','Tag','legendlabel');
cll = findobj(lch,'Tag','legendlabel');

orientation = get(lg,'Orientation');
legendloc = get(lg,'Location'); 
orientvertical = strcmp(orientation,'vertical');

%% Resizing and aligning

if orientvertical
  if align(1)=='l'
    legendtrim = @legendtrimleft;
  elseif align(1)=='r'
    legendtrim = @legendtrimright;
  elseif align(1)=='c'
    legendtrim = @legendtrimcentre;
  else
% Want to ensure that the legend is trimmed away from the side that's being
% aligned to the figure; e.g., if the legend is inside the figure on the
% right, then the left side needs to be trimmed. And vice versa. Centre it
% if unsure. (Perhaps there should be an option to always do this.)
    if ~isempty(regexpi(legendloc,'WestOutside$')) || ...
        ~isempty(regexpi(legendloc,'East$'))
      legendtrim = @legendtrimleft;
    elseif ~isempty(regexpi(legendloc,'EastOutside$')) || ...
        ~isempty(regexpi(legendloc,'West$'))
      legendtrim = @legendtrimright;
    else
      legendtrim = @legendtrimcentre;
    end
  end
else
  warning('LEGENDSHRINK:horizontal',...
    'There is yet no implemented method for shrinking horizontal legends. Exiting gracefully.');
  legendtrim = @legendtrimabort;
end

%% Loop through and adjust the legend children

% hack to get things working for now:
cch_lines = findobj(cch,'Type','Line');
cch_min = find(cch==cch_lines(1));
cch = cch(cch_min:end);
cch_max = 3*floor(length(cch)/3);
cch = cch(1:cch_max);

for ii = 2:3:length(cch)
  %  ii-1  ==  marker handle (line handle)
  %  ii    ==    line handle
  %  ii+1  ==    text handle
  linepos = get(cch(ii),'XData');
  textpos = get(cch(ii+1),'Position');
  linewidth = linepos(2)-linepos(1);
  
  [newlinepos newtextpos] = legendtrim(linepos,textpos);
  
  set(cch(ii-1),'XData',   mean(newlinepos));
  set(cch(ii),  'XData',   newlinepos);
  set(cch(ii+1),'Position',newtextpos);
end

%% Adjust the legend title, if any
% This is provided by labelplot.m (same author)

if ~isempty(cll)
  llpos = get(cll,'Position');
  if isequal(legendtrim,@legendtrimleft)
    llpos(1) = llpos(1)+s*linewidth/2;
  elseif isequal(legendtrim,@legendtrimright)
    llpos(1) = llpos(1)-s*linewidth/2;
  end
  set(cll,'Position',llpos);
end

%% subfunctions

  function [newlinepos newtextpos] = legendtrimleft(linepos,textpos)
    newlinepos = linepos;
    newtextpos = textpos;
    newlinepos(1) = linepos(2)-s*linewidth;
  end
  function [newlinepos newtextpos] = legendtrimright(linepos,textpos)
    newlinepos = linepos;
    newtextpos = textpos;
    newlinepos(2) = linepos(1)+s*linewidth;
    newtextpos(1) = textpos(1)-(linepos(2)-newlinepos(2));
  end
  function [newlinepos newtextpos] = legendtrimcentre(linepos,textpos)
    newlinepos = linepos;
    newtextpos = textpos;
    newtextpos(1) = textpos(1)-(1-s)*linewidth/2;
    newlinepos(1) = linepos(1)+(1-s)*linewidth/2;
    newlinepos(2) = newlinepos(1)+s*linewidth;
  end
  function [newlinepos newtextpos] = legendtrimabort(linepos,textpos)
    newlinepos = linepos;
    newtextpos = textpos;
  end

end

% Copyright (c) 2007-2009, Will Robertson, wspr 81 at gmail dot com
% All rights reserved.
%
% Distributed under the BSD licence in accordance with the wishes of the
% Matlab File Exchange.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ''AS IS'' AND ANY
% EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
% THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
