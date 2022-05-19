import os
import time
import subprocess

folders_to_run = ["estimation_samples",
                  "maps_mw_long_run",
                  "maps_shares",
                  "maps_US",
                  "shares",
                  "zillow_benchmark"]

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