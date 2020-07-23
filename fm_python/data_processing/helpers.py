from datetime import date
from typing import Union, List
import pandas as pd
from cleaning import fill_na
from decorators import NonNullArgs


@NonNullArgs
def blpstring(d: date, fmt="block") -> str:
    """
    :param d: a datetime date object
    :param fmt: a string which can be `dashed` for dash deparated dates or `block` for blpdates
    :return: A string corresponding to the string yyyymmdd - the format that blpapi likes for ingesting dates
    """
    if fmt != "dashed":
        return d.strftime('%Y%m%d')
    else:
        return str(d)


@NonNullArgs
def write_datasets_to_file(paths: List[str], frames: List[List[pd.DataFrame]]) -> None:
    """
    :param paths: a list of filepaths
    :param frames: a list of lists of dataframes
    """
    for path, frame in zip(paths, frames):
        with open(path, "w"):
            pd.concat(frame).to_csv(path)


@NonNullArgs
def load_dataset(dataset_names: List[str], dataset_valuation_fields: List[str], start_date: date, end_date: date, con) -> List[pd.DataFrame]:
    """
    :param dataset_names: list of dataset names to be passed into the con object : List[str]
    :param dataset_valuation_fields: list of fields to pull for each dataset from the con object : List[str]
    :param start_date: start date of the data : datetime.date
    :param end_date: end date of the data : datetime.date
    :param con: connector object for the pdblp api or a database connection object with a matching interface
    :return: A list of dataframes corresponding to those requested with each valuation field as a column
             in every dataset : List[pd.DataFrame]
    """
    output_data = []
    for index in dataset_names:
        frame: pd.DataFrame = con.bdh([index], dataset_valuation_fields, blpstring(start_date), blpstring(end_date))
        frame = fill_na(frame)
        output_data.append(frame)
    return output_data



