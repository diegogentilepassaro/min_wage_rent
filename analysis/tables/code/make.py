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
fd_cf_dir       = "../../counterfactuals/output"
fd_robust_dir   = "../../fd_robustness/output"
fd_county_dir   = "../../fd_county/output"
fd_wages_dir    = "../../twfe_wages/output"

tablefill(input    = os.path.join(fd_baseline_dir, 'static.txt'), 
          template = '../input/static.tex', 
          output   = '../output/static.tex')

tablefill(input    = os.path.join(fd_baseline_dir, 'static.txt'), 
          template = '../input/slides_static.tex',
          output   = '../output/slides_static.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_sample.txt'),
          template = '../input/static_sample.tex',
          output   = '../output/static_sample.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_sample.txt'),
          template = '../input/slides_static_sample.tex',
          output   = '../output/slides_static_sample.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_robust.txt'),
          template = '../input/static_robust.tex',
          output   = '../output/static_robust.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_robust.txt'), 
          template = '../input/slides_static_robust.tex', 
          output   = '../output/slides_static_robust.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_ab.txt'),
          template = '../input/static_ab.tex', 
          output   = '../output/static_ab.tex')

tablefill(input    = os.path.join(fd_county_dir, 'static_county.txt'),
          template = '../input/static_county.tex', 
          output   = '../output/static_county.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_expMW_sensitivity.txt'),
          template = '../input/static_expMW_sensitivity.tex', 
          output   = '../output/static_expMW_sensitivity.tex')

tablefill(input    = os.path.join(fd_robust_dir, 'static_expMW_sensitivity.txt'),
          template = '../input/slides_static_expMW_sensitivity.tex', 
          output   = '../output/slides_static_expMW_sensitivity.tex')

tablefill(input    = fd_wages_dir + '/static_wages.txt', 
          template = '../input/static_wages.tex', 
          output   = '../output/static_wages.tex')

tablefill(input    = fd_wages_dir + '/static_wages_robustness.txt', 
          template = '../input/static_wages_robustness.tex', 
          output   = '../output/static_wages_robustness.tex')

tablefill(input    = fd_cf_dir + '/counterfactuals.txt', 
          template = '../input/counterfactuals.tex', 
          output   = '../output/counterfactuals.tex')

tablefill(input    = fd_cf_dir + '/counterfactuals.txt', 
          template = '../input/slides_counterfactuals.tex', 
          output   = '../output/slides_counterfactuals.tex')

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')
