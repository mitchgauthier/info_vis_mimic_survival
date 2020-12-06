# Load packages -----------------------------------------------------
library(shiny)
library(shinydashboard)
library(glue)
library(tidyverse)
library(feather)
library(arrow)
library(DT) # Data Tables

# Load data ---------------------------------------------------------
mimic_data <- read_feather('./data/mimic_data_test.feather'
                           )

# Construct the Survival Data
column_names <- append(c('subject_id'), head(tail(colnames(mimic_data_full), 334), 10000) )
mimic_data <- mimic_data_full %>% select(column_names)
trans_mimic_data <- as.data.frame(t(as.matrix(mimic_data)))
colnames(trans_mimic_data) =as.character(unlist(mimic_data['subject_id']))
trans_mimic_data <- trans_mimic_data[-c(1), ]
trans_mimic_data <- rownames_to_column(trans_mimic_data, 'date')
trans_mimic_data <- gather(trans_mimic_data, key = "subject_id", value = "value", -date)
trans_mimic_data$date <- as.Date(trans_mimic_data[['date']], format='%Y-%m-%d')

# Dataframe with points of interest
mimic_data_full <- mimic_data_full[order(mimic_data_full$hours_until_death),] #Ordering helps for table
vis_metadata <- select(mimic_data_full, c('subject_id','TEST_date_forecast_los_icu','TEST_date_pass_away','TEST_date_leave_hospital','TEST_date_leave_icu')) %>%
  merge(trans_mimic_data, by='subject_id', how = 'left')
vis_metadata$TEST_date_forecast_los_icu <- as.Date(vis_metadata$TEST_date_forecast_los_icu, format='%Y-%m-%d')
vis_metadata$TEST_date_leave_hospital <- as.Date(vis_metadata$TEST_date_leave_hospital, format='%Y-%m-%d')
vis_metadata$TEST_date_leave_icu <- as.Date(vis_metadata$TEST_date_leave_icu, format='%Y-%m-%d')
vis_metadata$TEST_date_pass_away <- as.Date(vis_metadata$TEST_date_pass_away, format='%Y-%m-%d')
TEST_date_forecast_los_icu_df <- select(filter(vis_metadata, vis_metadata$TEST_date_forecast_los_icu == vis_metadata$date), c('subject_id','date','value'))
TEST_date_leave_hospital_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_hospital == vis_metadata$date), c('subject_id','date','value'))
TEST_date_leave_icu_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_icu == vis_metadata$date), c('subject_id','date','value'))
TEST_date_pass_away_df <- select(filter(vis_metadata, vis_metadata$TEST_date_pass_away == vis_metadata$date), c('subject_id','date','value'))

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
    select(mimic_data_full, c('subject_id','ICU_LOS' ,'TEST_date_forecast_los_icu','risk_class','diagnosis','TEST_date_pass_away'))
  )
  
  output$scatterplot <- renderPlot({
   # Merge back non-Survival Data
  trans_mimic_data %>%
  merge(mimic_data_full, by = 'subject_id') %>%
  ggplot(aes(x=date, y = value)) +
  geom_line(aes(color = risk_class, linetype = subject_id)) +  labs(x = 'Date', y = 'Hazard') +
  # Plot datapoints of interest
  geom_point(TEST_date_forecast_los_icu_df, mapping= aes(date, value), color = 'blue') +
  geom_point(TEST_date_leave_icu_df, mapping= aes(date, value), color = 'green') +
  geom_point(TEST_date_leave_hospital_df, mapping= aes(date, value), color = 'yellow') +
  geom_point(TEST_date_pass_away_df, mapping= aes(date, value), color = 'red')
  })
}

# Create the Shiny app object ---------------------------------------
shinyApp(ui, server)
