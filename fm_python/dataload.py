import pandas as pd
import pdblp
from typing import List
from helpers import blpstring, write_datasets_to_file, load_dataset
from constants import sectors, sector_valuation_fields, start_date, end_date, macroeconomic_indices,\
                      sector_etfs, sentiment_fields, ROOT_DIR, CLEAN_DATA_FOLDER, VALUATION_DATA_PATH_WIN,\
                      MACROECONOMIC_DATA_PATH_WIN, SENTIMENT_DATA_PATH_WIN


macroeconomic_data: List[pd.DataFrame] = []
sentiment_data: List[pd.DataFrame] = []
valuation_data: List[pd.DataFrame] = []

try:
    con = pdblp.BCon(timeout=30000)
    con.start()

    spx: pd.DataFrame = con.bdh(['SPX Index'], ['PX_LAST'], blpstring(start_date), blpstring(end_date))

    valuation_data = load_dataset(sectors, sector_valuation_fields, sector_valuation_fields, start_date, end_date, con)
    macroeconomic_data = load_dataset(macroeconomic_indices, ['PX_LAST'], [], start_date, end_date, con, case="macro")
    sentiment_data = load_dataset(sector_etfs, sentiment_fields, sentiment_fields, start_date, end_date, con)

    if len(sentiment_data) == 0 or len(valuation_data) == 0 or len(macroeconomic_data) == 0:
        raise ValueError("Unable to load some of the data, check Bloomberg API and internet connection")

except BaseException:
    print(BaseException("Error loading datasets from blp"))

try:
    paths: List[str] = [VALUATION_DATA_PATH_WIN, MACROECONOMIC_DATA_PATH_WIN, SENTIMENT_DATA_PATH_WIN]
    datasets: List[List[pd.DataFrame]] = [valuation_data, macroeconomic_data, sentiment_data]
    labels: List[List[str]] = [sectors, macroeconomic_indices, sector_etfs]
    write_datasets_to_file(paths, datasets, labels)

except FileNotFoundError:
    print("cannot find clean data folder")
    raise FileNotFoundError
