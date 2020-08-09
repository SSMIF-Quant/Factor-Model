from datetime import date
from typing import List
import pandas as pd
import numpy as np
from cleaning import fill_na
from decorators import NonNullArgs
from typing import List, Any, Dict
from os import listdir

@NonNullArgs
def list_files(directory: str, extension: str) -> Any:
    """
    List all of the files with a certain extension in a directory
    :param directory: directory in which to search (first level)
    :param extension: extension to search for (ex: csv, py, java, ...)
    :return: a list of strings of filepaths
    """
    return (f for f in listdir(directory) if f.endswith('.' + extension))

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
def write_datasets_to_file(paths: List[str], frames_lists: List[List[pd.DataFrame]], labels_list: List[str]) -> None:
    """
    :param paths: a list of filepaths
    :param frames_lists: a list of lists of dataframes
    """
    for path, frames, labels in zip(paths, frames_lists, labels_list):
        for frame, label in zip(frames, labels):
            save_path: str = path.split(".csv")[0]
            save_path += (label + ".csv")
            with open(save_path, "w"):
                frame.to_csv(save_path)


@NonNullArgs
def load_dataset(dataset_names: List[str], dataset_valuation_fields: List[str], colnames: List[str], start_date: date,
                 end_date: date, con, case: str =None) -> List[pd.DataFrame]:
    """
    :param dataset_names: list of dataset names to be passed into the con object : List[str]
    :param dataset_valuation_fields: list of fields to pull for each dataset from the con object : List[str]
    :param start_date: start date of the data : datetime.date
    :param end_date: end date of the data : datetime.date
    :param con: connector object for the pdblp api or a database connection object with a matching interface
    :param case: controls special behavior of the function
    :return: A list of dataframes corresponding to those requested with each valuation field as a column
             in every dataset : List[pd.DataFrame]
    """
    output_data = []
    i: int = 0
    for index in dataset_names:
        frame = con.bdh([index], dataset_valuation_fields, blpstring(start_date), blpstring(end_date))
        if case == "macro":
            frame.columns = ["PX_LAST"]
        elif case != "macro":
            frame.columns = colnames
        frame = fill_na(frame)
        output_data.append(frame)
        i += 1
    return output_data


@NonNullArgs
def train_test_split(X, Y, train_size=0.8, gap=10):
    assert (len(X) == len(Y))
    n: int = len(X)
    train_end: int = int(n * train_size)
    assert ((train_end + gap) < n)
    test_start: int = train_end + gap

    x_tr = X[:train_end]
    x_te = X[test_start:]
    y_tr = Y[:train_end]
    y_te = Y[test_start:]

    return x_tr, x_te, y_tr, y_te
