from datetime import date
from typing import Union, List
import pandas as pd
from cleaning import fill_na

def blpstring(d: date, fmt="block") -> str:
    """
    :param d: a datetime date object
    :param format: a string which can be `dashed` for dash deparated dates or `block` for blpdates
    :return: A string corresponding to the string yyyymmdd - the format that blpapi likes for ingesting dates
    """
    if fmt != "dashed":
        return d.strftime('%Y%m%d')
    else:
        return str(d)


def write_datasets_to_file(paths: List[str], frames: List[List[pd.DataFrame]]) -> None:
    """
    :param paths: a list of filepaths
    :param frames: a list of lists of dataframes
    """
    for path, frame in zip(paths, frames):
        with open(path, "w"):
            pd.concat(frame).to_csv(path)



def load_dataset(dataset_names: List[str], dataset_valuation_fields: List[str], start_date: date, end_date: date) -> List[pd.DataFrame]:
    output_data = []
    for index in dataset_names:
        frame: pd.DataFrame = con.bdh([index], dataset_valuation_fields, blpstring(start_date), blpstring(end_date))
        frame = fill_na(frame)
        ouput_data.append(frame)
    return output_data
