import os
os.environ['R_HOME'] = "C:\\Program Files\\R\\R-3.6.1"  # path to your R installation
os.environ['R_USER'] = "patel"  # your local username as found by running Sys.info()[["user"]] in R

from rpy2.robjects.packages import importr, isinstalled
import rpy2.robjects as ro
from rpy2.rinterface import RRuntimeError

from datetime import datetime
import pandas as pd


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
        self.model_path = flask_root_path.replace("\\flaskr", "\\Factor_Model")
        self.weights = None

    def run(self):
        t_start = datetime.now()
        self.load_packages()
        self.load_data()
        self.run_models()
        self.find_weights()
        self.backtest()
        t_end = datetime.now()
        print('All done! Took ' + str(t_end - t_start))

    def load_packages(self):
        try:
            # Try to load packages directly through R
            package_load = open(os.path.join(self.model_path, 'packageLoad.R')).read()
            ro.r(package_load)
        except RRuntimeError:
            # Otherwise load packages one by one using importr
            with open(self.model_path + "\\packages.txt") as f:
                packages = f.read().splitlines()
            try:
                assert all([isinstalled(x) for x in packages])
            except RRuntimeError as e:
                print("Make sure all packages are installed within R first, then re-run")
                return
            xts = importr("xts", robject_translations={".subset.xts": "_subset_xts2", "to.period": "to_period2"})
            for package in [x for x in packages if x != 'xts']:  # already imported xts specially so don't do it again
                importr(package)
        print("Package Loading: Done!")
        return True

    def load_data(self):
        data_load_code = open(os.path.join(self.model_path, 'DataLoad.R')).read()
        var_block = data_load_code[
                    :data_load_code.find("\n\n# Retrieve new data and/or load in existing data\ntryCatch")]
        try_block = data_load_code[data_load_code.find(
            "# First try to connect to Bloomberg and retrieve new data"):data_load_code.find("\n  },\n  error")]
        finally_block = data_load_code[
                        data_load_code.find("# This is where all the data that was saved above gets loaded in"):][:-7]

        ro.r(var_block)
        try:
            ro.r(try_block)
        except RRuntimeError:
            print("Not logged into Bloomberg or not on terminal, defaulting to existing data...")
        finally:
            os.chdir('./Factor-Model')
            ro.r(finally_block)
        print("Loading Data: Done!")
        return True

    def run_models(self, linear=True, arima=True, rf=True):
        ro.r("""
            size <- 0
            accuracyMatrix <- matrix(nrow = 1,ncol = length(sectorNames))
            colnames(accuracyMatrix) <- sectorNames
        """)

        if linear:
            linear_model = open(os.path.join(self.model_path, 'linearAnalysis.R')).read()
            ro.r(linear_model)
            print('Linear Analysis: Done!')
        if arima:
            arima_model = open(os.path.join(self.model_path, 'arimaAnalysis.R')).read()
            ro.r(arima_model)
            print('ARIMA Analysis: Done!')
        if rf:
            rf_model = open(os.path.join(self.model_path, 'randomForestAnalysis.R')).read()
            ro.r(rf_model)
            print('Random Forest Analysis: Done!')

        return True

    def find_weights(self):
        optimization = open(os.path.join(self.model_path, 'geneticBreedv2.R')).read()
        ro.r(optimization)
        self.weights = pd.DataFrame({'Sector': list(ro.r("sectorNames")), 'Weight': list(ro.r("weightsVector"))})
        print("Optimization: Done!")

    def backtest(self):
        backtest = open(os.path.join(self.model_path, 'fullTest.R')).read()
        ro.r(backtest)
        print("Backtesting: Done!")

    def save_workspace(self, include_models=False):
        if not include_models:
            ro.r("""remove(linear_models, arima_models, randomForest_models)""")
        ro.r("""save.image(file.path(savePath, ".RData"))""")

    def load_workspace(self, path):
        ro.r("""load("{}")""".format(path.replace("\\", "\\\\")))

    def get_backtest_stats(self):
        stats = pd.DataFrame({'Metric': list(ro.r("as.character(stats$Metric)")),
                              'Portfolio': list(ro.r("as.character(stats$Portfolio)")),
                              'SPX': list(ro.r("as.character(stats$SPX)"))})
        return stats

    def get_accuracy_matrix(self):
        res = None
        try:
            res = pd.DataFrame({'Sector': list(ro.r("sectorNames")),
                                'Linear Regression': list(ro.r("accuracyMatrix[1, ]")),
                                'ARIMA Analysis': list(ro.r("accuracyMatrix[2, ]")),
                                'Random Forest': list(ro.r("accuracyMatrix[3, ]"))}).set_index("Sector").T
        except RRuntimeError:
            print("Make sure all the models have been ran before fetching the accuracy matrix")
        return res

    def getRecentDataDate(self):
        run_dates = os.listdir(self.model_path + '\\results')
        max_date = max([int(x) for x in run_dates if '.' not in x])
        return str(max_date)

    def getGraphics(self):
        max_date = self.getRecentDataDate()
        imgs = os.listdir(self.model_path + '\\results\\' + max_date)
        imgs = [x for x in imgs if '.png' in x]

        srcs, alts, styles = [], [], []
        for img in imgs:
            srcs.append(img)
            alts.append(GRAPHICS_STYLE[img]['alt'])
            styles.append(GRAPHICS_STYLE[img]['style'])

        return {'src': srcs, 'alt': alts, 'style': styles}
