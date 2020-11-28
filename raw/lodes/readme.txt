OVERVIEW
========================================================
LEHD Origin-Destination Employment Statistics (LODES) data. Data files are state-based and 
organized into three types: Origin-Destination (OD), Residence Area Characteristics (RAC), 
and Workplace Area Characteristics (WAC), all at census block geographic detail. 

Data is available for most states for the years 2002–2017.

SOURCE
========================================================
Data downloaded by Santiago hermo on October 2th 2020 from https://lehd.ces.census.gov/data/


DESCRIPTION
========================================================
/ROOT/raw/lodes/docs 		Documentation files from https://lehd.ces.census.gov/php/inc_lodesFiles.php

/ROOT/raw/lodes/code 		Python script to download data, adapted from https://github.com/UrbanInstitute/lodes-data-downloads
				HOW TO RUN: go to `ROOT/raw/lodes/code` in cmd and type `python build.py` in your python 2.7 Anaconda environment

/ROOT/raw/lodes/output		Locally stored output from running code

ROOT/drive/raw_data/LODES/*	Downloaded files

IMPORTANT NOTE: The states Alaska (AK) and South Dakota (sd) do not have files for 2017. We manually downloaded the 2016 files 
and changed the name appropriately.



