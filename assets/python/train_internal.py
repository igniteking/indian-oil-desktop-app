#!/usr/bin/env python
# coding: utf-8

import sys
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime
import json  # Import json to format the output as JSON
import joblib
from sklearn.inspection import PartialDependenceDisplay
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LinearRegression

def main():
    input_data = sys.argv[1]  # Capture the input passed from Flutter

    try:
        # Read the input Excel file
        df_ILI = pd.read_excel(input_data)

        # Columns to select (Distance from the pumping location, wall surface location, upweld distance, elevation)
        columns_to_select = ['Stationing (m)', 'Wall surface', 'Up weld dist (m)', 'Elevation', 'Depth (mm)']
        final_df_ILI = df_ILI.filter(columns_to_select)

        # Label "INT" as 1, and others as 0
        final_df_ILI['Wall surface'] = final_df_ILI['Wall surface'].apply(lambda x: 1 if x == 'INT' else 0)

        # Clean the DataFrame by dropping rows with NaN values in the selected columns
        final_df_ILI = final_df_ILI.dropna(subset=columns_to_select)

        # Separate features (X) and target class (y)
        X = final_df_ILI.drop(columns=['Wall surface'])
        y = final_df_ILI['Wall surface']

        # Ensure that lengths match
        print("Number of samples in X:", len(X))
        print("Number of samples in y:", len(y))

        # Split the data into training and testing sets
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

        # Train the RandomForestClassifier
        model = RandomForestClassifier()
        model.fit(X_train, y_train)

        # Save the model
        joblib.dump(model, 'model.pkl')

        # 1. Create PDP
        features = ['Up weld dist (m)', 'Elevation', 'Stationing (m)']
        PartialDependenceDisplay.from_estimator(model, X_train, features)
        plt.title('Partial Dependence Plot')
        plt.xlabel('Features')
        plt.ylabel('Predicted Probability of Corrosion')

        # Create a timestamp for the image filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        pdp_plot_path = f'partial_dependence_plot_{timestamp}.png'  # Filename with timestamp

        # Save the PDP plot as an image
        plt.savefig(pdp_plot_path, bbox_inches='tight')  # Use bbox_inches='tight' to avoid cutting off
        plt.close()

        # 2. Feature Importance Plot
        importances = model.feature_importances_
        feature_names = X.columns

        plt.figure(figsize=(8, 6))  # Increased figure size
        sns.barplot(x=importances, y=feature_names)
        plt.title('Feature Importance for Internal Corrosion Prediction')
        plt.xlabel('Importance')
        plt.ylabel('Features')

        fi_plot_path = f'feature_importance_plot_{timestamp}.png'

        # Save the feature importance plot as an image
        plt.savefig(fi_plot_path, bbox_inches='tight')  # Use bbox_inches='tight'
        plt.close()

        # 3. Box Plot for Corrosion Depth by Wall Surface
        plt.figure(figsize=(6, 4))
        sns.boxplot(x='Wall surface', y='Depth (mm)', data=final_df_ILI)
        plt.title('Distribution of Corrosion Depth by Wall Surface')
        plt.xlabel('Wall Surface')
        plt.ylabel('Corrosion Depth (mm)')

        box_plot_path = f'box_plot_{timestamp}.png'

        # Save the box plot as an image
        plt.savefig(box_plot_path, bbox_inches='tight')  # Use bbox_inches='tight'
        plt.close()

        # 4. Actual vs Predicted Corrosion Depth Plot with Respect to Stationing
        # Linear regression model for corrosion depth prediction
        X_reg = final_df_ILI[['Stationing (m)', 'Up weld dist (m)', 'Elevation']].dropna()
        y_reg = final_df_ILI['Depth (mm)'].dropna()

        # Ensure consistency in the regression dataset
        if len(X_reg) == len(y_reg):
            X_train_reg, X_test_reg, y_train_reg, y_test_reg = train_test_split(X_reg, y_reg, test_size=0.2, random_state=42)
            model_reg = LinearRegression()
            model_reg.fit(X_train_reg, y_train_reg)
            y_pred_reg = model_reg.predict(X_test_reg)

            # Create a DataFrame to compare actual and predicted values
            comparison_df_stationing = pd.DataFrame({
                'Stationing (m)': X_test_reg['Stationing (m)'],  # Get the stationing values from the test set
                'Actual': y_test_reg,
                'Predicted': y_pred_reg
            })

            # Prepare output for comparison
            comparison_output = {
                "type": "data",
                "content": comparison_df_stationing.to_json(orient="split")  # Convert the DataFrame to JSON format
            }

            print(json.dumps(comparison_output))  # Print the comparison DataFrame as JSON
            # Sort by Stationing for better visualization
            comparison_df_stationing = comparison_df_stationing.sort_values(by='Stationing (m)')

            # Create the figure and axis for the plot
            plt.figure(figsize=(12, 6))
            plt.plot(comparison_df_stationing['Stationing (m)'], comparison_df_stationing['Actual'], label='Actual Depth (mm)', color='blue', marker='o', linestyle='-', markersize=5)
            plt.plot(comparison_df_stationing['Stationing (m)'], comparison_df_stationing['Predicted'], label='Predicted Depth (mm)', color='green', marker='x', linestyle='--', markersize=5)

            # Add title and labels
            plt.title('Actual vs Predicted Corrosion Depth with Respect to Stationing', fontsize=14, fontweight='bold')
            plt.xlabel('Stationing (m)', fontsize=12)
            plt.ylabel('Corrosion Depth (mm)', fontsize=12)

            # Add grid and legend
            plt.grid(True)
            plt.legend(loc='upper right', fontsize=10)

            # Save the plot
            stationing_plot_path = f'stationing_comparison_plot_{timestamp}.png'
            plt.tight_layout()
            plt.savefig(stationing_plot_path, bbox_inches='tight')  # Use bbox_inches='tight'
            plt.close()

            # 5. Feature Correlation Heatmap
            plt.figure(figsize=(8, 6))  # Increased figure size for heatmap
            sns.heatmap(final_df_ILI.corr(), annot=True, cmap='coolwarm', linewidths=0.5)
            plt.title('Feature Correlation Heatmap')

            heatmap_plot_path = f'heatmap_{timestamp}.png'

            # Save the heatmap plot
            plt.savefig(heatmap_plot_path, bbox_inches='tight')  # Use bbox_inches='tight'
            plt.close()

            # Return the paths to the saved images in JSON format
            data_output = {
                "type": "image",
                "pdp_image_path": pdp_plot_path,             # Path to Partial Dependence Plot
                "fi_image_path": fi_plot_path,               # Path to Feature Importance Plot
                "box_plot_path": box_plot_path,              # Path to Box Plot
                "stationing_plot_path": stationing_plot_path,# Path to Actual vs Predicted Plot
                "heatmap_plot_path": heatmap_plot_path       # Path to Feature Correlation Heatmap
            }

            print(json.dumps(data_output))  # Print the output as JSON
        else:
            raise ValueError("Inconsistent lengths in regression input data.")

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
