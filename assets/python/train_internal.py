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
    input_data = sys.argv[1]  # Capture the input passed from Flutter

    try:

        df_ILI = pd.read_excel(input_data)

        # Columns to select (Distance from the pumping location, wall surface locatiom, upweld distance, elevation)
        columns_to_select = ['Stationing (m)','Wall surface', 'Up weld dist (m)','Elevation']

        # Select the columns using filter
        final_df_ILI = df_ILI.filter(columns_to_select)

        # Label "EXT" as 1, and others as 0
        final_df_ILI['Wall surface'] = final_df_ILI['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)

        df = final_df_ILI.dropna()

        df

        # Separate features (X) and target class (y)
        X = df.drop(columns=['Wall surface'])
        y = df['Wall surface']

        # Split the data into training and testing sets
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

        # Train the RandomForestClassifier
        model = RandomForestClassifier()
        model.fit(X_train, y_train)

        # Save the model
        joblib.dump(model, 'model.pkl')

        # Define the features you want to plot PDP for
        features = ['Up weld dist (m)', 'Elevation', 'Stationing (m)']

        # Create PDP
        PartialDependenceDisplay.from_estimator(model, X_train, features)
        plt.title('Partial Dependence Plot')
        plt.xlabel('features')
        plt.ylabel('Predicted Probability of Corrosion')
        plt.show()

        # Save the plot as an image
        plt.savefig('partial_dependence_plot.png')  # You can choose other formats like .jpg or .pdf
        plt.show()


        columns_to_select = ['Stationing (m)','Depth (mm)', 'Up weld dist (m)','Elevation','Wall surface']
        # Select the columns using filter
        df_ILI_reg = df_ILI.filter(columns_to_select)

        # Display the final DataFrame
        # print(df_ILI_reg)

        # Filter the DataFrame to select only rows where 'column_name' is 'EXT'
        df_reg = df_ILI_reg[df_ILI_reg['Wall surface'] == 'INT']

        df_reg = df_reg.dropna()

        X_reg = df_reg[['Up weld dist (m)','Elevation','Stationing (m)']]  # Feature
        y_reg = df_reg['Depth (mm)']

        # Split the data into training and testing sets
        X_train_reg, X_test_reg, y_train_reg, y_test_reg = train_test_split(X_reg, y_reg, test_size=0.2, random_state=42)

        # Create and train the model
        model_reg = LinearRegression()
        model_reg.fit(X_train_reg, y_train_reg)

        # Make predictions
        y_pred_reg = model_reg.predict(X_test_reg)

        # Create a DataFrame to compare actual and predicted values
        comparison_df_length = pd.DataFrame({'Actual': y_test_reg, 'Predicted': y_pred_reg})

        # Print a message
        # print("Here is the comparison of actual vs predicted depth values at the locations of internal corrosion :")

        data_output = {
            "type": "data",
            "content": comparison_df_length.to_json(orient="split")  # Convert the DataFrame to JSON format
        }
       
        print(json.dumps(data_output))  # Print the DataFrame as JSON

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
