import os
import time
import subprocess

folders_to_run = ["autocorrelation",
                  "fd_baseline",
                  "fd_stacked",
                  "fd_robustness",
                  "fd_heterogeneity",
                  "fd_geos_times",
                  "twfe_wages",
                  "counterfactuals",
                  "maps_events"]

log_file = open("run.log", 'w')
log_file.write("Started at " + time.strftime('%I:%M:%S%p %Z on %b %d, %Y\n\n'))

for folder in folders_to_run:
    os.chdir(os.path.join(folder, "code"))

    log_file.write(time.strftime('%I:%M:%S%p') + ":    Folder /" + folder + "/ started.\n")

    p = subprocess.Popen("python make.py", 
                        stdin = subprocess.PIPE, shell = True)
    p.communicate(input = "\n")

    os.chdir(os.path.join("..", ".."))

log_file.write("\nFinished at " + time.strftime('%I:%M:%S%p %Z on %b %d, %Y\n'))
log_file.close()
