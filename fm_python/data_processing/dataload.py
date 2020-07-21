import pandas as pd
import pdblp
from typing import List
from helpers import blpstring, write_datasets_to_file
from cleaning import fill_na
from constants import holidays, sectors, sector_valuation_fields, start_date, end_date, macroeconomic_indices, sector_etfs, sentiment_fields, ROOT_DIR, CLEAN_DATA_FOLDER


macroeconomic_data: List[pd.DataFrame] = []
sentiment_data: List[pd.DataFrame] = []
valuation_data: List[pd.DataFrame] = []

try:
    con = pdblp.BCon(timeout=30000)
    con.start()

    spx: pd.DataFrame = con.bdh(['SPX Index'], ['PX_LAST'], blpstring(start_date), blpstring(end_date))

    for index in sectors:
        frame: pd.DataFrame = con.bdh([index], sector_valuation_fields, blpstring(start_date), blpstring(end_date))
        frame = fill_na(frame)
        valuation_data.append(frame)

    for index in macroeconomic_indices:
        frame: pd.DataFrame = con.bdh(index, ['PX_LAST'], blpstring(start_date), blpstring(end_date))
        frame = fill_na(frame)
        macroeconomic_data.append(frame)

    for index in sector_etfs:
        frame: pd.DataFrame = con.bdh(index, sentiment_fields, blpstring(start_date), blpstring(end_date))
        frame = fill_na(frame)
        sentiment_data.append(frame)

    if len(sentiment_data) == 0 or len(valuation_data) == 0 or len(macroeconomic_data) == 0:
        print("Unable to load some of the data, check Bloomberg API and internet connection")
        raise ValueError

except BaseException:
    print(BaseException)

try:
    paths: List[str] = [f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\valuation_data.csv", f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\macroeconomic_data.csv", f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\sentiment_data.csv"]
    datasets: List[List[pd.DataFrame]] = [valuation_data, macroeconomic_data, sentiment_data]

    write_datasets_to_file(paths, datasets)

except FileNotFoundError:
    print("cannot find clean data folder")
    raise FileNotFoundError
