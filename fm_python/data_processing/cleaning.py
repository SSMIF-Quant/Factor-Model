import pandas as pd
import numpy as np
from datetime import date
from constants import holidays


def remove_holidays_and_fill_na(frame: pd.DataFrame) -> pd.DataFrame:
    """
    :param frame: input data frame
    :return: the data frame with all of the holiday values removed and all empty values replaced with the previous
             valid value
    """
    frame: pd.DataFrame = frame.drop(holidays)
    return frame.fillna(method='ffill', inplace=True)
