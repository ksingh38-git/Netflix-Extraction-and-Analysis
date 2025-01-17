# Python Script: netflix_data_processing.py

# Importing necessary libraries
import pandas as pd
import sqlalchemy as sal
from sqlalchemy.types import NVARCHAR

# Load the dataset
df = pd.read_csv('C:/Users/Shyamli/Downloads/archive/netflix_titles.csv')

# Creating a connection to the SQL Server
engine = sal.create_engine('mssql://Khushi/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER')
dtype = {'title': NVARCHAR(length=200)}
conn = engine.connect()

# Loading the DataFrame into the SQL database
df.to_sql('netflix_raw', con=conn, index=False, if_exists='append', dtype=dtype)

# Closing the connection
conn.close()

# Check the number of rows inserted
print(len(df))

# Filtering the DataFrame to find a specific 'show_id'
df[df.show_id == 's5023']

# Finding missing values in the DataFrame
df.isna().sum()