
# Clear the working environment
rm(list = ls(all = TRUE))

# Install required packages. If they already installed, load
if(!require(httr)) {install.packages('httr'); library(httr)} # Tools for working with URLs and HTTP
if(!require(jsonlite)) {install.packages('jsonlite'); library(jsonlite)} # A JSON parser and generator
if(!require(tidyverse)) {install.packages('tidyverse'); library(tidyverse)} # A set of packages that work in harmony because they share common data representations and 'API' design
if(!require(data.table)) {install.packages('data.table'); library(data.table)} # Fast aggregation of large data

# Define the function
download_data <- function() {
    url <- paste0('https://lognet.saeon.ac.za/Haenertsburg/?command=DataQuery&uri=Server:SAEON_Haenertsburg_AWS.Daily&format=json&mode=since-time&p1=1900-01-01T00:00:00') # Change station details and date accordingly (PS, this will pull all the data from the logger's memory and not from the LNDB server)
  today <- format(Sys.Date(), '%Y%m%d')
  # Send GET request
  response <- GET(url, config(ssl_verifypeer = FALSE))
  # Check if the request was successful
  stop_for_status(response)
  # Parse the JSON response
  json_data <- content(response, 'parsed')
  # Extract the column names from the 'fields' list in the 'head' section.
  column_names <- c('TIMESTAMP', sapply(json_data$head$fields, function(x) x$name))
  # Extract the data entries from the 'vals' list in the 'data' section.
  data_entries <- lapply(json_data$data, function(x) c(x$time, x$vals))
  # Construct a dataframe from the data entries, using the column names.
  df <- data.frame(matrix(unlist(data_entries), nrow=length(data_entries), byrow=TRUE))
  colnames(df) <- column_names
  # Specify the directory where you want the files saved to. Below is the default GitHub repo dir. A Results folder were manually created
  csv_filename <- paste0('/Users/Rion.SAEON/Documents/GitHub/EFTEON/R/Results/', today, '.csv')
  output_filename <- paste0('/Users/Rion.SAEON/Documents/GitHub/EFTEON/R/Results/', today, '.txt')
  # csv_filename <- paste0('/Users/privateprivate/Downloads/test_', today, '.csv')
  # output_filename <- paste0('/Users/privateprivate/Downloads/test_', today, '.txt')
  # Write the dataframe to a CSV file that will be saved in the above dir(s)
  write.csv(df, file = csv_filename, row.names = FALSE)  
  # Write the content of the response to a file, same as above
  write(toJSON(json_data), file = output_filename)
}

# Call the function
download_data()

# Let's look at the raw data (structure, summaries and raw record snippets)
directory_path <- "/Users/Rion.SAEON/Documents/GitHub/EFTEON/R/Results"
csv_file <- list.files(path = directory_path, pattern = "\\.csv$", full.names = TRUE)[1]
met <- fread(csv_file) # Import the saved CSV file (see above) as a data.table/dataframe object
met <- met %>%
  mutate(Previous_TIMESTAMP = lag(TIMESTAMP)) %>% # The CS loggers report on the previous date's rainfall hence, the necessity of t-1. Note the first record has no TIMESTAMP
  relocate(Previous_TIMESTAMP, .after = 1) # Move to second location in dt/df
str(met) # Inspect the data structure
head(met, 10) # Inspect the first 10 records
tail(met, 10) # Inspect the last 10 records
summary(met) # Inspect summaries of each field

# Plot data from the selected fields to determine missing data and inspection of value ranges
rainplot <- met %>%
  ggplot(aes(as.Date(Previous_TIMESTAMP), Rain_mm_Tot, fill = Rain_mm_Tot == -5)) +
  geom_col(show.legend = F) + 
  ylim(-5,100) +
  ggtitle('', subtitle = 'Daily precipitation\n(Red values of -5 indicate missing data)') + # Name the plot, typically with the ID of the logger
  ylab('Precipitation (mm)') +
  xlab('Date') +
  theme_bw() +
  theme(text = element_text(family = 'Times New Roman', size = 10), # Adjust text size accordingly or specify further for indivual axes
        axis.text.x = element_text(angle = 45, hjust = 1)) + 
  scale_x_date(breaks = met$Previous_TIMESTAMP, date_breaks = '2 month', date_labels = '%b %Y') + # Adjust number of months, weeks, days to display according to data amount
  scale_fill_manual(values = alpha(c('blue', 'red'), 1.0), name = 'Rain = -5\n(missing values)')
rainplot # View the plot
# Save the plot as specific type and at a specific resolution
ggsave(plot = rainplot, filename = 'rainplot.png', path = '/Users/Rion.SAEON/Documents/GitHub/EFTEON/R/Results/', device='png', dpi=300, width = 1500, height = 1000, units = 'px')
