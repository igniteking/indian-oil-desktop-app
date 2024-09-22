import sys
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime
#import numpy as np
#import tensorflow as tf
#from tensorflow import keras
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LinearRegression
from sklearn.inspection import PartialDependenceDisplay
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import json  # Import json to format the output as JSON
import joblib

def main():
    if len(sys.argv) != 3:
        error_output = {
            "type": "error",
            "message": "Expected two arguments: dataset path and model path."
        }
        print(json.dumps(error_output))
        return

    data_path = sys.argv[1]  # Capture the dataset path
    model_path = sys.argv[2]  # Capture the model path

    try:
        # Load the dataset
        df_ILI_AK = pd.read_excel(data_path)

        # Columns to select
        columns_to_select = ['Stationing (m)', 'Wall surface', 'Up weld dist (m)', 'Elevation']
        
        # Filter the DataFrame to include only the specified columns
        final_df_ILI_AK = df_ILI_AK.filter(columns_to_select)

        # Label "INT" as 1 and others as 0 in 'Wall surface' column
        final_df_ILI_AK['Wall surface'] = final_df_ILI_AK['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)

        # Drop any rows with NaN values
        df = final_df_ILI_AK.dropna()

        # Load the model
        trained_model = joblib.load(model_path)

        # Get the feature names from the trained model
        model_features = trained_model.feature_names_in_

        # Align the new dataset's columns to the model's expected features
        df_ILI_aligned = df[model_features]

        # Predict using the aligned dataset
        predictions = trained_model.predict(df_ILI_aligned)

        # Create a DataFrame to map input feature values with predictions
        results_df = pd.DataFrame({
            'Stationing (m)': df_ILI_aligned['Stationing (m)'],
            'Prediction': predictions,
            'Actual': df['Wall surface']
        })

        # Filter the rows where 'Actual' is 1
        actual_ones = results_df[results_df['Actual'] == 1]

        # Check for mismatches where prediction is not 1
        mismatches = actual_ones[actual_ones['Prediction'] != 1]
        # Count the number of mismatches
        mismatch_count = mismatches.shape[0]

        # Prepare the mismatches output
        mismatch_output = {
            "type": "data",
            "content": mismatches.to_json(orient="split"),
            "mismatch_count": mismatch_count
        }
        print(json.dumps(mismatch_output))


    except FileNotFoundError as e:
        error_output = {
            "type": "error",
            "message": f"File not found: {e}"
        }
        print(json.dumps(error_output))
    except pd.errors.EmptyDataError as e:
        error_output = {
            "type": "error",
            "message": f"No data in file: {e}"
        }
        print(json.dumps(error_output))
    except pd.errors.ParserError as e:
        error_output = {
            "type": "error",
            "message": f"Error parsing file: {e}"
        }
        print(json.dumps(error_output))
    except Exception as e:
        error_output = {
            "type": "error",
            "message": f"An error occurred: {e}"
        }
        print(json.dumps(error_output))

if __name__ == "__main__":
    main()
