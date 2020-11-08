import lifelines
import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from lifelines import CoxPHFitter
from sklearn.model_selection import train_test_split

class CoxPHModel:

    def __init__(self, data):

        self.data = self.transform_data(data)
        self.train, self.test =

    def transform_data(self, data):
        """
        :param data: pandas DataFrame - raw patient and admission data
        :return: patient_df - data with transformed variables needed for modeling
        """
        patient_df = data[data['ICUSTAY_AGE_GROUP'] == 'adult']
        patient_df['survival_time'] = (patient_df['DOD'] - patient_df['intime']) / np.timedelta64(1, 'D')
        patient_df['length_stay'] = (patient_df['outtime'] - patient_df['intime']) / np.timedelta64(1, 'D')
        patient_df['survival_time'] = patient_df['survival_time'].fillna(0)
        patient_df['time'] = patient_df.apply(lambda row: math.floor(max(row.survival_time, row.length_stay)), axis=1)
        patient_df['age_group'] = patient_df['age'].map(lambda x: str(math.floor(x / 10) * 10) + 's')

        return patient_df

    def split_data(self, df):
        """
        :param df: pandas DataFrame
        :return:
        """
        train, test = train_test_split(df, test_size=0.3)

    def fitCoxModel(self, duration, event, predictors):
        """
        :param duration: str - name of column that contains time to event/censorship
        :param event: str - name of binary column of death/censorship
        :param predictors: list<str> - list of columns used for covariates
        :return coxModel: lifelines CoxPHFitter object fit to data
        """
        return model

