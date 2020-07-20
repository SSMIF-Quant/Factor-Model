import pandas as pd
import numpy as np
import pdblp
from typing import List
from datetime import date
from helpers import blpstring
from cleaning import remove_holidays_and_fill_na
from constants import holidays, sectors, sector_valuation_fields, start_date, end_date, macroeconomic_indices, sector_etfs, sentiment_fields


master_dataframe_list: List[pd.DataFrame] = []
macroeconomic_data: List[pd.DataFrame] = []
sentiment_data: List[pd.DataFrame] = []
valuation_data: List[pd.DataFrame] = []

try:
    con = pdblp.BCon()
    con.start()

    spx: pd.DataFrame = con.bdh(['SPX Index'], ['PX_LAST'], blpstring(start_date), blpstring(end_date))

    for index in sectors:
        frame: pd.DataFrame = con.bdh([index], sector_valuation_fields, blpstring(start_date), blpstring(end_date))
        frame = remove_holidays_and_fill_na(frame)
        master_dataframe_list.append(frame)
        valuation_data.append(frame)

    for index in macroeconomic_indices:
        frame: pd.DataFrame = con.bdh(con.bdh(index, ['PX_LAST'], blpstring(start_date), blpstring(end_date)))
        frame = remove_holidays_and_fill_na(frame)
        master_dataframe_list.append(frame)
        macroeconomic_data.append(frame)

    for index in sector_etfs:
        frame: pd.DataFrame = con.bdh(con.bdh(index, sentiment_fields, blpstring(start_date), blpstring(end_date)))
        frame = remove_holidays_and_fill_na(frame)
        master_dataframe_list.append(frame)
        valuation_data.append(frame)


except (ValueError, ConnectionError):
    print("cannot load data from bloomberg")

print(len(master_dataframe_list))
print(len(master_dataframe_list[2]))
for x in range(len(master_dataframe_list)):
    print(master_dataframe_list[x].columns)
