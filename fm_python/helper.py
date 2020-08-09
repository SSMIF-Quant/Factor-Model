import pandas as pd

df = pd.read_csv("clean_data\\macroeconomic_dataEHGDUS Index.csv")
print(df.head())
print(df.columns)
print(df.head())

df = pd.read_csv("clean_data\\valuation_dataS5INDU Index.csv")
print(df.head())
print(df.columns)
print(df.head())