"""
Author: Marc Pienaar
Email: m.pienaar@saeon.ac.za

This script fetches table information from a server and allows users to view
the variables in those tables through a simple tkinter GUI.

Import necessary packages, disable SSL warnings, and define key functions:
- get_tables: retrieves the tables from the server and processes them into pandas dataframes
- update_server: updates the server based on user's selection and fetches corresponding data
- update_values: updates the available values based on user's selection of the table

Finally, define and run the main tkinter GUI loop.
"""

import requests
import pandas as pd
import json
import tkinter as tk
from tkinter import ttk

# Disable SSL warnings
requests.packages.urllib3.disable_warnings()  

def get_tables(server):
    """
    Fetches the tables from the server and processes them into pandas dataframes.
    """
    baseURL = "https://proxy.saeon.ac.za/lognet/?command=browsesymbols&uri="
    url = baseURL  + server + "&format=json"
    response = requests.get(url, verify=False)    
    # raise an exception if the GET request was not successful
    response.raise_for_status()    
    # Get JSON from the response
    json_data = response.json()
    # Extract the column names from the 'symbols' list.
    names = [item['name'] for item in json_data['symbols']]
    dataframes = []
    for i in names:
        url = baseURL  + server + "."+ str(i) +"&format=json"
        response = requests.get(url, verify=False)    
        # raise an exception if the GET request was not successful
        response.raise_for_status()    
        # Get JSON from the response
        json_data = response.json()
        symbol_names = [item['name'] for item in json_data['symbols']]
        df = pd.DataFrame(symbol_names, columns=[i])
        dataframes.append(df)
    final_df = pd.concat(dataframes, axis=1)
    return final_df

def update_server(event):
    """
    Updates the server based on user's selection and fetches corresponding data.
    """
    server = server_cb.get()
    # Clear other dropdowns
    column_name_cb.set('')
    column_name_cb['values'] = []
    values_cb.set('')
    values_cb['values'] = []
    # Show loading label
    loading_label.pack(pady=10)
    root.update()
    # Fetch data
    global table
    table = get_tables(server)
    # Update column names dropdown and hide loading label
    column_name_cb['values'] = table.columns.tolist()
    loading_label.pack_forget()

def update_values(event):
    """
    Updates the available values based on user's selection of the table.
    """
    selected_column = column_name_cb.get()
    values = table[selected_column].dropna().tolist()
    values.insert(0, 'Return all variables')
    values_cb['values'] = values

# GUI creation and event loop
root = tk.Tk()
root.title('DataFrame Viewer')
root.geometry('300x300')

# Center window on screen
window_width = root.winfo_reqwidth()
window_height = root.winfo_reqheight()
position_right = int(root.winfo_screenwidth()/2 - window_width/2)
position_down = int(root.winfo_screenheight()/2 - window_height/2)
root.geometry("+{}+{}".format(position_right, position_down))

# Server dropdown
server_label = tk.Label(root, text="Select Server:", font=('Arial', 14))
server_label.pack(pady=10)

servers = ["Server:EFTEON_Spioenkop_EC", "Server:EFTEON_Spioenkop_AWS", "Server3"] # Add more servers as needed
server_cb = ttk.Combobox(root, values=servers, font=('Arial', 14))
server_cb.bind('<<ComboboxSelected>>', update_server)
server_cb.pack(ipadx=50)

# Column dropdown
column_name_label = tk.Label(root, text="Select Table:", font=('Arial', 14))
column_name_label.pack(pady=10)

column_name_cb = ttk.Combobox(root, font=('Arial', 14))
column_name_cb.bind('<<ComboboxSelected>>', update_values)
column_name_cb.pack(ipadx=50)

# Values dropdown
values_label = tk.Label(root, text="Table Variables:", font=('Arial', 14))
values_label.pack(pady=10)

values_cb = ttk.Combobox(root, font=('Arial', 14))
values_cb.pack(ipadx=50)

# Loading label
loading_label = tk.Label(root, text="Loading...", font=('Arial', 14))

root.mainloop()
