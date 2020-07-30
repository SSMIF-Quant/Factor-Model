import pandas as pd

from ..data_processing.constants import  VALUATION_DATA_PATH_WIN, MACROECONOMIC_DATA_PATH_WIN, SENTIMENT_DATA_PATH_WIN


valuation_data: pd.DataFrame = pd.read_csv(VALUATION_DATA_PATH_WIN)
macroeconomic_data: pd.DataFrame = pd.read_csv(MACROECONOMIC_DATA_PATH_WIN)
sentiment_data: pd.DataFrame = pd.read_csv(SENTIMENT_DATA_PATH_WIN)

valuation_data.add_prefix("val_")
macroeconomic_data.add_prefix("macro_")
sentiment_data.add_prefix("sent_")

valuation_data.head()
macroeconomic_data.head()
sentiment_data.head()