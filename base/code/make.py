#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
from distutils.dir_util import copy_tree
copy_tree("../../lib/python/gslab_make", "./gslab_make") # Copy from gslab tools stored locally
from gslab_make.get_externals import *
from gslab_make.make_log import *
from gslab_make.make_links import *
from gslab_make.make_link_logs import *
from gslab_make.run_program import *
from gslab_make.dir_mod import *

stata_exe = os.environ.get('STATAEXE')
if stata_exe:
    import copy
    default_run_stata = copy.copy(run_stata)
    def run_stata(**kwargs):
        kwargs['executable'] = stata_exe
        default_run_stata(**kwargs)

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = '../output/')
set_option(output_dir = '../output/', temp_dir = '../temp/')
clear_dirs('../temp/')
delete_files('../output/*')

start_make_logging()

# os.system('Rscript RenameZillowVars_zipLevel.R')
# os.system('Rscript cleanGeoRelationshipFiles.R')
run_rbatch(program = 'RenameZillowVars_zipLevel.R')
run_rbatch(program = 'cleanGeoRelationshipFiles.R')
run_stata(program = 'state_mw.do')
run_stata(program = 'substate_mw.do')

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')

