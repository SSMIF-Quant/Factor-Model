# import numpy as np
# import pandas as pd
# import matplotlib.pyplot as pt
# from tensorflow.keras.layers import DenseFeatures
# from tensorflow.estimator import LinearClassifier
# from ..data_processing.constants import sectors, sector_valuation_fields, sector_etfs, sentiment_fields, macroeconomic_indices, ROOT_DIR, CLEAN_DATA_FOLDER
# import itertools
#
# valuation_data: pd.DataFrame = pd.load_csv(f"{ROOT_DIR}/{CLEAN_DATA_FOLDER}/valuation_data.csv")
# sentiment_data: pd.DataFrame = pd.load_csv(f"{ROOT_DIR}/{CLEAN_DATA_FOLDER}/sentiment_data.csv")
# macroeconomic_data: pd.DataFrame = pd.load_csv(f"{ROOT_DIR}/{CLEAN_DATA_FOLDER}/macroeconomic_data.csv")
#
# for sector, sector_etf in zip(sectors, sector_etfs):
#     # Perform a separate evaluation for every sector in the "sectors" list
#     # https://stackoverflow.com/questions/18470323/selecting-columns-from-pandas-multiindex
#     # sector_val_data = valuation_data.loc[:, list(itertools.product([sector], sector_valuation_fields))]
#     # sentiment_data = sentiment_data.loc[:, list(itertools.product([sector_etf], sentiment_fields))]
#     val_training_data = valuation_data[sector].select(lambda x: x[1] in sector_valuation_fields, axis=1)
#     sent_training_data = sentiment_data[sector_etf].select(lambda x: x[1] in sentiment_fields, axis=1)
#     macro_training_data = macroeconomic_data
# TODO: GET A CLEANER WAY TO LOAD THIS DATA IN