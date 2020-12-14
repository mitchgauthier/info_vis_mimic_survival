import pandas as pd
import numpy as np
from sklearn.model_selection import GridSearchCV
import xgboost as xgb


class GridSearch:

    def perform_search(self, train_input, train_target, model, param_grid,
                       scoring_method, cv=10):
        """
        :param train_input: Array, Pandas Dataframe, DMatrix - Predictor Variables of training data
        :param train_target: Array, Pandas Dataframe, DMatrix - Target Variables of training data
        :param model: XGBoost, sklearn model object - Model to be trained and evaluated at each iteration
        :param param_grid: dict - lists of different values for each parameter to test
        :param scoring_method: str, callable - evaluation metric to be optimized in Grid Search
        :param cv: int - number of folds to partition data into
        :return:
        """
        grid = GridSearchCV(
            estimator=model,
            param_grid=param_grid,
            cv=cv,
            n_jobs=-1,
            scoring=scoring_method,
            verbose=2
        )
        model = grid.fit(train_input, train_target)
        return model