import sys
import os
import pandas as pd
import json
import joblib

def main():
    if len(sys.argv) != 3:
        error_output = {
            "type": "error",
            "message": "Expected two arguments: dataset path and model path."
        }
        print(json.dumps(error_output))
        return

    # Capture the input passed from Flutter
    input_data = sys.argv[1]  # Dataset path
    model_path = sys.argv[2]  # Model path

    try:
        # Load the data from the provided Excel file, specifying the engine manually
        df_ILI = pd.read_excel(input_data, engine='openpyxl')

        # Columns to select
        columns_to_select = ['Stationing (m)', 'Depth (mm)', 'Up weld dist (m)', 'Elevation', 'Wall surface']

        # Select the columns using filter
        final_df_ILI_AK = df_ILI.filter(columns_to_select)

        # Label "INT" as 1, and others as 0
        final_df_ILI_AK['Wall surface'] = final_df_ILI_AK['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)

        df = final_df_ILI_AK.dropna()

        # Output initial data as JSON
        data_output = {
            "type": "data",
            "content": df.to_json(orient="split")  # Convert DataFrame to JSON
        }
        print(json.dumps(data_output))  # Print data as JSON

        # Load the trained model
        trained_model = joblib.load(model_path)

        # Get the model's feature names
        model_features = trained_model.feature_names_in_

        # Align the dataset with the model's expected features
        df_ILI_aligned = df[model_features]

        # Make predictions
        predictions = trained_model.predict(df_ILI_aligned)

        # Map input feature with predictions
        input_feature = 'Stationing (m)'
        results_df = pd.DataFrame({
            input_feature: df_ILI_aligned[input_feature],
            'Prediction': predictions
        })
        results_df['Actual'] = df['Wall surface']

        # Filter rows where 'Actual' is 1
        actual_ones = results_df[results_df['Actual'] == 1]

        # Check for mismatches
        mismatches = actual_ones[actual_ones['Prediction'] != 1]

        # Output mismatches as JSON
        mismatch_output = {
            "type": "data",
            "content": mismatches.to_json(orient="split"),
            "mismatch_count": mismatches.shape[0]
        }
        print(json.dumps(mismatch_output))  # Print mismatches as JSON

    except FileNotFoundError as e:
        error_output = {
            "type": "error",
            "message": f"File not found: {e}"
        }
        print(json.dumps(error_output))  # Print error as JSON
    except pd.errors.EmptyDataError as e:
        error_output = {
            "type": "error",
            "message": f"No data in file: {e}"
        }
        print(json.dumps(error_output))  # Print error as JSON
    except pd.errors.ParserError as e:
        error_output = {
            "type": "error",
            "message": f"Error parsing file: {e}"
        }
        print(json.dumps(error_output))  # Print error as JSON
    except Exception as e:
        error_output = {
            "type": "error",
            "message": f"An error occurred: {e}"
        }
        print(json.dumps(error_output))  # Print error as JSON

if __name__ == "__main__":
    main()
