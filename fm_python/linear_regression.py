from constants import VALUATION_DATA_PATH_WIN, MACROECONOMIC_DATA_PATH_WIN, SENTIMENT_DATA_PATH_WIN, ROOT_DIR, \
    CLEAN_DATA_FOLDER, sectors, sector_etfs, train_size, gap
import numpy as np
import pandas as pd
from typing import List, Dict
from helpers import list_files, train_test_split
from sklearn.metrics import mean_squared_error, mean_squared_log_error, mean_tweedie_deviance, mean_poisson_deviance, \
    mean_absolute_error, mean_gamma_deviance, r2_score
from sklearn.linear_model import LinearRegression

def main() -> None:
    """
    main function for the linear regression module of the SSMIF Factor Model
    :return: None
    """
    filepaths: List[str] = [filepath for filepath in list_files(f"{ROOT_DIR}\\{CLEAN_DATA_FOLDER}\\", "csv")]

    sector_log_price_predictions: Dict = dict()
    sector_coefficients: Dict = dict()
    sector_mse: Dict = dict()
    sector_msle: Dict = dict()
    sector_mean_tweedie_deviance: Dict = dict()
    sector_mean_poisson_deviance: Dict = dict()
    sector_mean_absolute_error: Dict = dict()
    sector_mean_gamma_deviance: Dict = dict()
    sector_r2_score: Dict = dict()

    X_train: Dict = dict()
    y_train: Dict = dict()
    X_test: Dict = dict()
    y_test: Dict = dict()

    for sector in sectors:
        # First add valuation data
        sector_paths = [filepath for filepath in filepaths if filepath.__contains__(sector)]

        # Then read the csvs
        data = [pd.read_csv(f"{CLEAN_DATA_FOLDER}\\{path}") for path in sector_paths]

        # Put them all together (one sector's data)
        dataset = pd.concat(data).drop(columns=["field"])

        # dataset.droplevel(0)
        # print(dataset.head())
        # Add a log-price column
        dataset["log-price"] = np.log(dataset["PX_LAST"])

        Y = dataset["log-price"]
        X = dataset.drop(columns=["log-price", "PX_LAST"])

        # Datasets are now of the form {'S5FNIL Index' : pd.DataFrame(valuation data + macroeconomic data)}
        x_tr, x_te, y_tr, y_te = train_test_split(X, Y, train_size=train_size, gap=gap)

        # Then save
        X_train[sector] = x_tr
        y_train[sector] = y_tr
        X_test[sector] = x_te
        y_test[sector] = x_te

        model = LinearRegression()

        model.fit(x_tr, y_tr)

        model_predictions: List[float] = model.predict(x_te)
        sector_coefficients[sector] = model.coef_

        sector_log_price_predictions[sector] = model_predictions
        sector_mse[sector] = mean_squared_error(y_te, model_predictions)
        sector_msle[sector] = mean_squared_log_error(y_te, model_predictions)
        sector_mean_tweedie_deviance[sector] = mean_tweedie_deviance(y_te, model_predictions)
        sector_mean_poisson_deviance[sector] = mean_poisson_deviance(y_te, model_predictions)
        sector_mean_absolute_error[sector] = mean_absolute_error(y_te, model_predictions)
        sector_mean_gamma_deviance[sector] = mean_gamma_deviance(y_te, model_predictions)
        sector_r2_score[sector] = r2_score(y_te, model_predictions)






if __name__ == "__main__":
    main()