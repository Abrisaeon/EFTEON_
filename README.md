# EFTEON_

EFTEON Data Processing Scripts
This repository contains Python and R scripts for processing and analyzing data files in the EFTEON project.

Table of Contents
CSI Web API
Python Scripts
R Scripts
1. CSI Web API
The CSI Web Server provides a user-friendly HTTP API interface that facilitates data access from various sources defined in the RTMC projects running on the server.

Key Features
User-friendly HTTP API: Easily accessible through simple HTTP commands.
Data Access: Capable of accessing data from a variety of sources.
Flexible Command Format: Commands sent to the web server usually adhere to this format: URL?command=CommandName&uri=DataSource&arguments.
DataSource Definition: Within commands, 'DataSource' is defined as source_name:station_name.table_name.field_name. For example, Server:CR1000:onemin.TempF.
Station Name: Specifically applicable to LoggerNet Server data sources.
Field Name: If not specified, all fields in the table are output. If an array without a subscript is referred to, all associated values of that array are output.
Return to Table of Contents

2. Python Scripts
This section is reserved for Python scripts related to the EFTEON project.

Note: As of now, no Python scripts are listed. Please check back later for updates.

Return to Table of Contents

3. R Scripts

R/Simple_example.R
R/Simple_GUI_example.R
3.1 R/Simple_example.R
This script can be used as an example to download data from the SAEON Lognet service. The script fetches data from a specified URL, parses the JSON response, and writes the data to a CSV file. It also includes a section for basic plotting.

Dependencies
httr
jsonlite
tidyverse
data.table
Return to Table of Contents

3.2 R/Simple_GUI_example.R
This script handles data retrieval and visualisation and allows users to select a server, table, and field from SAEON LoggerNet sites to retrieve data and visualize it as a plot.

Screenshot of the application
Fig 1. Screenshot of the application

Features
Select a server from a list of available options.
Fetch tables available on the selected server.
Fetch fields available in the selected table.
Fetch data from the selected field.
Visualize the data in a time-series plot.
Dependencies
shiny
httr
jsonlite
tidyverse
data.table
The installation of the above dependancies/libraries are handled automatically within the script

Your web browser should open with the app running. If not, check the R console for the address to access it (usually http://127.0.0.1:xxxx).

How to Use
Select a server from the "Choose a server" dropdown list.
Click the "Submit" button to fetch the available tables.
Select a table from the "Choose a table" dropdown list.
Click the "Fetch Fields" button to fetch the available fields.
Select a field from the "Select field" dropdown list.
Click the "Fetch Data" button to fetch the data.
The data will be visualized in a plot below the selection inputs.
Return to Table of Contents
