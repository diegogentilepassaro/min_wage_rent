import sys
import os
import logging
import requests
import zipfile

def get_year_data(year, data_type, outstub, unzip = True):
    ''' Get County High-Level files for a given year. '''
    type_dict = {'county'  :['xls', 'all_county_high_level'],
                 'area'    :['csv', 'qtrly_by_area'],
                 'industry':['csv', 'qtrly_by_industry']}

    type_info = type_dict[data_type]
    filename = "%s_%s.zip" % (year, type_info[1])
    url = "https://data.bls.gov/cew/data/files/%s/%s/%s" % (year, type_info[0], filename)
    r = requests.get(url)

    zip_file = os.path.join(outstub, filename)
    open(zip_file, 'wb').write(r.content)

    if unzip:
        zip_folder = outstub
        if data_type is "county":
            zip_folder = os.path.join(outstub, filename.split(".")[0])
        
        zip = zipfile.ZipFile(zip_file, allowZip64 = True)
        zip.extractall(zip_folder)
        zip.close()

        os.remove(zip_file)

def log_and_print(message, logger):
    print(message)
    logger.info(message)

if __name__ == '__main__':

    # Preliminaries
    logging.basicConfig(filename = '../output/build.log', filemode = 'w', format = '%(asctime)s %(message)s',
                        level=logging.INFO, datefmt='%Y-%m-%d %H:%M:%S')
    logger = logging.getLogger()

    QCEW_PATH = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    ROOT_PATH = os.path.dirname(os.path.dirname(QCEW_PATH))
    ORIG_PATH = os.path.join(ROOT_PATH, "drive\\raw_data\\qcew\\origin")

    empty_folder = len(os.listdir(ORIG_PATH)) == 0

    if not empty_folder:
        sys.exit("Error: Please clear 'origin' folder before downloading the data.")
    
    log_and_print('Start raw data build.', logger)

    start_year     = 1990
    start_year_ind = 1990
    end_year       = 2019

    # County-High Level
    folder = os.path.join(ORIG_PATH, 'county')
    os.mkdir(folder)

    for year in range(start_year, end_year + 1):
        get_year_data(year = year, data_type = 'county', outstub = folder)

    log_and_print("County-High Level data downloaded and unzipped.", logger)
    
    # Area Quarterly
    folder = os.path.join(ORIG_PATH, 'area')
    os.mkdir(folder)

    for year in range(start_year, end_year + 1):
        get_year_data(year = year, data_type = 'area', outstub = folder)

    log_and_print("By Area Quarterly data downloaded and unzipped.", logger)

    # Industry Quarterly
    folder = os.path.join(ORIG_PATH, 'industry')
    os.mkdir(folder)

    for year in range(start_year_ind, end_year + 1):
        get_year_data(year = year, data_type = 'industry', outstub = folder)

    log_and_print("By Industry Quarterly data downloaded and unzipped.", logger)

    log_and_print("Data succesfully downloaded.", logger)
