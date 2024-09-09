import sys
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime

def main():
    if len(sys.argv) != 2:
        sys.exit(1)

    input_data = sys.argv[1]

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

        # Create the heatmap
        plt.figure(figsize=(10, 8))
        heatmap = sns.heatmap(df.corr(), annot=True, cmap='coolwarm', vmin=-1, vmax=1, center=0)

        # Define the uploads directory
        output_dir = os.path.join(os.getcwd(), 'uploads')

        # Create the directory if it doesn't exist
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        # Delete any old heatmap files in the directory
        for file in os.listdir(output_dir):
            if file.startswith('heatmap_') and file.endswith('.png'):
                os.remove(os.path.join(output_dir, file))

        # Create a new filename with the timestamp
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        output_file = os.path.join(output_dir, f'heatmap_{timestamp}.png')

        # Save the new heatmap
        plt.savefig(output_file)
        plt.close()

        # Print the full path of the saved image for Flutter to capture
        full_path = os.path.abspath(output_file)
        print(full_path)

    except FileNotFoundError as e:
        print(f"File not found: {e}")
    except pd.errors.EmptyDataError as e:
        print(f"No data in file: {e}")
    except pd.errors.ParserError as e:
        print(f"Error parsing file: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
