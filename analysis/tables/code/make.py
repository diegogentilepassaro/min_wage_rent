#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
from distutils.dir_util import copy_tree
copy_tree("../../../lib/python/gslab_make", "./gslab_make") # Copy from gslab tools stored locally
from gslab_make.get_externals import *
from gslab_make.make_log import *
from gslab_make.make_links import *
from gslab_make.make_link_logs import *
from gslab_make.run_program import *
from gslab_make.dir_mod import *
from gslab_fill.tablefill import tablefill

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = '../output/')
set_option(output_dir = '../output/', temp_dir = '../temp/')
clear_dirs('../temp/')
clear_dirs('../output/')

envir_vars = os.getenv('PATH')
if envir_vars is None:
    envir_vars = os.getenv('Path')

start_make_logging()

fd_baseline_dir = "../../fd_baseline/output"

tablefill(input    = fd_baseline_dir + '/static.txt', 
          template = '../input/static.tex', 
          output   = '../output/static.tex')


tablefill(input    = fd_baseline_dir + '/static.txt', 
          template = '../input/static_slides.tex', 
          output   = '../output/static_slides.tex')

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')
