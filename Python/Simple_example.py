import requests
import json
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime

# Define filenames for CSV and JSON files
today = datetime.now().strftime('%Y%m%d')
csv_filename = f'/Users/privateprivate/Downloads/{today}.csv'
output_filename = f'/Users/privateprivate/Downloads//{today}.json'
fig_path = f'/Users/privateprivate/Downloads/rainplot.png'

def download_saeon_data():
    url = 'https://lognet.saeon.ac.za/Haenertsburg/?command=DataQuery&uri=Server:SAEON_Haenertsburg_AWS.Daily&format=json&mode=since-time&p1=2020-01-01T00:00:00'
    response = requests.get(url, verify=False)

    # Check if the request was successful
    response.raise_for_status()

    # Parse the JSON response
    json_data = response.json()

    # Extract the column names from the 'fields' list in the 'head' section
    column_names = ['TIMESTAMP'] + [x['name'] for x in json_data['head']['fields']]

    # Extract the data entries from the 'vals' list in the 'data' section
    data_entries = [[x['time']] + x['vals'] for x in json_data['data']]

    # Construct a DataFrame from the data entries, using the column names
    df = pd.DataFrame(data_entries, columns=column_names)
    
    # Write the DataFrame to a CSV file
    df.to_csv(csv_filename, index=False)

    # Write the content of the response to a JSON file
    with open(output_filename, 'w') as file:
        json.dump(json_data, file)

    return df

# Call the function and store the DataFrame
data = download_saeon_data()

# Add Previous_TIMESTAMP column
data['Previous_TIMESTAMP'] = data['TIMESTAMP'].shift(1)

# Display DataFrame structure
print(data.info())

# Display first 10 records
print(data.head(10))

# Display last 10 records
print(data.tail(10))

# Display summary statistics
print(data.describe())

# Plotting the data
rain_plot = data.copy()
rain_plot['Previous_TIMESTAMP'] = pd.to_datetime(rain_plot['Previous_TIMESTAMP'])
rain_plot['Rain_mm_Tot'] = pd.to_numeric(rain_plot['Rain_mm_Tot'], errors='coerce')

plt.figure(figsize=(10, 5))
plt.bar(rain_plot['Previous_TIMESTAMP'], rain_plot['Rain_mm_Tot'],
    color=['red' if val == -5 else 'blue' for val in rain_plot['Rain_mm_Tot']])
plt.title('Daily precipitation\n(Red values of -5 indicate missing data)')
plt.xlabel('Date')
plt.ylabel('Precipitation (mm)')
plt.ylim(-5, 100)
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b %Y'))
plt.gca().xaxis.set_major_locator(mdates.MonthLocator())
plt.xticks(rotation=45)
plt.savefig(fig_path, dpi=300)
plt.show()
