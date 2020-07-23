import pandas as pd
from typing import Union
from decorators import NonNullArgs


@NonNullArgs
def fill_na(frame: Union[pd.DataFrame, pd.MultiIndex]) -> Union[pd.DataFrame, pd.MultiIndex]:
    """
    :param frame: input data frame
    :return: the data frame with all empty values replaced with the previous
             valid value. If there is no previous value, replace with the next valid value
    """
    return frame.fillna(method='ffill', inplace=False).fillna(method="bfill", inplace=False)
