# Load packages -----------------------------------------------------
library(shiny)
library(shinydashboard)
library(glue)
library(tidyverse)
library(feather)
library(arrow)
library(DT) # Data Tables

# Load data ---------------------------------------------------------
# Full Mimic Data (Single Row Per Subject)
mimic_data_full <- read_feather('./data/mimic_data_test.feather'
)
mimic_data_full <- mimic_data_full[order(mimic_data_full['2012-01-01']),]
mimic_data_full$TEST_date_forecast_los_icu <- as.Date(mimic_data_full$TEST_date_forecast_los_icu, format='%Y-%m-%d')

# Construct the Transaction Mimic Data (Subject, Date, Value)
column_names <- append(c('subject_id'), head(tail(colnames(mimic_data_full), 334), 35) )
mimic_data <- mimic_data_full %>% select(column_names)
trans_mimic_data <- as.data.frame(t(as.matrix(mimic_data)))
colnames(trans_mimic_data) =as.character(unlist(mimic_data['subject_id']))
trans_mimic_data <- trans_mimic_data[-c(1), ]
trans_mimic_data <- rownames_to_column(trans_mimic_data, 'date')
trans_mimic_data <- gather(trans_mimic_data, key = "subject_id", value = "value", -date)
trans_mimic_data$date <- as.Date(trans_mimic_data[['date']], format='%Y-%m-%d')

# Construct Field of Interest Df (Subject, Date, Value)
#mimic_data_full <- mimic_data_full[order(mimic_data_full$hours_until_death),] #Ordering helps for table
vis_metadata <- select(mimic_data_full, c('subject_id','TEST_date_forecast_los_icu','TEST_date_pass_away','TEST_date_leave_hospital','TEST_date_leave_icu')) %>%
  merge(trans_mimic_data, by='subject_id', how = 'left')

convert_to_day_date <- function(x) {
  return(as.Date(x, format='%Y-%m-%d'))
}

vis_metadata$TEST_date_forecast_los_icu <- as.Date(vis_metadata$TEST_date_forecast_los_icu, format='%Y-%m-%d')
vis_metadata$TEST_date_leave_hospital <- as.Date(vis_metadata$TEST_date_leave_hospital, format='%Y-%m-%d')
vis_metadata$TEST_date_leave_icu <- as.Date(vis_metadata$TEST_date_leave_icu, format='%Y-%m-%d')
vis_metadata$TEST_date_pass_away <- as.Date(vis_metadata$TEST_date_pass_away, format='%Y-%m-%d')
# 
TEST_date_forecast_los_icu_df <- select(filter(vis_metadata, vis_metadata$TEST_date_forecast_los_icu == vis_metadata$date), c('subject_id','date','value'))
TEST_date_leave_hospital_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_hospital == vis_metadata$date), c('subject_id','date','value'))
TEST_date_leave_icu_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_icu == vis_metadata$date), c('subject_id','date','value'))
TEST_date_pass_away_df <- select(filter(vis_metadata, vis_metadata$TEST_date_pass_away == vis_metadata$date), c('subject_id','date','value'))
# 
# # rename value columns
names(TEST_date_forecast_los_icu_df)[names(TEST_date_forecast_los_icu_df) == 'value'] <- 'ICU_LOS_Forecast'
names(TEST_date_leave_hospital_df)[names(TEST_date_leave_hospital_df) == 'value'] <- 'Actual_Date_Left_Hospital'
names(TEST_date_leave_icu_df)[names(TEST_date_leave_icu_df) == 'value'] <- 'Actual_Date_Leave_ICU'
names(TEST_date_pass_away_df)[names(TEST_date_pass_away_df) == 'value'] <- 'Actual_Date_Passed_Away'
# 
# 
# #class(TEST_date_forecast_los_icu_df)
# #cat(class(TEST_date_forecast_los_icu_df))
# 

#typeof(TEST_date_forecast_los_icu_df)

# Merge Datasets Together
vis_df <- trans_mimic_data %>%
  merge(mimic_data_full, by = 'subject_id') %>%
  merge(TEST_date_forecast_los_icu_df, by = c("subject_id", "date"), all.x = TRUE) %>%
  merge(TEST_date_leave_hospital_df, by = c("subject_id", "date"), all.x = TRUE) %>%
  merge(TEST_date_leave_icu_df, by = c("subject_id", "date"), all.x = TRUE) %>%
  merge(TEST_date_pass_away_df, by = c("subject_id", "date"), all.x = TRUE)


# Define UI ---------------------------------------------------------
ui <- dashboardPage(
  
  # Header
  dashboardHeader(title = "Hospital Management"),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("home")),
      menuItem("Patient View", tabName = "patient_view", icon = icon("cut"))
      )
  ),
  
  # Body
  dashboardBody(
    tabItems(
      
      # Tab 1
      tabItem(
        tabName = "overview", # Overview
        fluidRow(
          # Value box: sample size
          valueBox(
            nrow(mimic_data), 
            "Total Patients", 
            icon = icon("hospital-user")
          )
        ),
        # Data reference
        h4("Overview of Patients in the Hospital")
      ),
      
      # Tab 2
      tabItem(
        tabName = "patient_view",
        
          fluidRow(
            # Value box: sample size
            valueBox(
              '2012-01-01', 
              "Current Date", 
              icon = icon('calendar')
            )
          ),
        
        fluidRow(
          box(
            status = "info",
            plotOutput("scatterplot", height = 260)
          )
        )
        , fluidRow(
             dataTableOutput('tbl')
        )
      )
    )
  )
)

# Define server function --------------------------------------------
server <- function(input, output) {
  
  output$tbl = renderDT(
    #mimic_data_full <- 
    select(mimic_data_full, c('subject_id', 'gender','ICU_LOS' ,'TEST_date_forecast_los_icu','risk_class','diagnosis','TEST_date_pass_away','2012-01-01','hours_until_death'))
  )
  
  output$scatterplot <- renderPlot({
    vis_df %>%
    ggplot() +
    geom_line(aes(x=date, y = value, color = risk_class, linetype = subject_id)) +  labs(x = 'Date', y = 'Hazard') +
    # Plot datapoints of interest
    geom_point(mapping= aes(date, ICU_LOS_Forecast), color = 'black') +
    geom_point(mapping= aes(date, Actual_Date_Left_Hospital), color = 'yellow') +
    geom_point(mapping= aes(date, Actual_Date_Leave_ICU), color = 'green') +
    geom_point(mapping= aes(date, Actual_Date_Passed_Away), color = 'red') #+
    
    #scale_colour_manual(values = c("black", "yellow","green","red"), labels=c('ICU_LOS_Forecast','Actual_Date_Left_Hospital','Actual_Date_Leave_ICU','Actual_Date_Passed_Away'))
  })
}

# Create the Shiny app object ---------------------------------------
shinyApp(ui, server)
