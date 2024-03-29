library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(DBI)
library(RMySQL)

# Read the file and split its content into lines
sql_credentials <- readLines("conf/mysql.txt", warn=FALSE)

# Database connection details
db_host <- sql_credentials[1]
db_name <- sql_credentials[2]
db_user <- sql_credentials[3]
db_password <- sql_credentials[4]
db_port <- strtoi(sql_credentials[5])

# Connect to the database
con <- dbConnect(RMySQL::MySQL(),
                 host = db_host,
                 port = db_port,
                 dbname = db_name,
                 user = db_user,
                 password = db_password)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Home air quality monitoring"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"))
    ),
    sidebarMenu(
      menuItem("Latest data", tabName = "datatable", icon = icon("table"))
    ),
    sidebarMenu(
      menuItem("Statistics", tabName = "cstatus", icon = icon("list-alt"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "dashboard",
        box(
          dateInput("date", "Select date:", format = 'yyyy-mm-dd'),
          width=3
        ),
        fluidRow(
          box(
            plotOutput("co2_plot", height = 250),
            plotOutput("temperature_plot", height = 250),
            plotOutput("humidity_plot", height = 250)
          )
        )
      ),
      tabItem(tabName = "datatable",
        fluidRow(
          tableOutput("latestDataTable")
        )
      ),
      tabItem(tabName = "cstatus",
        fluidRow(
          textOutput("Today"),
          textOutput("latestTime"),
          textOutput("latestCO2"),
          textOutput("latestTemperature"),
          textOutput("latestHumidity")
        )
      )
    )
  )
)


# Server
server <- function(input, output, session) {
  # Function to get available dates from the database
  get_available_dates <- reactive({
    query <- "SELECT date FROM sensirion"
    dates <- dbGetQuery(con, query)$date
    return(dates)
  })
  
  today <- format(Sys.Date(), "%Y-%m-%d")
  
  # Update the date drop-down choices (set today as default choice)
  observe({
    updateDateInput(session, "date", min = min(get_available_dates()), max = max(get_available_dates()))
  })

  # CO2 plot
  output$co2_plot <- renderPlot({
    req(input$date)
    
    # Query the CO2 data for the chosen date
    query <- paste0("SELECT CO2_ppm, date, time FROM sensirion WHERE date = '", input$date, "'")
    sensor_data <- dbGetQuery(con, query)
    sensor_data$date_time <- paste(sensor_data$date, sensor_data$time)
    
    # convert data string to numeric
    sensor_data_num <- transform(sensor_data, 
                                 CO2_ppm = as.numeric(CO2_ppm), 
                                 date_time = as.POSIXct(date_time))
    
    # Create a ggplot
    ggplot(sensor_data_num, aes(x = date_time, y = CO2_ppm, group = 1)) +
      geom_line() +
      ggtitle("CO2") +
      labs(x = "Hour", y = "ppm") +
      scale_x_datetime(date_breaks = "1 hour", date_labels = "%H") +
      theme_grey(base_size = 14) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            panel.background = element_blank(), axis.line = element_line(colour = "black"))
  })
  
  # Temperature plot
  output$temperature_plot <- renderPlot({
    req(input$date)
    
    # Query the temperature data for the chosen date
    query <- paste0("SELECT temperature_degC, date, time FROM sensirion WHERE date = '", input$date, "'")
    sensor_data <- dbGetQuery(con, query)
    sensor_data$date_time <- paste(sensor_data$date, sensor_data$time)
    
    # convert data string to numeric
    sensor_data_num <- transform(sensor_data, 
                                 temperature = as.numeric(temperature_degC), 
                                 date_time = as.POSIXct(date_time))
    
    # Create a ggplot
    ggplot(sensor_data_num, aes(x = date_time, y = temperature, group = 1)) +
      geom_line() +
      ggtitle("Temperature") +
      labs(x = "Hour", y = "celcius") +
      scale_x_datetime(date_breaks = "1 hour", date_labels = "%H") +
      theme_grey(base_size = 14) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            panel.background = element_blank(), axis.line = element_line(colour = "black"))
  })
  
  # Humidity plot
  output$humidity_plot <- renderPlot({
    req(input$date)
    
    # Query the humidity data for the chosen date
    query <- paste0("SELECT humidity_RH, date, time FROM sensirion WHERE date = '", input$date, "'")
    sensor_data <- dbGetQuery(con, query)
    sensor_data$date_time <- paste(sensor_data$date, sensor_data$time)
    
    # convert data string to numeric
    sensor_data_num <- transform(sensor_data, 
                                 humidity_RH = as.numeric(humidity_RH),
                                 date_time = as.POSIXct(date_time))
    
    # Create a ggplot
    ggplot(sensor_data_num, aes(x = date_time, y = humidity_RH, group = 1)) +
      geom_line() +
      ggtitle("Humidity") +
      labs(x = "Hour", y = "% RH") +
      scale_x_datetime(date_breaks = "1 hour", date_labels = "%H") +
      theme_grey(base_size = 14) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            panel.background = element_blank(), axis.line = element_line(colour = "black"))
  })
  
  # Fetch the latest data point
  query <- paste0("SELECT date, time, CO2_ppm, temperature_degC, humidity_RH 
              FROM sensirion 
              WHERE date = '", today,"'
              ORDER BY time DESC 
              LIMIT 1")
  latest_data <- dbGetQuery(con, query)
  
  # Display the latest data
  output$Today <- renderText({paste("Today: ", today)})
  output$latestTime <- renderText({paste("Time: ", as.character(latest_data$time))})
  output$latestCO2 <- renderText({paste("CO2: ", latest_data$CO2_ppm, " ppm")})
  output$latestTemperature <- renderText({paste("Temperature: ", latest_data$temperature_degC, "°C")})
  output$latestHumidity <- renderText({paste("Humidity: ", latest_data$humidity_RH, "%")})
  
  output$latestDataTable <- renderTable({
    latest_data
  })
}

# Run the app
shinyApp(ui = ui, server = server)

