BSD = """/*
    Copyright (c) %04d, Philipp Krähenbühl
    All rights reserved.
	
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
        * Neither the name of the Stanford University nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.
	
    THIS SOFTWARE IS PROVIDED BY Philipp Krähenbühl ''AS IS'' AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL Philipp Krähenbühl BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
"""

from sys import argv
import re
from datetime import date

r = re.compile( '(# -*- encoding: utf-8)?\n?(/\\*|"""|%\{).*?All rights reserved.*?(\\*/|"""|%\})\n?', re.MULTILINE | re.DOTALL )
YEAR = date.today().year
for f in argv[1:]:
	bsd = BSD%YEAR
	if len(f)>3 and f[-3:]==".py":
		bsd = bsd.replace("/*", '# -*- encoding: utf-8\n"""')
		bsd = bsd.replace("*/", '"""')
	if len(f)>2 and f[-2:]==".m":
		bsd = bsd.replace("/*", '%{')
		bsd = bsd.replace("*/", '%}')
	lines = open( f, 'r' ).read()
	# Remove any old lic
	lines = r.sub( '', lines )
	if len(f)>3 and f[-3:]==".py":
		lines = lines.replace( """# -*- encoding: utf-8""", "" )
	open( f, 'w' ).write( bsd+lines )
