import numpy as np
import pandas as pd
import math
from sklearn.preprocessing import StandardScaler, MinMaxScaler


class Utils:

    def clean_data(self, data):
        """
        :param data: pandas DataFrame - raw patient and admission data
        :return: patient_df - data with transformed variables needed for modeling
        """
        # Convert TimeDelta to integer
        data['time'] = pd.to_timedelta(data['time_until_death']) / np.timedelta64(1, 'D')
        # Set censorship to max survival
        data.time = data.time.fillna(data.time.max()).apply(math.floor)
        # Select variables that will be used for modeling
        t_data = pd.concat([data[['time', 'anytime_expire_flag', 'icu_admit_age']],
                            data.loc[:, 'female':'TSICU'],
                            data.loc[:, 'cardio':'other']], axis=1)
        # Scale Numerical variables to match range of one-hot variables
        scaler = MinMaxScaler()
        t_data.icu_admit_age = scaler.fit_transform(t_data.icu_admit_age.values.reshape(-1, 1))

        return t_data