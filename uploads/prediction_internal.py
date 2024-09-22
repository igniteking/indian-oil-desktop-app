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
        # Load the data from the provided Excel file
        df_ILI = pd.read_excel(data_path)

        # Columns to select
        columns_to_select = ['Stationing (m)', 'Depth (mm)', 'Up weld dist (m)', 'Elevation', 'Wall surface']
        final_df_ILI_AK = df_ILI.filter(columns_to_select)

        # Label "INT" as 1, and others as 0
        final_df_ILI_AK['Wall surface'] = final_df_ILI_AK['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)

        df = final_df_ILI_AK.dropna()

        # Prepare the data output
        data_output = {
            "type": "data",
            "content": df.to_json(orient="split")  # Convert the DataFrame to JSON format
        }
        print(json.dumps(data_output))  # Print the DataFrame as JSON

        # Load the model
        trained_model = joblib.load("model.pkl")

        # Get the feature names from the trained model
        model_features = trained_model.feature_names_in_

        # Align the new dataset's columns to the model's expected features
        df_ILI_aligned = df[model_features]

        # Predict using the aligned and preprocessed dataset
        predictions = trained_model.predict(df_ILI_aligned)

        # Create a DataFrame to map input feature values with predictions
        input_feature = 'Stationing (m)'
        results_df = pd.DataFrame({
            input_feature: df_ILI_aligned[input_feature],
            'Prediction': predictions
        })

        results_df['Actual'] = df['Wall surface']

        # Filter the rows where 'Actual' is 1
        actual_ones = results_df[results_df['Actual'] == 1]

        # Check for mismatches with 'Prediction' column where 'Actual' is 1
        mismatches = actual_ones[actual_ones['Prediction'] != 1]

        # Print the rows where there are mismatches
        print("Mismatches between actual vs predicted locations:")
        print(mismatches)

        # Prepare the mismatches output
        mismatch_output = {
            "type": "data",
            "content": mismatches.to_json(orient="split"),  # Convert the DataFrame to JSON format
            "mismatch_count": mismatches.shape[0]
        }
        print(json.dumps(mismatch_output))  # Print the mismatches as JSON

    except FileNotFoundError as e:
        error_output = {
            "type": "error",
            "message": f"File not found: {e}"
        }
        print(json.dumps(error_output))  # Print the error as JSON
    except pd.errors.EmptyDataError as e:
        error_output = {
            "type": "error",
            "message": f"No data in file: {e}"
        }
        print(json.dumps(error_output))  # Print the error as JSON
    except pd.errors.ParserError as e:
        error_output = {
            "type": "error",
            "message": f"Error parsing file: {e}"
        }
        print(json.dumps(error_output))  # Print the error as JSON
    except Exception as e:
        error_output = {
            "type": "error",
            "message": f"An error occurred: {e}"
        }
        print(json.dumps(error_output))  # Print the error as JSON

if __name__ == "__main__":
    main()
