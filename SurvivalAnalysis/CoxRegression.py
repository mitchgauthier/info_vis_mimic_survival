import lifelines
import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from lifelines import CoxPHFitter
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, MinMaxScaler


class CoxPHModel:

    def fit_model(self, data, duration, event, predictors):
        """
        :param data: Pandas Dataframe
        :param duration: str - name of column that contains time to event/censorship
        :param event: str - name of binary column of death/censorship
        :param predictors: list<str> - list of columns used for covariates
        :return coxModel: lifelines CoxPHFitter object fit to data
        """
        # Filter data for predictors
        train_data = data[[duration, event] + predictors]

        # Initialize and Fit Cox Proportional Hazards Model
        model = CoxPHFitter()
        model.fit(train_data, duration_col=duration, entry_col=event)

        return model

    def find_strong_vars(self, model, weight=None, num_var=None):
        """
        :param model: Lifelines CoxPHFitter - trained model object
        :param weight: float - minimum coefficient threshold for variables
        :param num_var: integer - top number of coefficients to be used
        :return strong_vars: list<str> - strongest variables by coefficient
        """
        # Create Series w/ absolute coefficient values
        cox_vars = model.summary.coef.abs()

        # Determine which metric will be used for selection
        if weight is not None:
            strong_vars = cox_vars[cox_vars > weight].index.to_list()
        elif num_var is not None:
            strong_vars = cox_vars.sort_values(ascending=False).index[:num_var].to_list()

        return strong_vars

    def generate_survival_function(self, model, data):
        """
        :param model: lifelines CoxPHFitter - trained Cox model
        :param data: pandas Dataframe -
        :return :
        """
        # Generate Survival Curves and Risk v. Time by patient
        curves = model.predict_survival_function(data)
        risks = curves.applymap(self.ClassifyRisk)

        return curves, risks

    def classify_risk(self, score):
        """
        :param score: float - Survival Probability from Regression
        :return:
        """

        if score >= 0.9:
            risk = 'Level 1'
        elif score >= 0.8:
            risk = 'Level 2'
        elif score >= 0.7:
            risk = 'Level 3'
        elif score >= 0.6:
            risk = 'Level 4'
        else:
            risk = 'Level 5'

        return risk

    def score_model(self, model, data):
        """
        :param model: Lifelines CoxPHFitter - trained model object
        :param data: Pandas DataFrame - data w/ same fields as model
        :return score: float - Concordance Index of Cox Model
        """
        score = model.score(data, scoring_method='concordance_index')

        return score