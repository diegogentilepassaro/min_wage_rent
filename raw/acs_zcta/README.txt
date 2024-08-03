OVERVIEW
========================================================
The code fetch American Community Survey (ACS) zcta-level annual data from the US 
Census via-API and format it in a csv file. 

Tables currently downloaded: 
    'B01003'  # Total Population
    'B25001'  # Total Housing Units
    'B19013'  # Median Household Income
    'B19025'  # Aggregate Household Income
    'B17001'  # Number of Persons Below Poverty Level
    'B00001'  # Unweighted_Sample_Count_Population 2011-2018
    'B00002'  # Unweighted_Sample_Count_Housing 2011-2018
    'B19001'  # Income Distribution
    'B08122'  # Earnings by Workers' Characteristics
    
    # Rent Data
    'B25026'  # Population in Occupied Units 
    'B25057'  # Lower Contract Rent Quartile (Dollars) 
    'B25058'  # Median Contract Rent Quartile (Dollars) 
    'B25059'  # Upper Contract Rent Quartile (Dollars) 
    'B25060'  # Aggregate Contract Rent (Dollars) 
    'B25070'  # Gross Rent as a Percentage of Household Income in the Past 12 Months 



SOURCE
========================================================
Downloaded by Gabriele Borg on August 3rd, 2024 via-API from https://data.census.gov/. 


DESCRIPTION
========================================================
ROOT/drive/raw_data/acs_zcta/		
	
	- acs_zcta_data.csv      annual zcta-level ACS data
