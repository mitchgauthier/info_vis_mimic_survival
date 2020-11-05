import pandas as pd
import numpy as np
from collections import Counter
import re

static_test_data = pd.read_csv('C:\Google NEU\DS5500 Applications in Data Science\Project\github\data\static_test_data.csv')
static_train_data = pd.read_csv('C:\Google NEU\DS5500 Applications in Data Science\Project\github\data\static_train_data.csv')
static_val_data = pd.read_csv('C:\Google NEU\DS5500 Applications in Data Science\Project\github\data\static_val_data.csv')

diagnoses = pd.read_csv('C:\Google NEU\DS5500 Appliations in Data Science\Project\github\data\diagnoses.csv')

static_train_data = pd.merge(static_train_data, diagnoses, how='inner', on=['hadm_id'])
static_train_data['diagnosis'] = static_train_data['diagnosis'].astype('str')

static_test_data = pd.merge(static_test_data, diagnoses, how='inner', on=['hadm_id'])
static_test_data['diagnosis'] = static_test_data['diagnosis'].astype('str')

static_val_data = pd.merge(static_val_data, diagnoses, how='inner', on=['hadm_id'])
static_val_data['diagnosis'] = static_val_data['diagnosis'].astype('str')

# clean punctuation

punctuation = '!"$%&()*+,-./:;<=>?[]^_`{|}~•@'

def clean_diagnosis(data):
    for mark in punctuation:
        data = data.replace(mark, ' ')
    return data


static_train_data['diagnosis'] = static_train_data.diagnosis.apply(clean_diagnosis)
static_test_data['diagnosis'] = static_test_data.diagnosis.apply(clean_diagnosis)
static_val_data['diagnosis'] = static_val_data.diagnosis.apply(clean_diagnosis)

# EDA for diagnosis

topdiag_temp = static_train_data.copy()

# Look at top diagnoses based on test set

topdiagnoses = pd.DataFrame(topdiag_temp['diagnosis'])
topdiagnoses['count'] = 1

topdiagnoses = topdiagnoses.groupby("diagnosis").agg({"count": np.sum})
topdiagnoses = topdiagnoses.sort_values(by = ['count'], ascending = False)

# Feature Engineer and Encode these Diagnoses

# Clean & Categorize
cardio = ['STEMI', 'CARDIAC','CORONARY', 'ARTERY', 'HEART', 'HYPOTENSION', 'MYOCARDIAL', 'AORTIC', 'VALVE', 'INFARCTION',
          'ARREST', 'BRADYCARDIA', 'STROKE', 'ANGINA', 'PULMONARY', 'PERICARDIAL', 'SYNCOPE',
          'HYPERTENSION', 'HYPERTENSIVE', 'ATRIAL', 'CAROTID', 'CARDIOMYOPATHY', 'ISCHEMIC', 'PULM', 'TACHYCARDIA'
          'CARDIOGENIC', 'VALVE', 'CAROTID', 'VENTRICULAR', 'CAD', 'TACHYCARDIA']
infection = ['PNEUMONIA', 'SEPSIS', 'SEPTIC', 'FEVER', 'UROSEPSIS', 'INFECTION', 'UTI', 'ABSCESS', 'BACTERIAL', 'BACTERMIA', 'HEPATITIS', 'COLITIS']
brain = ['INTRACRANIAL', 'SUBARACHNOID', 'SEIZURE', 'HEAD', 'CEREBROVASCULAR', 'BRAIN', 'INTRACEREBRAL',
         'ANEURYSM', 'CEREBRAL', 'HEADACHE']
mental = ['MENTAL', 'OVERDOSE', 'OD', 'ALCOHOL']
gastro = ['GASTROINTESTINAL', 'GI', 'ABDOMINAL', 'BILE', 'DIARRHEA']
trauma = ['TRAUMA', 'HEMATOMA', 'FALL', 'MOTOR', 'ACCIDENT', 'STRUCK', 'GUN', 'SHOT', 'ASSAULT', 'FRACTURE', 'STAB']
respiratory = ['RESPIRATORY', 'ASTHMA', 'ESOPHAGEAL', 'BREATH', 'DYSPNEA', 'HEMOPTYSIS', 'LUNG', 'AIRWAY', 'TRACHEAL', 'CHEST', 'COPD']
organ = ['LIVER', 'PANCREATITIS', 'RENAL', 'CHOLANGITIS', 'PANCREATIC', 'BLADDER', 'APPENDICITIS', 'CHOLECYSTITIS', 'LIVER',
         'HEPATIC', 'PANCREATITIS', 'SPLENIC', 'CIRRHOSIS']
blood = ['HEMORRHAGE', 'HYPOXIA', 'HYPONATREMIA', 'ANEMIA', 'BLEED', 'DIABETIC', 'HYPERGLYCEMIA', 'HYPOGLYCEMIA', 'HYPERKALEMIA', 'HYPOKALEMIA']
acute = ['ACUTE', 'SHOCK']
failure = ['FAILURE']
cancer = ['CANCER', 'LEUKEMIA', 'LYMPHOMA']
back = ['SPINE', 'SPINAL', 'SCOLIOSIS', 'LUMBAR', 'BACK', 'CORD']
bone = ['FEMUR', 'HIP', 'PELVIC']
pain = ['PAIN']

# categories_all = [cardio, infection, brain, mental, gastro, trauma, respiratory, organ]

topdiag_temp2 = topdiag_temp.copy()

static_train_data['cardio'] = 0
static_train_data['infection'] = 0
static_train_data['brain'] = 0
static_train_data['mental'] = 0
static_train_data['gastro'] = 0
static_train_data['trauma'] = 0
static_train_data['respiratory'] = 0
static_train_data['organ'] = 0
static_train_data['blood'] = 0
static_train_data['acute'] = 0
static_train_data['failure'] = 0
static_train_data['cancer'] = 0
static_train_data['back'] = 0
static_train_data['bone'] = 0
static_train_data['pain'] = 0
static_train_data['other'] = 0
static_train_data['totalcats'] = 0

static_test_data['cardio'] = 0
static_test_data['infection'] = 0
static_test_data['brain'] = 0
static_test_data['mental'] = 0
static_test_data['gastro'] = 0
static_test_data['trauma'] = 0
static_test_data['respiratory'] = 0
static_test_data['organ'] = 0
static_test_data['blood'] = 0
static_test_data['acute'] = 0
static_test_data['failure'] = 0
static_test_data['cancer'] = 0
static_test_data['back'] = 0
static_test_data['bone'] = 0
static_test_data['pain'] = 0
static_test_data['other'] = 0
static_test_data['totalcats'] = 0

static_val_data['cardio'] = 0
static_val_data['infection'] = 0
static_val_data['brain'] = 0
static_val_data['mental'] = 0
static_val_data['gastro'] = 0
static_val_data['trauma'] = 0
static_val_data['respiratory'] = 0
static_val_data['organ'] = 0
static_val_data['blood'] = 0
static_val_data['acute'] = 0
static_val_data['failure'] = 0
static_val_data['cancer'] = 0
static_val_data['back'] = 0
static_val_data['bone'] = 0
static_val_data['pain'] = 0
static_val_data['other'] = 0
static_val_data['totalcats'] = 0


def categorize(data):
    for i in range(len(data['diagnosis'])):
        # find a way to automatically loop through all lists, maybe use dictionary
        # maybe more efficient?
        for condition in cardio:
            if condition in data['diagnosis'][i]:
                data['cardio'][i] = 1
        for condition in infection:
            if condition in data['diagnosis'][i]:
                data['infection'][i] = 1
        for condition in brain:
            if condition in data['diagnosis'][i]:
                data['brain'][i] = 1
        for condition in mental:
            if condition in data['diagnosis'][i]:
                data['mental'][i] = 1
        for condition in gastro:
            if condition in data['diagnosis'][i]:
                data['gastro'][i] = 1
        for condition in trauma:
            if condition in data['diagnosis'][i]:
                data['trauma'][i] = 1
        for condition in respiratory:
            if condition in data['diagnosis'][i]:
                data['respiratory'][i] = 1
        for condition in organ:
            if condition in data['diagnosis'][i]:
                data['organ'][i] = 1
        for condition in blood:
            if condition in data['diagnosis'][i]:
                data['blood'][i] = 1
        for condition in acute:
            if condition in data['diagnosis'][i]:
                data['acute'][i] = 1
        for condition in failure:
            if condition in data['diagnosis'][i]:
                data['failure'][i] = 1
        for condition in cancer:
            if condition in data['diagnosis'][i]:
                data['cancer'][i] = 1
        fosr condition in back:
            if condition in data['diagnosis'][i]:
                data['back'][i] = 1
        for condition in bone:
            if condition in data['diagnosis'][i]:
                data['bone'][i] = 1
        for condition in pain:
            if condition in data['diagnosis'][i]:
                data['pain'][i] = 1
    return data

categorize(static_train_data)
categorize(static_test_data)
categorize(static_val_data)

# sum total categories

static_train_data['totalcats'] = static_train_data[['cardio', 'infection', 'brain', 'mental', 'gastro', 'trauma', 'respiratory',
                                                   'organ', 'blood', 'acute', 'failure', 'cancer', 'back', 'bone', 'pain']].sum(axis=1)

static_test_data['totalcats'] = static_test_data[['cardio', 'infection', 'brain', 'mental', 'gastro', 'trauma', 'respiratory',
                                                   'organ', 'blood', 'acute', 'failure', 'cancer', 'back', 'bone', 'pain']].sum(axis=1)

static_val_data['totalcats'] = static_val_data[['cardio', 'infection', 'brain', 'mental', 'gastro', 'trauma', 'respiratory',
                                                   'organ', 'blood', 'acute', 'failure', 'cancer', 'back', 'bone', 'pain']].sum(axis=1)

#fill in other category

static_train_data['other'] = np.where(static_train_data['totalcats'] == 0, 1, 0)

static_test_data['other'] = np.where(static_test_data['totalcats'] == 0, 1, 0)

static_val_data['other'] = np.where(static_val_data['totalcats'] == 0, 1, 0)


#Export new CSVs

static_test_data.to_csv(r'C:\Users\Insti\Desktop\static_test_data_diag.csv')
static_train_data.to_csv(r'C:\Users\Insti\Desktop\static_train_data_diag.csv')
static_val_data.to_csv(r'C:\Users\Insti\Desktop\static_val_data_diag.csv')


##############################################################################
#check where categories are 0

zeros = static_train_data.loc[static_train_data['totalcats'] == 0]

topdiag_temp2 = zeros.copy()

# Look at top remaining diagnoses again and adjust

topdiagnoses2 = pd.DataFrame(topdiag_temp2['diagnosis'])
topdiagnoses2['count'] = 1

topdiagnoses2 = topdiagnoses2.groupby("diagnosis").agg({"count": np.sum})
topdiagnoses2 = topdiagnoses2.sort_values(by = ['count'], ascending = False)


### COUNT WORDS -- possibly look at later

def count_words(data):
    words = []
    for i in range(len(data['diagnosis'])):
        words.append(data['diagnosis'][i].split())
    word_counts = Counter(words)
    return word_counts


words = topdiag_temp2['diagnosis'][1].split()
counts_of_words = Counter(words)
print (counts_of_words)

tempwords = []

for i in range(len(topdiag_temp2['diagnosis'])-1000):
    tempwords_2 = topdiag_temp2['diagnosis'][i].split()
    for words in tempwords_2:
        print ('inside second for')
        tempwords.append(words)
word_counts = Counter(tempwords)

topdiag_temp2['diagnosis'][1]
categorize(topdiag_temp2)






