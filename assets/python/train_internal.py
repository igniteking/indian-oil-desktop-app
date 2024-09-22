import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.inspection import PartialDependenceDisplay
import json  # Import json to format the output as JSON
import joblib

def main():
    input_data = sys.argv[1]  # Capture the input passed from Flutter

    try:
        # Load the data from the provided Excel file
        df_ILI = pd.read_excel(input_data)

        # Define columns to select
        columns_to_select = ['Stationing (m)', 'Wall surface', 'Up weld dist (m)', 'Elevation']

        # Filter the dataframe to keep only the selected columns
        final_df_ILI = df_ILI.filter(columns_to_select)

        # Convert 'Wall surface' values to numerical
        final_df_ILI['Wall surface'] = final_df_ILI['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)

        # Drop rows with missing values
        df = final_df_ILI.dropna()

        # Separate features (X) and target class (y)
        X = df.drop(columns=['Wall surface'])
        y = df['Wall surface']
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

        # Train the RandomForestClassifier
        model = RandomForestClassifier()
        model.fit(X_train, y_train)

        # Save the model
        joblib.dump(model, 'model.pkl')

        # Define the features you want to plot PDP for
        features = ['Up weld dist (m)', 'Elevation', 'Stationing (m)']

        # Set the figure size
        plt.figure(figsize=(10, 8))

        # Create PDP
        PartialDependenceDisplay.from_estimator(model, X_train, features)
        plt.title('Partial Dependence Plot')
        plt.xlabel('Features')
        plt.ylabel('Predicted Probability of Corrosion')

        # Save the plot as an image file with a timestamp
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        output_file = f'pdp_{timestamp}.png'
        plt.savefig(output_file)
        plt.close()

        # Get the full path of the saved image
        full_path = os.path.abspath(output_file)

        # Prepare the image output as JSON
        image_output = {
            "type": "image",
            "content": full_path  # Return the image file path
        }
        print(json.dumps(image_output))  # Print the image path as JSON

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
