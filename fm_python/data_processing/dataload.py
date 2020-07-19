import pandas as pd
import numpy as np
import pdblp
from typing import List
from datetime import date
from constants import holidays, sectors, sector_valuation_fields, start_date, end_date

def blpstring(d: date) -> str:
    """
    :param d: a datetime date object
    :return: A string corresponding to the string yyyymmdd - the format that blpapi likes for ingesting dates
    """
    return d.strftime('%Y%m%d')


master_dataframe_list: List[pd.DataFrame] = []

try:
    con = pdblp.BCon()
    con.start()

    spx: pd.DataFrame = con.bdh(['SPX Index'], ['PX_LAST'], blpstring(start_date), blpstring(end_date))

    for index in sectors:
        master_dataframe_list.append(con.bdh([index], sector_valuation_fields, blpstring(start_date), blpstring(end_date)))

except (ValueError, ConnectionError):
    print("cannot load data from bloomberg")

print(len(master_dataframe_list))
print(len(master_dataframe_list[2]))
for x in range(len(master_dataframe_list)):
    print(master_dataframe_list[x].columns)
