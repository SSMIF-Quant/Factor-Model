"""
* ALL rpy2 FUNCTIONALITY IS DISABLED FOR NOW UNTIL THERE IS A NEED TO RUN FACTOR MODEL THROUGH BAILEY
* THIS WILL ONLY RETRIEVE RESULTS FROM FACTOR MODEL TO SHOW ON BAILEY
"""

from datetime import datetime, timedelta
import pandas as pd
import json
import plotly
import plotly.graph_objs as go
import os
from bs4 import BeautifulSoup
import requests
import re
from Risk_API import holdings
# os.environ['R_HOME'] = "C:\\Program Files\\R\\R-3.6.1"  # path to your R installation
# os.environ['R_USER'] = "patel"  # your local username as found by running Sys.info()[["user"]] in R

# from rpy2.robjects.packages import importr, isinstalled
# import rpy2.robjects as ro
# from rpy2.rinterface import RRuntimeError  # or "from rpy2.rinterface_lib.embedded import RRuntimeError" if you're on the latest rpy2 (i.e. not on Windows)


# TODO: add more api endpoints to bailey that allows access to more information gathered during modelling
# TODO: allow privileged user to run factor model on bailey (but this would essentially freeze all other bailey functionality for almost 2 hours while factor model runs -- multiple workers on pythonanywhere?)


GRAPHICS_STYLE = {'cumulativeReturns.png': {'alt': 'cumulative returns all', 'style': 'width:100%'},
                  'cumulativeReturnsTest.png': {'alt': 'cumulative returns test period', 'style': 'width:100%'},
                  'cumulativeReturnsSem.png': {'alt': 'cumulative returns semester', 'style': 'width:100%'},
                  'modelAssessment.png': {'alt': 'model performance', 'style': 'width:100%'},
                  'sectorReturns.png': {'alt': 'sector returns all', 'style': 'width:100%'},
                  'stats.png': {'alt': 'comparative stats', 'style': 'width:45%; float:left;'},
                  'weights.png': {'alt': 'model weights', 'style': 'width:45%; float:right;'}}


class FactorModel:

    def __init__(self, flask_root_path):
        self.model_path = flask_root_path.replace("flaskr", "Factor-Model")
        self.weights = self.getWeights()

    # def run(self, save=True):
    #     t_start = datetime.now()
    #     self.load_packages()
    #     self.load_data()
    #     self.run_models()
    #     self.find_weights()
    #     self.backtest()
    #     t_end = datetime.now()
    #     if save:
    #         self.save_workspace()
    #     print('All done! Took ' + str(t_end - t_start))

    # def load_packages(self):
    #     try:
    #         # Try to load packages directly through R
    #         package_load = open(os.path.join(self.model_path, 'packageLoad.R')).read()
    #         ro.r(package_load)
    #     except RRuntimeError:
    #         # Otherwise load packages one by one using importr
    #         with open(self.model_path + "/packages.txt") as f:
    #             packages = f.read().splitlines()
    #         try:
    #             assert all([isinstalled(x) for x in packages])
    #         except RRuntimeError as e:
    #             print("Make sure all packages are installed within R first, then re-run")
    #             return
    #         xts = importr("xts", robject_translations={".subset.xts": "_subset_xts2", "to.period": "to_period2"})
    #         for package in [x for x in packages if x != 'xts']:  # already imported xts specially so don't do it again
    #             importr(package)
    #     print("Package Loading: Done!")
    #     return True

    # def load_data(self):
    #     data_load_code = open(os.path.join(self.model_path, 'DataLoad.R')).read()
    #     var_block = data_load_code[
    #                 :data_load_code.find("\n\n# Retrieve new data and/or load in existing data\ntryCatch")]
    #     try_block = data_load_code[data_load_code.find(
    #         "# First try to connect to Bloomberg and retrieve new data"):data_load_code.find("\n  },\n  error")]
    #     finally_block = data_load_code[
    #                     data_load_code.find("# This is where all the data that was saved above gets loaded in"):][:-7]
    #
    #     ro.r(var_block)
    #     try:
    #         ro.r(try_block)
    #     except RRuntimeError:
    #         print("Not logged into Bloomberg or not on terminal, defaulting to existing data...")
    #     finally:
    #         os.chdir('./Factor-Model')
    #         ro.r(finally_block)
    #     print("Loading Data: Done!")
    #     return True

    # def run_models(self, linear=True, arima=True, rf=True):
    #     ro.r("""
    #         size <- 0
    #         accuracyMatrix <- matrix(nrow = 1,ncol = length(sectorNames))
    #         colnames(accuracyMatrix) <- sectorNames
    #     """)
    #
    #     if linear:
    #         linear_model = open(os.path.join(self.model_path, 'linearAnalysis.R')).read()
    #         ro.r(linear_model)
    #         print('Linear Analysis: Done!')
    #     if arima:
    #         arima_model = open(os.path.join(self.model_path, 'arimaAnalysis.R')).read()
    #         ro.r(arima_model)
    #         print('ARIMA Analysis: Done!')
    #     if rf:
    #         rf_model = open(os.path.join(self.model_path, 'randomForestAnalysis.R')).read()
    #         ro.r(rf_model)
    #         print('Random Forest Analysis: Done!')
    #
    #     return True

    # def find_weights(self):
    #     optimization = open(os.path.join(self.model_path, 'geneticBreedv2.R')).read()
    #     ro.r(optimization)
    #     self.weights = pd.DataFrame({'Sector': list(ro.r("sectorNames")), 'Weight': list(ro.r("weightsVector"))})
    #     print("Optimization: Done!")

    # def backtest(self):
    #     backtest = open(os.path.join(self.model_path, 'fullTest.R')).read()
    #     ro.r(backtest)
    #     print("Backtesting: Done!")

    # def save_workspace(self, include_models=False):
    #     if not include_models:
    #         ro.r("""remove(linear_models, arima_models, randomForest_models)""")
    #     ro.r("""save.image(file.path(savePath, ".RData"))""")

    # def load_workspace(self, path):
    #     ro.r("""load("{}")""".format(path.replace("/", "//")))

    def get_backtest_stats(self):
        stats = pd.read_csv(os.path.join(self.model_path, 'results', self.getRecentResultsDate(), 'stats.csv'))
        return stats

    # def get_accuracy_matrix(self):
    #     res = None
    #     try:
    #         res = pd.DataFrame({'Sector': list(ro.r("sectorNames")),
    #                             'Linear Regression': list(ro.r("accuracyMatrix[1, ]")),
    #                             'ARIMA Analysis': list(ro.r("accuracyMatrix[2, ]")),
    #                             'Random Forest': list(ro.r("accuracyMatrix[3, ]"))}).set_index("Sector").T
    #     except RRuntimeError:
    #         print("Make sure all the models have been ran before fetching the accuracy matrix")
    #     return res

    def getRecentResultsDate(self):
        run_dates = os.listdir(self.model_path + '/results')
        max_date = max([int(x) for x in run_dates if '.' not in x])
        return str(max_date)

    def getGraphics(self):
        max_date = self.getRecentResultsDate()
        imgs = os.listdir(self.model_path + '/results/' + max_date)
        imgs = [x for x in imgs if '.png' in x]

        srcs, alts, styles = [], [], []
        for img in imgs:
            srcs.append(img)
            alts.append(GRAPHICS_STYLE[img]['alt'])
            styles.append(GRAPHICS_STYLE[img]['style'])

        return {'src': srcs, 'alt': alts, 'style': styles}

    def getWeights(self):
        weights = self.getHistoricalWeights().iloc[-1, ]
        return {weights.index.values[i]: weights.iloc[i] for i in range(2, len(weights))}

    def getHistoricalWeights(self, format_pct=False):
        res = pd.read_csv(self.model_path + '/results/weightsHistory.csv')
        if format_pct:
            res.iloc[:, 2:] = [['{:.0f}%'.format(float(y) * 100) for y in x] for x in res.iloc[:, 2:].values]
        return res

    def getRecentDataDate(self):
        spx = pd.read_csv(self.model_path + '/data/SPX.csv')
        return spx['date'].iloc[-1]

    def newDataAvailable(self):
        recent_run = datetime.strptime(self.getRecentResultsDate(), '%Y%m%d')
        recent_data = datetime.strptime(self.getRecentDataDate(), '%Y-%m-%d')
        return recent_data > recent_run

    def plotWeights(self):
        weights = self.weights
        weights = {k: v for k, v in weights.items() if v > 0}
        real_weights = self.getActualAllocations()
        graph = dict(
            data=[go.Bar(
                    text=['<b>Optimal ' + sector + ' weight: </b> {:.2f}%'.format(weight*100)
                          for sector, weight in weights.items()],
                    x=list(weights.keys()),
                    y=list(weights.values()),
                    hoverinfo="text",
                    name='Factor Model Weights',
                ),
                go.Bar(
                    text=['<b>Current ' + sector + ' weight: </b> {:.2f}%'.format(weight*100)
                          for sector, weight in list(real_weights.items())],
                    x=list(real_weights.keys()),
                    y=list(real_weights.values()),
                    hoverinfo='text',
                    name='Current Weights',
                )
            ],
            layout=dict(
                title="Optimal Portfolio Weights",
                margin=dict(b=30, r=0, t=50, l=0),
                paper_bgcolor='rgba(0,0,0,0)',
                plot_bgcolor='rgba(0,0,0,0)',
                legend=dict(x=0.5, y=-0.2, xanchor='center', orientation='h')
            )
        )
        fig = go.FigureWidget(data=graph['data'], layout=graph['layout'])
        graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
        return graphJSON
