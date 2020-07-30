from datetime import date
from typing import List
import os

ROOT_DIR: str = os.path.dirname(os.path.abspath(__file__))
CLEAN_DATA_FOLDER: str = "clean_data"

VALUATION_DATA_PATH_WIN: str = f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\valuation_data.csv"
MACROECONOMIC_DATA_PATH_WIN: str = f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\macroeconomic_data.csv"
SENTIMENT_DATA_PATH_WIN: str = f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\sentiment_data.csv"

start_date: date = date(2019, 1, 1)
end_date: date = date(2020, 1, 1)

# List of sectors that we will pull data on
sectors: List[str] = ["S5INFT Index", "S5FINL Index", "S5ENRS Index", "S5HLTH Index",
                      "S5CONS Index", "S5COND Index", "S5INDU Index", "S5UTIL Index",
                      "S5TELS Index", "S5MATR Index"]

# These will be used to pull sentiment data on the sectors because the indices themselves don't have that available
sector_etfs: List[str] = ["XLK US Equity", "XLF US Equity", "XLE US Equity", "XLV US Equity",
                          "XLP US Equity", "XLY US Equity", "XLI US Equity", "XLU US Equity",
                          "XLC US Equity", "XLB US Equity"]

# List of valuation fields we will pull with regards to each sector
sector_valuation_fields: List[str] = ["PX_LAST", "PE_RATIO", "PX_TO_BOOK_RATIO", "PX_TO_SALES_RATIO",
                                      "FREE_CASH_FLOW_YIELD", "EST_LTG_EPS_AGGTE", "TOT_DEBT_TO_TOT_ASSET",
                                      "EARN_YLD"]

# Fields that will be applied to the sector_etfs to approximate sentiment for the sector indices
sentiment_fields: List[str] = ["PX_LAST", "PUT_CALL_OPEN_INTEREST_RATIO", "EQY_INST_PCT_SH_OUT", "PX_VOLUME"]

# Fields used to pull macroeconomic data from
macroeconomic_indices: List[str] = ["EHGDUS Index", "USGG2YR Index", "USGG10YR Index",
                                    "USURTOT Index", "PRUSTOT Index", "CONSSENT Index",
                                    "CPI YOY Index"]

holidays: List[date] = [date(1994, 4, 27), date(2001, 9, 11), date(2001, 9, 14), date(2004, 6, 11),
                        date(2007, 1, 2), date(2012, 10, 29), date(2012, 10, 30), date(2018, 12, 5)]

days_moving_average: int = 10
