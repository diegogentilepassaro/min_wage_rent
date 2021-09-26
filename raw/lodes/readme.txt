OVERVIEW
========================================================
LEHD Origin-Destination Employment Statistics (LODES) data. Data files are state-based and 
organized into three types: Origin-Destination (OD), Residence Area Characteristics (RAC), 
and Workplace Area Characteristics (WAC), all at census block geographic detail. 

Data is available for most states for the years 2002–2017.

SOURCE
========================================================
Data downloaded by Santiago Hermo on October 2th 2020 from https://lehd.ces.census.gov/data/


Data was redownloaded by Santiago Hermo on September 25th 2021 for 2009--2018. For OD matrices,
we only downloaded files for total jobs (JT00).

See https://github.com/diegogentilepassaro/min_wage_rent/issues/130


DESCRIPTION
========================================================
/ROOT/raw/lodes/docs 		Documentation files from https://lehd.ces.census.gov/php/inc_lodesFiles.php

/ROOT/raw/lodes/code 		Python script to download data, adapted from https://github.com/UrbanInstitute/lodes-data-downloads
				HOW TO RUN: go to `ROOT/raw/lodes/code` in cmd and type `python build.py` in your python 2.7 Anaconda environment

/ROOT/raw/lodes/output		Locally stored output from running code

ROOT/drive/raw_data/LODES/*	Downloaded files

IMPORTANT NOTE: The states of Alaska (AK) and South Dakota (SD) do not have files for 2017. We manually downloaded the 2016 
files and changed the name appropriately.



