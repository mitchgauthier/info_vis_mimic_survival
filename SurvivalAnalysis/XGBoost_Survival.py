import numpy as np
import pandas as pd
import xgboost as xgb
from sksurv.metrics import concordance_index_censored


class XGBoostSurvival:

    def transform_data(self, data, duration, event, predictors=None, censor=None):
        """
        :param data: Pandas DataFrame - Preprocessed Data with Targets & Predictors
        :param duration: string - Name of column that pertains to time-to-event
        :param event: string - Name of column of 0-1 death/censorship flag
        :param predictors: list<str> - Names of columns of predictor variables
        :param censor: integer - Number of dates until censorship
        :return d_train: Dmatrix - Correct model input for XGBoost
        """
        # Use censor to generate target vector
        if censor is None:
            censor = data.time.max()
        target = data.time.apply(lambda x: -x if x == censor else x)

        # Format data to work with XGBoost
        data_input = data.drop([duration, event], axis=1)
        if predictors is not None:
            data_input = data_input[predictors]

        d_train = xgb.DMatrix(data_input, label=target)
        return d_train

    def train_model(self, data, params, num_estimators):
        """
        :param data: DMatrix - Training Data in XGBoost format
        :param params: dict - Parameters for model (max_depth, learning_rate, etc.)
        :param num_estimators: Number of Regression trees to aggregate
        :return model: XGBoost model object - Model trained on data given params
        """
        model = xgb.train(params, data, num_estimators)
        return model

    def predict_risk(self, model, test_data):
        """
        :param model: XGBoost model object - Trained Survival Model
        :param test_data: DMatrix - Test data in XGBoost format
        :return risks: array, shape=(n_observed, ) - Predicted risk for each patient
        """
        pred = model.predict(test_data)
        return pred

    def evaluate_model(self, event, duration, pred):
        """
        :param event: Pandas Series - 0/1 flags for whether patient died
        :param duration: Pandas Series - Time to death/censorship as integers
        :param pred: array, shape=(n_observed, ) - predictions from trained model
        :return c_index: float - Concordance Index of Model against test data
        """
        event_flag = event.apply(lambda x: False if x == 0 else True)
        c_index, concord, discord, tie_risk, tie_time = concordance_index_censored(event_flag, duration, pred)
        return c_index

