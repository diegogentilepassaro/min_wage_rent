###################
# BLS API allows only 500 query of25 series per day, with a registration key (Unregistered users only have 25 quesries a day). 
#To obtain a registration key, visit https://data.bls.gov/registrationEngine/
#The registration key must be updated once a year.
###########
import requests
import json
import pandas
import logging
import os
import sys
import datetime

def create_seriesID_list(instub):
    
    #read in area codes and build list of laus series to download
    areacodes = pandas.read_csv(instub + 'bls_areacodes.csv')
    areacodes = areacodes[areacodes.area_type_code == 'F']
    areacodes = areacodes[['area_code', 'area_text']]
    areacodes = areacodes.rename(columns = {'area_text': 'county'})
    areacodes = areacodes.area_code
    
    #Build Series ID
    #	                      1         2
    #	Series ID e.g.:    LAUCN281070000000003
    #
    #	Positions    Value            Field Name
    #
    #	1-2          LA               Prefix
    #	3            U                Seasonal Adjustment Code (U = Unadjusted and S = Seasonally Adjusted)
    #	4-18         CN2810700000000  Area Code
    #	19-20        03               Measure Code (06 = Labor force, 05 = Employment, 04 = Unemployment, 03 = Unemp. rate)
    
    laus_seriesID = 'LAU' + areacodes + '03'
    laus_seriesID = laus_seriesID.tolist()
    
    return laus_seriesID


def divide_chunks(l, n): 
      
    # looping till length l 
    for i in range(0, len(l), n):  
        yield l[i:i + n] 


def get_data(seriesID, year_start, year_end, outstub):
    #Code adapted from http://danstrong.tech/blog/BLS-API/
    
    seriesID_list = list(divide_chunks(seriesID, 25))
    
    df_list = []
    
    for this_series in seriesID_list:  
        headers = {'Content-type': 'application/json'}
        data = json.dumps({"seriesid": this_series,
                           "startyear":year_start, 
                           "endyear":year_end, 
                           "registrationkey":"4ad5d078135a4bea83ef7c2550427f6e"})
        p = requests.post('https://api.bls.gov/publicAPI/v2/timeseries/data/', data=data, headers=headers)
        json_data = json.loads(p.text)
        
        county_list = []
        year_list = []
        month_list = []
        unemp_list = []
        footnote_list = []
        
        for series in json_data['Results']['series']:
            countyfips = series['seriesID'][5:10]
            for item in series['data']:
                year = item['year']
                period = item['period']
                month = item['period'][1:]
                unemp_rate = item['value']
                footnotes=""
                for footnote in item['footnotes']:
                    if footnote:
                        footnotes = footnotes + footnote['text'] + ','
                if 'M01' <= period <= 'M12':
                    #x.add_row([countyfips, year,month,unemp_rate,footnotes[0:-1]])
                    county_list.append(countyfips)
                    year_list.append(year)
                    month_list.append(month)
                    unemp_list.append(unemp_rate)
                    footnote_list.append(footnote)
        
        df = pandas.DataFrame({'countyfips': county_list, 
                               'year': year_list, 
                               'month': month_list, 
                               'unemp_rate': unemp_list, 
                               'footnotes': footnote_list})
        df_list.append(df)
    
    df_final = pandas.concat(df_list)
    df_final.to_csv(outstub + 'cty_laus.csv')

    
def log_and_print(message, logger):
    print(message)
    logger.info(message.replace("\n", ""))



if __name__ == "__main__":
    
    LAUS_PATH     = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    AREACODE_PATH = os.path.join(LAUS_PATH, 'docs/')
    LOG_PATH      = os.path.join(LAUS_PATH, 'output/')
    DATA_PATH     = os.path.join(os.path.dirname(os.path.dirname(LAUS_PATH)), 'drive/raw_data/laus/')     
    
    logging.basicConfig(filename = os.path.join(LOG_PATH, 'build.log'), filemode = 'w', 
                        format = '%(asctime)s %(message)s', level = logging.INFO, datefmt = '%Y-%m-%d %H:%M:%S')
    logger = logging.getLogger()
    
    empty_folder = len(os.listdir(DATA_PATH)) == 0
    if not empty_folder:
        sys.exit("Error: Please clear the 'drive/raw_data/laus/' folder before downloading the data.")
    
    
    seriesID_LAUS = create_seriesID_list(AREACODE_PATH)
    log_and_print(f"Series ID created.", logger)
    
    
    current_time = datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")
    log_and_print(f"Start downloading process. Time is {current_time}", logger)
    
    get_data(seriesID_LAUS, "2010", "2019", DATA_PATH)  
    
    log_and_print(f"County-level LAUS series downloaded in ROOT/drive/raw_data/lodes.", logger)
    