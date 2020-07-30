from constants import VALUATION_DATA_PATH_WIN, MACROECONOMIC_DATA_PATH_WIN, SENTIMENT_DATA_PATH_WIN, ROOT_DIR, CLEAN_DATA_FOLDER
import numpy as np
import pandas as pd
from typing import Union, List
from helpers import list_files


def main() -> None:
    """
    main function for the linear regression module of the SSMIF Factor Model
    :return: None
    """
    [print(filepath) for filepath in list_files(f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\", "csv")]



    # valuation_data: Union[None, pd.DataFrame] = None
    # macroeconomic_data: Union[None, pd.DataFrame] = None
    # sentiment_data: Union[None, pd.DataFrame] = None
    #
    # prefixes: List[str] = ["_val", "macro_", "sent_"]
    # paths: List[str] = [VALUATION_DATA_PATH_WIN, MACROECONOMIC_DATA_PATH_WIN, SENTIMENT_DATA_PATH_WIN]
    #
    # data: Union[None, List[pd.DataFrame]] = [valuation_data, macroeconomic_data, sentiment_data]
    # for prefix, path, dat in zip(prefixes, paths, data):
    #     dat: Union[None, pd.DataFrame] = pd.read_csv(path)
    #     print(dat.head())
    #     dat.add_prefix(prefix)

    # if None not in data:
    #     master_dataframe: pd.DataFrame = pd.concat(data)
    # else:
    #     raise ValueError("Could not read data")
    #
    # print(master_dataframe.head())


if __name__ == "__main__":
    main()