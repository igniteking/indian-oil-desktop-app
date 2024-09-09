import sys
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

input_data = sys.argv[1]  # This captures the input passed from Flutter
# print(f"Received input: {input_data}")

try:
    # df_ILI = pd.read_excel("./lib/helpers/test2.xlsx")
    df_ILI = pd.read_excel("test2.xlsx")

    # Columns to select
    columns_to_select = ['Stationing (m)', 'Wall surface', 'Up weld dist (m)', 'Elevation']

    # Select the columns using filter
    final_df_ILI = df_ILI.filter(columns_to_select)

    # Label "EXT" as 1, and others as 0
    final_df_ILI['Wall surface'] = final_df_ILI['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)
    df = final_df_ILI.dropna()
    
    # Create a heatmap
    plt.figure(figsize=(10, 8))
    heatmap = sns.heatmap(df.corr(), annot=True, cmap='coolwarm', vmin=-1, vmax=1, center=0)
    
    # Save the heatmap to an image file
    output_file = './heatmap.png'
    plt.savefig(output_file)
    plt.close()
    
    # Print the location of the saved image
    print(output_file)

except FileNotFoundError as e:
    print(f"File not found: {e}")
except Exception as e:
    print(f"An error occurred: {e}")
