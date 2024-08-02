import os
import requests
import pandas as pd
import gzip
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
from tqdm import tqdm
from ratelimit import limits, sleep_and_retry
import logging
import numpy as np
from typing import Union
import glob


# Your API key
API_KEY = 'f0aadefd118cba2a1047e3f4be068bb384908cb2'

CALLS_PER_SECOND = 500  # Adjust this based on API limits

# Define the API endpoint
BASE_URL = 'https://api.census.gov/data'

# Define the years to fetch data for
YEARS = range(2011, 2023)  # ACS 5-year estimates are typically available up to 2-3 years before the current year

# Define the tables and variables we want to fetch
TABLES_AND_VARIABLES = {
    
    # Population and Housing Data
    'B01003': ['B01003_001E'],  # Total Population
    'B25001': ['B25001_001E'],  # Total Housing Units
    'B19013': ['B19013_001E'],  # Median Household Income
    'B19025': ['B19025_001E'],  # Aggregate Household Income
    'B17001': ['B17001_002E'],  # Number of Persons Below Poverty Level
    'B00001': ['B00001_001E'],  # Unweighted_Sample_Count_Population
    'B00002': ['B00002_001E'],  # Unweighted_Sample_Count_Housing
    'B19001': ['B19001_002E', 'B19001_003E', 'B19001_004E', 'B19001_005E', 
               'B19001_006E', 'B19001_007E', 'B19001_008E', 'B19001_009E', 
               'B19001_010E', 'B19001_011E', 'B19001_012E', 'B19001_013E', 
               'B19001_014E', 'B19001_015E', 'B19001_016E', 'B19001_017E'],  # Income Distribution
    'B08122': ['B08122_001E', 'B08122_002E', 'B08122_003E', 'B08122_004E', 'B08122_005E'],  # Earnings by Workers' Characteristics
    
    # Rent Data
    'B25026': ['B25026_001E', 'B25026_002E', 'B25026_009E'],  # Population in Occupied Units 
    'B25057': ['B25057_001E'],  # Lower Contract Rent Quartile (Dollars) 
    'B25058': ['B25058_001E'],  # Median Contract Rent Quartile (Dollars) 
    'B25059': ['B25059_001E'],  # Upper Contract Rent Quartile (Dollars) 
    'B25060': ['B25060_001E'],  # Aggregate Contract Rent (Dollars) 
    'B25070': ['B25070_001E', 'B25070_002E', 'B25070_003E', 
               'B25070_004E', 'B25070_005E', 'B25070_006E', 
               'B25070_007E', 'B25070_008E', 'B25070_009E', 
               'B25070_010E', 'B25070_011E'],  # Gross Rent as a Percentage of Household Income in the Past 12 Months 


}


# Specify the geographic level
GEO = 'zip code tabulation area:*'

def save_progress(year, data):
    with open(f'acs_{year}.json', 'w') as f:
        json.dump(data.to_dict(), f)

def load_progress(year):
    if os.path.exists(f'acs_{year}.json'):
        with open(f'acs_{year}.json', 'r') as f:
            return pd.DataFrame.from_dict(json.load(f))
    return None

def get_dataset_name(year):
    return f"{year}/acs/acs5"


def fetch_all_data_for_year(year):
    all_data = []
    for table, variables in TABLES_AND_VARIABLES.items():
        table_data = []
        offset = 0
        has_more_data = True
        while has_more_data:
            df, has_more_data = fetch_data_for_zctas(year, table, variables, offset)
            if df is None:
                break
            logging.info(f"Final {variables} for {year}:Table {table} {df.columns}")
            table_data.append(df)
            offset += len(df)
            if not has_more_data:
                break
        
        if table_data:
            combined_table_data = pd.concat(table_data, ignore_index=True)
            all_data.append(combined_table_data)
        else:
            logger.warning(f"No data available for year {year}, table {table}")
    
    if all_data:
        combined_df = pd.concat(all_data, axis=1)
        combined_df = combined_df.loc[:,~combined_df.columns.duplicated()]
        combined_df['Year'] = year
            
        logging.info(f"Final Columns for {year}: {combined_df.columns}")

        return combined_df
    else:
        return None
    

@sleep_and_retry
@limits(calls=CALLS_PER_SECOND, period=1)
def fetch_data_for_zctas(year, table, variables, offset=0):
    dataset = get_dataset_name(year)
    columns = ['NAME'] + variables
    geo_levels = [
        'zip code tabulation area:*',
        'county:*',
        'state:*'
    ]
    
    for geo in geo_levels:
        url = f"{BASE_URL}/{dataset}?get={','.join(columns)}&for={geo}&key={API_KEY}&offset={offset}"
        
        try:
            logger.info(f"Attempting to fetch data for year {year}, table {table}, geo {geo}, offset {offset}")
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            data = response.json()
            df = pd.DataFrame(data[1:], columns=data[0])
            logger.info(f"Successfully fetched {len(df)} rows for year {year}, table {table}, geo {geo}, offset {offset}")
            return df, len(df) == 50000  # Census API returns max 50000 rows per request
        except requests.exceptions.RequestException as e:
            logger.warning(f"Error fetching data for year {year}, table {table}, geo {geo}, offset {offset}: {e}")
    
    logger.error(f"Failed to fetch data for year {year}, table {table} at all geographic levels")
    return None, False

 
def test_data_availability():
    for year in YEARS:
        logger.info(f"Testing year {year}")
        for table, variables in TABLES_AND_VARIABLES.items():
            df, _ = fetch_data_for_zctas(year, table, variables, offset=0)
            if df is not None and not df.empty:
                logger.info(f"  Table {table} is available for year {year}. Sample size: {len(df)}")
            else:
                logger.warning(f"  Table {table} is not available for year {year}")
        logger.info("")

def process_final_dataset(df):
    # Rename columns for clarity
    column_names = {
        'zip code tabulation area': 'zcta',
        'B01003_001E': 'Total_Population',
        'B25001_001E': 'Total_Housing_Units',
        'B19013_001E': 'Median_Household_Income',
        'B19025_001E': 'Aggregate_Household_Income',
        'B17001_002E': 'Persons_Below_Poverty_Level',
        'B00001_001E': 'Unweighted_Sample_Count_Population',
        'B00002_001E': 'Unweighted_Sample_Count_Housing',
        'B19001_002E': 'Income_Less_10000',
        'B19001_003E': 'Income_10000_14999',
        'B19001_004E': 'Income_15000_19999',
        'B19001_005E': 'Income_20000_24999',
        'B19001_006E': 'Income_25000_29999',
        'B19001_007E': 'Income_30000_34999',
        'B19001_008E': 'Income_35000_39999',
        'B19001_009E': 'Income_40000_44999',
        'B19001_010E': 'Income_45000_49999',
        'B19001_011E': 'Income_50000_59999',
        'B19001_012E': 'Income_60000_74999',
        'B19001_013E': 'Income_75000_99999',
        'B19001_014E': 'Income_100000_124999',
        'B19001_015E': 'Income_125000_149999',
        'B19001_016E': 'Income_150000_199999',
        'B19001_017E': 'Income_200000_or_more',
        'B08122_001E': 'Workers_16_and_over',
        'B08122_002E': 'Workers_Earning_1_to_9999',
        'B08122_003E': 'Workers_Earning_10000_to_14999',
        'B08122_004E': 'Workers_Earning_15000_to_24999',
        'B08122_005E': 'Workers_Earning_25000_to_34999',
        'B25026_001E': 'total_occ_housing_units', 
        'B25026_002E': 'owner_occ_housing_units', 
        'B25026_009E': 'renter_occ_housing_units', 
        'B25057_001E': 'rent_p25', 
        'B25058_001E': 'rent_median', 
        'B25059_001E': 'rent_p75', 
        'B25060_001E': 'rent_aggregate', 
        'B25070_001E': 'rent_share_hh_income_Total', 
        'B25070_002E': 'rent_share_hh_income_10pct', 
        'B25070_003E': 'rent_share_hh_income_10_15pct', 
        'B25070_004E': 'rent_share_hh_income_15_20pct', 
        'B25070_005E': 'rent_share_hh_income_20_25pct', 
        'B25070_006E': 'rent_share_hh_income_20_30pct', 
        'B25070_007E': 'rent_share_hh_income_30_35pct', 
        'B25070_008E': 'rent_share_hh_income_35_40pct', 
        'B25070_009E': 'rent_share_hh_income_40_45pct', 
        'B25070_010E': 'rent_share_hh_income_45_50pct', 
        'B25070_011E': 'rent_share_hh_income_50Pluspct', 
    }

    df = df.rename(columns=column_names)
    
    # Convert relevant columns to numeric type
    for col in df.columns:
        if col.startswith(('B', 'Income_', 'Workers_', 'Total_', 'Median_', 'Aggregate_', 'Persons_', 'Universe_', 'Unweighted_')):
            df[col] = pd.to_numeric(df[col], errors='coerce')

    # Calculate derived variables    

    # Calculate mean household income
    if 'Aggregate_Household_Income' in df.columns and 'Total_Housing_Units' in df.columns:
        df['Mean_Household_Income'] = df['Aggregate_Household_Income'] / df['Total_Housing_Units'].replace(0, np.nan)
    else:
        logger.warning("Unable to calculate Mean_Household_Income due to missing data")

    # Calculate number of low income workers (earning less than $25,000 per year)
    low_income_columns = ['Workers_Earning_1_to_9999', 'Workers_Earning_10000_to_14999', 'Workers_Earning_15000_to_24999']
    if all(col in df.columns for col in low_income_columns):
        df['Low_Income_Workers'] = df[low_income_columns].sum(axis=1)
    else:
        logger.warning("Unable to calculate Low_Income_Workers due to missing data")

    # Calculate approximate sample size (this is an approximation, not the actual sample size)
    if 'Total_Housing_Units' in df.columns and 'Unweighted_Sample_Count_Housing' in df.columns:
        df['Approximate_Sample_Size_Housing'] = df['Unweighted_Sample_Count_Housing'] / df['Total_Housing_Units'] 
        logger.info(f"Approximate_Sample_Size - Housing column created. Sample values: {df['Approximate_Sample_Size_Housing'].head().tolist()}")
    else:
        logger.warning("Unable to calculate Approximate_Sample_Size Housing due to missing data")

    if 'Total_Population' in df.columns and 'Unweighted_Sample_Count_Population' in df.columns:
        df['Approximate_Sample_Size_Population'] = df['Unweighted_Sample_Count_Population'] / df['Total_Population'] 
        logger.info(f"Approximate_Sample_Size - Population column created. Sample values: {df['Approximate_Sample_Size_Population'].head().tolist()}")
    else:
        logger.warning("Unable to calculate Approximate_Sample_Size Population due to missing data")

    # Check for missing variables
    expected_columns = list(column_names.values()) + ['Mean_Household_Income', 'Low_Income_Workers', 
        'Approximate_Sample_Size_Housing', 'Approximate_Sample_Size_Population']
    missing_columns = [col for col in expected_columns if col not in df.columns]
    if missing_columns:
        logger.warning(f"The following expected columns are missing from the dataset: {missing_columns}")

    index_cols = ['zcta', 'Year']
    return df[index_cols + [x for x in df.columns if x not in index_cols]]


if __name__ == "__main__":
        
    # Initialize paths
    output_path = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    output_path = os.path.join(output_path, 'output')
    if not os.path.exists(output_path):
        os.makedirs(output_path)
    
    root_path  = os.path.dirname(
        os.path.dirname(
            os.path.dirname(
                os.path.dirname(
                    os.path.realpath(__file__)))))
    
    data_path  = os.path.join(root_path, "drive", "raw_data", "acs_zcta")
    
    # Initialize log file
    logging.basicConfig(filename = os.path.join(output_path, 'build.log'), filemode = 'w', 
                        format = '%(asctime)s %(message)s', level = logging.INFO, datefmt = '%Y-%m-%d %H:%M:%S')
    logger = logging.getLogger()
    
    # Run the test_data_availability function if needed
    # test_data_availability()
    n_workers = 5
    with ThreadPoolExecutor(max_workers=n_workers) as executor:
        future_to_year = {}
        all_years_data = []
        for year in YEARS:
            existing_data = load_progress(year)
            if existing_data is not None:
                all_years_data.append(existing_data)
                logger.info(f"Loaded existing data for year {year}")
            else:
                future_to_year[executor.submit(fetch_all_data_for_year, year)] = year

        for future in tqdm(as_completed(future_to_year), total=len(future_to_year), desc="Overall Progress"):
            year = future_to_year[future]
            try:
                data = future.result()
                if data is not None and not data.empty:
                    all_years_data.append(data)
                    save_progress(year, data)
                    logger.info(f"Data fetched successfully for year {year}")
                else:
                    logger.warning(f"No data available for year {year}")
            except Exception as exc:
                logger.error(f"Error fetching data for year {year}: {exc}", exc_info=True)

    if all_years_data:
        final_df = pd.concat(all_years_data, ignore_index=True)
        
        logger.info(f"Columns in the raw dataset: {final_df.columns.tolist()}")
        
        final_df = process_final_dataset(final_df)
        
        logger.info(f"Columns in the processed dataset: {final_df.columns.tolist()}")
        logger.info(f"Number of rows in the final dataset: {len(final_df)}")
        logger.info(f"Sample of the final dataset:\n{final_df.head()}")

        # Save as compressed CSV
        if not os.path.exists(data_path):
            os.mkdir(data_path)
        final_df.to_csv(os.path.join(data_path, 'acs_zcta_data.csv'), index=False)
        logger.info(f"Data saved to {data_path}")
        # Remove the temporary JSON files
        json_list = glob.glob(f"{os.getcwd()}/*.json")
        for file in json_list:
            os.remove(file)
        logger.info("Temporary JSON files removed!")
    else:
        logger.warning("No data was fetched for any year.")
