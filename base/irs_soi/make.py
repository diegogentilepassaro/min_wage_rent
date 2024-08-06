#! /usr/bin/env python3
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os, sys
from zipfile import ZipFile
from distutils.dir_util import copy_tree
from gslab_make import *

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
PATHS = {
    'config'           : '',
    'config_user'      : '',
    'input_dir'        : '../../drive/raw_data/irs_soi',
    'external_dir'     : '',
    'temp_dir'         : 'temp',
    'output_dir'       : '../../drive/base_large/irs_soi',
    'makelog'          : 'output/make.log',
    'output_statslog'  : 'output/data_file_manifest.log',
    'source_maplog'    : 'output/source_map.log',
    'source_statslog'  : 'output/source_stats.log',
}
sys.path.append(f'{os.path.dirname(__file__)}/code/')

clear_dir([PATHS[x] for x in ['temp_dir', 'output_dir']])
clear_dir([os.path.dirname(PATHS['makelog'])])

envir_vars = os.getenv('PATH')
if envir_vars is None:
    envir_vars = os.getenv('Path')

stata = "StataMP"
if "StataSE" in envir_vars:
    stata = "StataSE-64"

start_makelog(PATHS)

files = [f for f in os.listdir(PATHS['input_dir']) if '.zip' in f]

for file in files:
    year = file.replace('zipcode', '').replace('.zip', '')
    print(f"Decompressing {year} file: {file}")
    zf = ZipFile(os.path.join(PATHS['input_dir'], file), 'r')
    zf.extractall(f'{PATHS['temp_dir']}/{year}')
    zf.close()

run_stata(program = 'code/build.do', executable = stata, paths=PATHS)
run_stata(program = 'code/build_by_bracket.do', executable = stata, paths=PATHS)

clear_dir([PATHS[x] for x in ['temp_dir']])

end_makelog(PATHS)

# input('\n Press <Enter> to exit.')