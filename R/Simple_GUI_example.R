# Clear the working environment
rm(list = ls(all = TRUE))

# Install required packages. If they already installed, they will be loaded
if(!require(shiny)) {install.packages('shiny'); library(shiny)} # For building interactive web applications
if(!require(httr)) {install.packages('httr'); library(httr)} # Tools for working with URLs and HTTP
if(!require(jsonlite)) {install.packages('jsonlite'); library(jsonlite)} # A JSON parser and generator
if(!require(tidyverse)) {install.packages('tidyverse'); library(tidyverse)} # A set of packages that work in harmony because they share common data representations and 'API' design
if(!require(data.table)) {install.packages('data.table'); library(data.table)} # Fast aggregation of large data

# Define the function to download data
download_saeon_data <- function(field_uri) {
  url <- paste0('https://proxy.saeon.ac.za/lognet/?command=DataQuery&uri=', field_uri, '&format=json&mode=since-time&p1=1900-01-01T00:00:00')
  response <- GET(url, config(ssl_verifypeer = FALSE))
  if (status_code(response) == 404) {
    showNotification("Data not found. Please select valid options.", type = "warning")
    return(NULL)
  }
  stop_for_status(response)
  json_data <- content(response, 'parsed')
  column_names <- c('TIMESTAMP', sapply(json_data$head$fields, function(x) x$name))
  data_entries <- lapply(json_data$data, function(x) c(x$time, x$vals))
  df <- data.frame(matrix(unlist(data_entries), nrow = length(data_entries), byrow = TRUE))
  colnames(df) <- column_names
  return(df)
}

# Define UI
ui <- fluidPage(
  titlePanel("Select Server, Table, and Field"),
  selectInput("server", "Choose a server:", ""),
  actionButton("submit", "Submit"),
  selectInput("table", "Choose a table:", ""),
  actionButton("submit_table", "Fetch Fields"),
  selectInput("field", "Select field:", ""),
  actionButton("submit_field", "Fetch Data"),
  plotOutput("rainPlot")
)

# Define server logic 
server <- function(input, output, session) {
  
  # Load the server options into the selectInput
  observe({
    res <- GET("https://proxy.saeon.ac.za/lognet/?command=browsesymbols&uri=Server&format=json")
    if (status_code(res) == 404) {
      showModal(modalDialog(
        title = "Error",
        "Server options not found. Please try again later.",
        footer = NULL,
        easyClose = TRUE
      ))
      return(NULL)
    }
    json_data <- content(res, 'parsed')
    server_names <- sapply(json_data$symbols, function(x) x$name)
    server_uris <- sapply(json_data$symbols, function(x) x$uri)
    choices <- setNames(server_uris, server_names)
    updateSelectInput(session, "server", choices = choices)
  })
  
  # React when the submit button is clicked
  observeEvent(input$submit, {
    selected_server <- input$server
    if (!is.null(selected_server) && selected_server != "") {
      # Fetch tables from the selected server
      tables_url <- paste0("https://proxy.saeon.ac.za/lognet/?command=browsesymbols&uri=", selected_server, "&format=json")
      res <- GET(tables_url)
      if (status_code(res) == 404) {
        showModal(modalDialog(
          title = "Error",
          "Table options not found. Please select a different server.",
          footer = NULL,
          easyClose = TRUE
        ))
        updateSelectInput(session, "server", selected = "")
        updateSelectInput(session, "table", choices = character(0))
        return(NULL)
      }
      json_data <- content(res, 'parsed')
      table_names <- sapply(json_data$symbols, function(x) x$name)
      table_uris <- sapply(json_data$symbols, function(x) x$uri)
      choices <- setNames(table_uris, table_names)
      updateSelectInput(session, "table", choices = choices)
    }
  })
  
  # React when the submit_table button is clicked
  observeEvent(input$submit_table, {
    selected_table <- input$table
    if (!is.null(selected_table) && selected_table != "") {
      # Fetch fields from the selected table
      fields_url <- paste0("https://proxy.saeon.ac.za/lognet/?command=browsesymbols&uri=", selected_table, "&format=json")
      res <- GET(fields_url)
      if (status_code(res) == 404) {
        showModal(modalDialog(
          title = "Error",
          "Field options not found. Please select a different table.",
          footer = NULL,
          easyClose = TRUE
        ))
        updateSelectInput(session, "table", selected = "")
        updateSelectInput(session, "field", choices = character(0))
        return(NULL)
      }
      json_data <- content(res, 'parsed')
      field_names <- sapply(json_data$symbols, function(x) x$name)
      field_uris <- sapply(json_data$symbols, function(x) x$uri)
      choices <- setNames(field_uris, field_names)
      updateSelectInput(session, "field", choices = choices)
    }
  })
  
  # React when the submit_field button is clicked
  observeEvent(input$submit_field, {
    selected_field <- input$field
    if (!is.null(selected_field) && selected_field != "") {
      # Fetch data from the selected field
      data <- download_saeon_data(selected_field)
      if (is.null(data)) {
        updateSelectInput(session, "field", selected = "")
        return(NULL)
      }
      
      # Column names to be used (can be set dynamically based on some criteria)
      time_column <- "TIMESTAMP"
      data_column <- names(data)[2] # Assuming that the second column is the one of interest
      
      # Plot the data
      output$rainPlot <- renderPlot({
        # Check if data is a data frame and contains the required columns
        if (is.data.frame(data) && time_column %in% names(data) && data_column %in% names(data)) {
          data <- data %>%
            mutate(Previous_TIMESTAMP = as.Date(dplyr::lag(.data[[time_column]])),
                   data_value = as.numeric(.data[[data_column]])) %>%
            dplyr::relocate(Previous_TIMESTAMP, .after = time_column)
          
          ggplot(data, aes(x = Previous_TIMESTAMP, y = data_value, fill = data_value == -5)) +
            geom_col(show.legend = FALSE) +
            ylim(-5, 100) +
            ggtitle('Daily Values\n(Red values of -5 indicate missing data)') +
            ylab(paste0(data_column, " (Units)")) +
            xlab('Date') +
            theme_bw() +
            theme(text = element_text(family = 'Times New Roman', size = 10),
                  axis.text.x = element_text(angle = 45, hjust = 1)) +
            scale_x_date(date_breaks = '1 month', date_labels = '%b %Y') +
            scale_fill_manual(values = alpha(c('blue', 'red'), 1.0), name = paste0(data_column, '= -5\n(missing values)'))
        } else {
          # If data is not in the correct format or columns are missing, display an error message
          plot.new()
          title(main = "Error: Data format incorrect or required columns missing", col.main = "red")
        }
      })
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
