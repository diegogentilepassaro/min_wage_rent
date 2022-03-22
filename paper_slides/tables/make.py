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
from gslab_fill.tablefill import tablefill

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = "output")
set_option(output_dir = "output", makelog = "output/make.log")
clear_dirs("temp/")
clear_dirs("output/")


start_make_logging()

autocorr_dir         = "../../analysis/autocorrelation/output"
desc_est_samples_dir = "../../descriptive/estimation_samples/output"
fd_baseline_dir      = "../../analysis/fd_baseline/output"
fd_cf_dir            = "../../analysis/counterfactuals/output"
fd_robust_dir        = "../../analysis/fd_robustness/output"
fd_county_dir        = "../../analysis/fd_county/output"
fd_wages_dir         = "../../analysis/twfe_wages/output"
fd_stacked_dir       = "../../analysis/fd_stacked/output"

tablefill(input    = os.path.join(desc_est_samples_dir, "stats_zip_samples.txt"), 
          template = "input/stats_zip_samples.tex", 
          output   = "output/stats_zip_samples.tex")

tablefill(input    = os.path.join(desc_est_samples_dir, "stats_est_panel.txt"), 
          template = "input/stats_est_panel.tex", 
          output   = "output/stats_est_panel.tex")

tablefill(input    = os.path.join(fd_baseline_dir, "static.txt"), 
          template = "input/static.tex", 
          output   = "output/static.tex")

tablefill(input    = os.path.join(fd_baseline_dir, "static.txt"), 
          template = "input/slides_static.tex",
          output   = "output/slides_static.tex")

tablefill(input    = os.path.join(fd_stacked_dir, "stacked_w6.txt"), 
          template = "input/stacked_w6.tex", 
          output   = "output/stacked_w6.tex")

tablefill(input    = os.path.join(fd_robust_dir, "robustness.txt"),
          template = "input/robustness.tex",
          output   = "output/robustness.tex")

tablefill(input    = os.path.join(fd_robust_dir, "static_sample.txt"),
          template = "input/static_sample.tex",
          output   = "output/static_sample.tex")

tablefill(input    = os.path.join(fd_robust_dir, "static_sample.txt"),
          template = "input/slides_static_sample.tex",
          output   = "output/slides_static_sample.tex")

tablefill(input    = os.path.join(fd_robust_dir, "static_ab.txt"),
          template = "input/static_ab.tex", 
          output   = "output/static_ab.tex")

tablefill(input    = os.path.join(fd_county_dir, "static_county.txt"),
          template = "input/static_county.tex", 
          output   = "output/static_county.tex")

tablefill(input    = os.path.join(fd_wages_dir, "static_wages.txt"), 
          template = "input/static_wages.tex", 
          output   = "output/static_wages.tex")

tablefill(input    = os.path.join(fd_wages_dir, "static_wages_robustness.txt"), 
          template = "input/static_wages_robustness.tex", 
          output   = "output/static_wages_robustness.tex")

tablefill(input    = os.path.join(fd_cf_dir, "counterfactuals.txt"), 
          template = "input/counterfactuals.tex", 
          output   = "output/counterfactuals.tex")

tablefill(input    = os.path.join(fd_cf_dir, "counterfactuals.txt"), 
          template = "input/slides_counterfactuals.tex", 
          output   = "output/slides_counterfactuals.tex")

tablefill(input    = os.path.join(autocorr_dir, "autocorrelation.txt"), 
          template = "input/autocorrelation.tex", 
          output   = "output/autocorrelation.tex")

end_make_logging()

shutil.rmtree("gslab_make")
input("\n Press <Enter> to exit.")
