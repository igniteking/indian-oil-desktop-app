import sys
import pandas as pd

input_data = sys.argv[1]  # This captures the input passed from Flutter
print(f"Received input: {input_data}")

try:
    # df_ILI = pd.read_excel("./lib/helpers/test.xlsx")
    df_ILI = pd.read_excel("test.xlsx")
    print(df_ILI)
except FileNotFoundError as e:
    print(f"File not found: {e}")
except Exception as e:
    print(f"An error occurred: {e}")