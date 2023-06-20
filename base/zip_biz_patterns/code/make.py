#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
from zipfile import ZipFile
from distutils.dir_util import copy_tree
copy_tree('../../../lib/python/gslab_make', './gslab_make') # Copy from gslab tools stored locally
from gslab_make.get_externals import *
from gslab_make.make_log import *
from gslab_make.make_links import *
from gslab_make.make_link_logs import *
from gslab_make.run_program import *
from gslab_make.dir_mod import *

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = '../output/')
clear_dirs('../temp/')
delete_files('../output/*')

envir_vars = os.getenv('PATH')
if envir_vars is None:
    envir_vars = os.getenv('Path')

stata = "StataMP-64"
if "StataSE" in envir_vars:
    stata = "StataSE-64"

start_make_logging()

path = '../../../drive/raw_data/zip_biz_patterns'
files = [f for f in os.listdir(path) if '.zip' in f]

for file in files:
    zf = ZipFile(os.path.join(path, file), 'r')
    zf.extractall('../temp/')
    zf.close()

files = [f for f in os.listdir('../temp/')]
for file in files:
    os.rename('../temp/' + file, '../temp/' + file.lower())

run_stata(program = 'build.do', executable = stata)

clear_dirs('../temp/')

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')

