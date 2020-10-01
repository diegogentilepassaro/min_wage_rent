#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Sep 30 16:12:17 2020

@author: gabriborg
"""

import sys
import os
import logging
import requests
import zipfile
from fredapi import Fred

fred = Fred(api_key=os.environ.get('FRED_API_KEY'))


unemp_tables = fred.search('unemployment county')


