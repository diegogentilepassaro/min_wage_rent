###############################################################################
# Original script written by Graham MacDonald and Vivian Zheng from the Urban Institute.
# https://github.com/UrbanInstitute/lodes-data-downloads/
#
# Script modified to fit the needs of the project min_wage_rent
###############################################################################

import sys
import os
import shutil
import datetime
import requests
import gzip
import multiprocessing
from multiprocessing import Pool, freeze_support
import re
import logging


def create_directories(types, path, years, work_segs, work_types):
    """
    Function:
        Create directories in `path` folder to store LODES data
    """

    for p in types:
        new_dir = os.path.join(path, p)
        os.mkdir(new_dir)

        if p == "od":
            for typ in work_types:
                os.mkdir(os.path.join(new_dir, typ))
                for year in range(years[0], years[1] + 1):
                    os.mkdir(os.path.join(new_dir, typ, str(year)))
        else:
            for seg in work_segs:
                os.mkdir(os.path.join(new_dir, seg))
                for typ in work_types:
                    os.mkdir(os.path.join(new_dir, seg, typ))
                    for year in range(years[0], years[1] + 1):
                        os.mkdir(os.path.join(new_dir, seg, typ, str(year)))


def process_files(types, states, years, logger, work_segs, work_types, 
                  path, n_cores = 2, unzip = True):
    """
    function: 
        Build links, download LODES data, and store in previously created folders

        If unzip is set equal to True, the files will be unzipped
    """
    
    build_links_args = [types, states, years, work_segs, work_types]
    urls = build_links(build_links_args)
    log_and_print("Links created.", logger)

    download_args = [[x, path, unzip] for x in urls]
    log_and_print("\nStart downloading files.", logger)

    p = multiprocessing.Pool(n_cores)
    downloaded_files_all = p.map(download_file, download_args)
    log_and_print("\nDownload finished.", logger)

    return None


def build_links(args):
    """
    function:
        Build links to download LODES7 data for given years
    """

    types, states, years, work_segs, work_types = args

    url_base = "https://lehd.ces.census.gov/data/lodes/LODES7"
    all_links = []
    for st in states:
        for p in types:
            if p == "od":
                for typ in work_types:
                    for year in range(years[0], years[1] + 1):
                        url = f"{url_base}/{st}/od/{st}_od_aux_{typ}_{year}.csv.gz"
                        all_links.append(url)
            else:
                for seg in work_segs:
                    for typ in work_types:
                        for year in range(years[0], years[1] + 1):
                            url = f"{url_base}/{st}/{p}/{st}_{p}_{seg}_{typ}_{year}.csv.gz"
                            all_links.append(url)
   

    return all_links


def download_file(args):
    # Modified from http://stackoverflow.com/questions/16694907/how-to-download-large-
    # file-in-python-with-requests-py
    """
    Function:
        Download files using the download links from the function build_links, and optionally unzip the 
        gzip files to csv files and remove the gzip files in the folders.
    """
    pattern = "20[0-1][0-9]"
    url, path, unzip = args

    fname = url.split("/")[-1]
    points = fname.split(".")[0].split("_")
    year = re.findall(pattern, fname)[0]

    if len(points) < 5:
        print("The file name in the download link is not correct. Please double check.")
        return None

    else:
        if points[1] == "od":
            loc = os.path.join(path, points[1], points[3], year)
        else: 
            loc = os.path.join(path, points[1], points[2], points[3], year)

        r = requests.get(url, stream = True)
        f = open(os.path.join(loc, fname), "wb")

        for chunk in r.iter_content(chunk_size = 1024): 
            if chunk:
                f.write(chunk)

        f.close()
        if unzip:
            unzip_file(fname, loc)

    return fname


def unzip_file(fname, loc):
    """
    Function: 
        Convert gzip files to CSV files, and remove the gzip files in the local folders.
    Args:
        fname: the name of the gzip file
        loc: the location of the gzip files 
    Return: 
        The CSV files that are converted from the gzip files 
    """
    infile = gzip.open(os.path.join(loc, fname), "rb")
    outfile = open(os.path.join(loc, fname).replace('.gz',''), "wb")

    outfile.write(infile.read())

    infile.close()
    outfile.close()

    os.remove(os.path.join(loc, fname))


def log_and_print(message, logger):
    print(message)
    logger.info(message.replace("\n", ""))



if __name__ == "__main__":

    ## Preliminaries
    LODES_PATH = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    ROOT_PATH  = os.path.dirname(os.path.dirname(LODES_PATH))

    start_end_year = [2016, 2016]
    DATA_PATH  = os.path.join(ROOT_PATH, "drive", "raw_data", "lodes_" + str(start_end_year[0]))

    logging.basicConfig(filename = os.path.join(LODES_PATH, 'build.log'), filemode = 'w', 
                        format = '%(asctime)s %(message)s', level = logging.INFO, datefmt = '%Y-%m-%d %H:%M:%S')
    logger = logging.getLogger()

    empty_folder = len(os.listdir(DATA_PATH)) == 0
    if not empty_folder:
        sys.exit("Error: Please clear the corresponding folder before downloading the data.")

    freeze_support() # Prevent Windows system to freeze when running multiprocessing
    cores = 8        # Choose number of cores

    data_types = ["od","rac","wac"]                                   # LODES data categories 
    states = ["al", "ak", "az", "ar", "ca", "co", "ct", "de", "dc",   # States acronyms
              "fl", "ga", "hi", "id", "il", "in", "ia", "ks", "ky",
              "la", "me", "md", "ma", "mi", "mn", "ms", "mo", "mt",
              "ne", "nv", "nh", "nj", "nm", "ny", "nc", "nd", "oh",
              "ok", "or", "pa", "ri", "sc", "sd", "tn", "tx", "ut",
              "vt", "va", "wa", "wv", "wi", "wy"]

    work_segs = ["S000","SA01","SA02","SA03","SE01","SE02","SE03","SI01","SI02","SI03"]
    work_types = ["JT00","JT01","JT02","JT03","JT04","JT05"]

    current_time = datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")
    log_and_print(f"Start downloading process. Time is {current_time}", logger)

    try:
        create_directories(data_types, DATA_PATH, start_end_year, work_segs, work_types)
        log_and_print("\nDirectories created.", logger)

        process_files(data_types, states, start_end_year, logger, work_segs, work_types, 
                      DATA_PATH, n_cores = cores, unzip = False)
        log_and_print(f"\nDownloaded CSV files available in ROOT/drive/raw_data/lodes.", logger)

    except Exception as e:
        log_and_print("\nThere was an error. See details below:", logger)
        logging.fatal(e, exc_info = True)  # log exception info at FATAL log level
        print(e)
