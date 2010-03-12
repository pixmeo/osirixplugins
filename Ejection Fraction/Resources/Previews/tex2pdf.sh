#!/bin/csh

foreach file (./*.tex)
	if (-d $file) then
		echo '.'
	else
		pdflatex -interaction nonstopmode $file
		pdfcrop `echo $file | awk '{sub(".tex", ".pdf"); print $0}'`
	endif
end

exit 0;