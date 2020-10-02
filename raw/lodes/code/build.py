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
from bs4 import BeautifulSoup
import re
import logging

def create_directories(types, path, years):
    """
    Function:
        Create a directory whose name starts with "LODES_Download_", set the newly created directory as working directory; 
        Create subfolders under the working directory based on the data types specified in "types". 
    Return: 
        Directories are created under current working directory, for storing downloaded CSV files. 
    """
    #specify the Year of job data, Segment of the workforce, and Job Type 
    work_segs = ["S000","SA01","SA02","SA03","SE01","SE02","SE03","SI01","SI02","SI03"]
    work_types = ["JT00","JT01","JT02","JT03","JT04","JT05"]

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


def process_files(types, states, path, years, logger, n_cores = 2, unzip = True):
    """
    function: 
        Specify the state and data type to donwload, call function get_links to get download links, 
        and call download_file to download and unzip files.
    return: 
        The downloaded and unzipped files are stored in the specified folders. 
    """
    combos = []
    for i in states:
        for j in types:
            combos.append((i, j))
    
    #Call get_links function to get download links
    p = multiprocessing.Pool(n_cores)
    results = p.map(get_links, combos)
    log_and_print("Links created.", logger)
    flat_results = [x for y in results for x in y
                    for yr in range(2002, years[0])                      
                    if str(yr) not in x]

    download_args = [[x, path, unzip] for x in flat_results]
    log_and_print("\nStart downloading files.", logger)

    p = multiprocessing.Pool(n_cores)
    downloaded_files_all = p.map(download_file, download_args)
    log_and_print("\nDownload finished.", logger)

    return None


def get_links(vals):
    """
    Function:
        Get download links for data files of a state"s specific group of LODES data. 
    Args:
        vals: a tuple, where the first item is the state acronym and the second is the group name.
            e.g., ("va", "rac") represents all RAC files for Virginia.
    Return:
        a list, where each item is a file"s download link of a specific state and data group. 
    """
    form = [("version","LODES7")]
    url_main = "https://lehd.ces.census.gov/php/inc_lodesFiles.php"
    start_url = "https://lehd.ces.census.gov"

    f = dict(form + [("type",vals[1]),("state",vals[0])])
    r = requests.post(url_main, data = f)

    soup = BeautifulSoup(r.text, "lxml")
    a_link = [f"{start_url}{x['href']}" for x in soup.find("div", {"id":"lodes_file_list"}).find_all("a")]

    return a_link


def download_file(args):
    # Modified from http://stackoverflow.com/questions/16694907/how-to-download-large-file-in-python-with-requests-py
    """
    Function:
        Download files using the download links from the function get_links, unzip the gzip files to csv files, 
        and remove the gzip files in the folders. 
    Args:
        url: the download links for datasets from function get_links. 
    Return:
        Downloaded CSV files in the local folders. 
    """
    url, path, unzip = args
    pattern = "20[0-1][0-9]"

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
    DATA_PATH  = os.path.join(ROOT_PATH, "drive\\raw_data\\lodes")

    logging.basicConfig(filename = os.path.join(LODES_PATH, 'build.log'), filemode = 'w', 
                        format = '%(asctime)s %(message)s', level = logging.INFO, datefmt = '%Y-%m-%d %H:%M:%S')
    logger = logging.getLogger()

    empty_folder = len(os.listdir(DATA_PATH)) == 0
    if not empty_folder:
        sys.exit("Error: Please clear the 'drive/raw_data/lodes/' folder before downloading the data.")

    freeze_support() # Prevent Windows system to freeze when running multiprocessing
    cores = 6        # Choose number of cores

    # start_end_year = [2002, 2017]
    start_end_year = [2009, 2017]
    data_types = ["od","rac","wac"]                                   # LODES data categories 
    states = ["al", "ak", "az", "ar", "ca", "co", "ct", "de", "dc",   # States acronyms
              "fl", "ga", "hi", "id", "il", "in", "ia", "ks", "ky",
              "la", "me", "md", "ma", "mi", "mn", "ms", "mo", "mt",
              "ne", "nv", "nh", "nj", "nm", "ny", "nc", "nd", "oh",
              "ok", "or", "pa", "ri", "sc", "sd", "tn", "tx", "ut",
              "vt", "va", "wa", "wv", "wi", "wy", "pr"]

    current_time = datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")
    log_and_print(f"Start downloading process. Time is {current_time}", logger)

    try:
        create_directories(types = data_types, path = DATA_PATH, years = start_end_year)
        log_and_print("\nDirectories created.", logger)

        process_files(data_types, states, DATA_PATH, start_end_year, logger, n_cores = cores, unzip = False)
        log_and_print(f"\nDownloaded CSV files available in ROOT/drive/raw_data/lodes.", logger)

    except Exception as e:
        log_and_print("\nThere was an error. See details below:", logger)
        logging.fatal(e, exc_info = True)  # log exception info at FATAL log level
        print(e)
