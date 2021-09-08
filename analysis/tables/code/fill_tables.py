import os
from gslab_fill.tablefill import tablefill

fd_baseline = "../../fd_baseline/output"

tablefill(input    = fd_baseline + '/static.txt', 
	      template = '../input/static.tex', 
          output   = '../output/static.tex')
