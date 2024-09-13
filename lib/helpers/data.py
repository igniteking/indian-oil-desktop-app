import sys
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime

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

        # Create and save a heatmap of the dataframe's correlations
        plt.figure(figsize=(10, 8))
        heatmap = sns.heatmap(df.corr(), annot=True, cmap='coolwarm', vmin=-1, vmax=1, center=0)

        # Save the heatmap to an image file with a timestamp
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        output_file = f'heatmap_{timestamp}.png'
        plt.savefig(output_file)
        plt.close()

        # Get the full path of the saved image and print it
        full_path = os.path.abspath(output_file)
        print(full_path)

    except FileNotFoundError as e:
        print(f"ERROR: File not found: {e}")
    except pd.errors.EmptyDataError as e:
        print(f"ERROR: No data in file: {e}")
    except pd.errors.ParserError as e:
        print(f"ERROR: Error parsing file: {e}")
    except Exception as e:
        print(f"ERROR: An error occurred: {e}")

if __name__ == "__main__":
    main()
