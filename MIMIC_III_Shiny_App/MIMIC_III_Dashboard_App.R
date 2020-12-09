# Load packages -----------------------------------------------------
library(shiny)
library(shinydashboard)

# Non-Shiny Packages
library(glue)
library(tidyverse)
library(feather)
library(arrow)
library(data.table)
library(DT)

# Full Mimic Data (Single Row Per Subject)
mimic_data_full <- read_feather('./data/mimic_data_test.feather')
setnames(mimic_data_full, old = c('gender','subject_id','ICU_LOS','risk_class','diagnosis','TEST_date_forecast_los_icu','icu_admit_age','2012-01-01'), new = c('Gender','Name','Forecast ICU LOS','Risk_Class','Diagnosis','Forecast_Date_Leave_ICU','Age','Current_Risk_Score'))
mimic_data_full$Forecast_Date_Leave_ICU <- as.Date(mimic_data_full$Forecast_Date_Leave_ICU, format='%Y-%m-%d')
mimic_data_full$Gender <- as.factor(mimic_data_full$Gender)
mimic_data_full$Risk_Class <- factor(mimic_data_full$Risk_Class, levels=c("high", "med", "low"), ordered=TRUE)

mimic_data_full_vis <- mimic_data_full
mimic_data_full_vis$Current_Risk_Score <- formatC(mimic_data_full_vis$Current_Risk_Score, format="f", digits=2)


# Supporting Disease Data
disease_group_stats <- read_feather('./data/disease_group_stats.feather')
disease_group_stats <- disease_group_stats[order(disease_group_stats$week_median_risk), descending = TRUE]
disease_group_stats$average_risk <- formatC(disease_group_stats$average_risk, format="f", digits=4)
disease_group_stats$median_risk <- formatC(disease_group_stats$median_risk, format="f", digits=4)
#disease_group_stats <- filter(disease_group_stats, disease_group_stats$Disease_Group, c('brain','blood'))

# Distinct Colors
colors_picked <- c("#89C5DA", "#DA5724", "#74D944", "#CE50CA", "#3F4921", "#C0717C", "#CBD588", "#5F7FC7", "#673770", "#D3D93E", "#38333E", "#508578", "#D7C1B1", "#689030", "#AD6F3B", "#CD9BCD",  "#D14285", "#6DDE88", "#652926", "#7FDCC0", "#C84248", "#8569D5", "#5E738F", "#D1A33D",  "#8A7C64", "#599861")

# Define UI ---------------------------------------------------------
ui <- dashboardPage(
  
  # Header
  dashboardHeader(title = "Hospital Management"),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("home")),
      menuItem("Patient View", tabName = "patient_view", icon = icon("cut")),
      menuItem("Patient View (Debugger)", tabName = "patient_view_debugger", icon = icon("cut")) #similar as patient_view
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
              #fluidCol option lines up left side to be para or# Value box: sample size
            valueBox(
                  '2012-01-01', 
                  "Current Date", 
                  icon = icon('calendar')
                ),
                box(
                  status = "info",
                  plotOutput("scatterplot", height = 260)
              ),
              # grid input, each grid is 12 x 12, can set width of boxes so if one box changes from 3->7 other ones move from 7 -> 3
                dataTableOutput('supporting'),
              dataTableOutput('tbl')
          )
      ),
        
          # Tab 3
          tabItem(
            tabName = "patient_view_debugger",
            
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
                plotOutput("scatterplot_debugger", height = 260)
              )
            )
            , fluidRow(
              dataTableOutput('tbl_debugger')
            )
          )
    )
  )
)

# Define server function --------------------------------------------
server <- function(input, output) {
  
  output$tbl = renderDT(
    select(mimic_data_full_vis, c('Name', 'Gender','Age','Diagnosis','Disease_Groups','Forecast ICU LOS' ,'Forecast_Date_Leave_ICU','Current_Risk_Score','Risk_Class') )
  )
  
  output$supporting = renderDT(
    disease_group_stats
  )
  
  output$scatterplot <- renderPlot({
    
    # Construct the Transaction Mimic Data (Subject, Date, Value)
    column_names <- append(c('Name'), head(tail(colnames(mimic_data_full), 334), 14) )
    #column_names <- append(c('Name'), head(tail(colnames(mimic_data_full), 334), 45) ) # Debugging View
    mimic_data <- mimic_data_full %>% select(column_names)
    trans_mimic_data <- as.data.frame(t(as.matrix(mimic_data)))
    colnames(trans_mimic_data) =as.character(unlist(mimic_data['Name']))
    trans_mimic_data <- trans_mimic_data[-c(1), ]
    trans_mimic_data <- rownames_to_column(trans_mimic_data, 'date')
    trans_mimic_data <- gather(trans_mimic_data, key = "Name", value = "value", -date)
    trans_mimic_data$date <- as.Date(trans_mimic_data[['date']], format='%Y-%m-%d')
    
    # Construct Field of Interest Df (Subject, Date, Value)
    vis_metadata <- select(mimic_data_full, c('Name','Forecast_Date_Leave_ICU','TEST_date_pass_away','TEST_date_leave_hospital','TEST_date_leave_icu')) %>%
      merge(trans_mimic_data, by='Name', how = 'left')
    
    convert_to_day_date <- function(x) {
      return(as.Date(x, format='%Y-%m-%d'))
    }
    
    vis_metadata$TEST_date_leave_hospital <- as.Date(vis_metadata$TEST_date_leave_hospital, format='%Y-%m-%d')
    vis_metadata$TEST_date_leave_icu <- as.Date(vis_metadata$TEST_date_leave_icu, format='%Y-%m-%d')
    vis_metadata$TEST_date_pass_away <- as.Date(vis_metadata$TEST_date_pass_away, format='%Y-%m-%d')
    # 
    TEST_date_forecast_los_icu_df <- select(filter(vis_metadata, vis_metadata$Forecast_Date_Leave_ICU == vis_metadata$date), c('Name','date','value'))
    TEST_date_leave_hospital_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_hospital == vis_metadata$date), c('Name','date','value'))
    TEST_date_leave_icu_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_icu == vis_metadata$date), c('Name','date','value'))
    TEST_date_pass_away_df <- select(filter(vis_metadata, vis_metadata$TEST_date_pass_away == vis_metadata$date), c('Name','date','value'))
    # 
    # # rename value columns
    names(TEST_date_forecast_los_icu_df)[names(TEST_date_forecast_los_icu_df) == 'value'] <- 'ICU_LOS_Forecast'
    names(TEST_date_leave_hospital_df)[names(TEST_date_leave_hospital_df) == 'value'] <- 'Actual_Date_Left_Hospital'
    names(TEST_date_leave_icu_df)[names(TEST_date_leave_icu_df) == 'value'] <- 'Actual_Date_Leave_ICU'
    names(TEST_date_pass_away_df)[names(TEST_date_pass_away_df) == 'value'] <- 'Actual_Date_Passed_Away'
    
    # Merge Datasets Together
    vis_df <- trans_mimic_data %>%
      merge(mimic_data_full, by = 'Name') %>%
      merge(TEST_date_forecast_los_icu_df, by = c("Name", "date"), all.x = TRUE) %>%
      merge(TEST_date_leave_icu_df, by = c("Name", "date"), all.x = TRUE) %>%
      merge(TEST_date_pass_away_df, by = c("Name", "date"), all.x = TRUE)
    vis_df$Name <-factor(vis_df$Name, levels = unique(vis_df[order(vis_df$Current_Risk_Score, decreasing = TRUE),]$Name))
    
    vis_df %>%
      ggplot() +
      geom_line(aes(x=date, y = value, color = Name, linetype = Risk_Class)) +
      scale_color_manual(values=colors_picked) +
      labs(x = 'Date', y = 'Risk Score (Mortality Risk)') +
      # Plot datapoints of interest (Last line has higher priority to override other dots)
      #geom_point(mapping= aes(date, Actual_Date_Leave_ICU), shape = 'square') +
      #geom_point(mapping= aes(date, Actual_Date_Left_Hospital), shape = 'triangle') +
      geom_point(mapping= aes(date, ICU_LOS_Forecast), color = 'black') #+
      #geom_point(mapping= aes(date, Actual_Date_Passed_Away), shape = 'star') #+
  })
  
  output$tbl_debugger = renderDT(
    #mimic_data_full$Current_Risk_Score <- formatC(mimic_data_full$Current_Risk_Score, format="f", digits=2)
    
    select(mimic_data_full_vis, c('Name', 'Gender','Age','Diagnosis' ,'Forecast_Date_Leave_ICU','Current_Risk_Score',
                              'TEST_date_pass_away','TEST_date_leave_hospital','TEST_date_leave_icu')) # New Fields on this Line
  )
  
  output$scatterplot_debugger <- renderPlot({
    
    # Construct the Transaction Mimic Data (Subject, Date, Value)
    #column_names <- append(c('Name'), head(tail(colnames(mimic_data_full), 334), 14) )
    column_names <- append(c('Name'), head(tail(colnames(mimic_data_full), 334), 45) ) # Debugging View
    mimic_data <- mimic_data_full %>% select(column_names)
    trans_mimic_data <- as.data.frame(t(as.matrix(mimic_data)))
    colnames(trans_mimic_data) =as.character(unlist(mimic_data['Name']))
    trans_mimic_data <- trans_mimic_data[-c(1), ]
    trans_mimic_data <- rownames_to_column(trans_mimic_data, 'date')
    trans_mimic_data <- gather(trans_mimic_data, key = "Name", value = "value", -date)
    trans_mimic_data$date <- as.Date(trans_mimic_data[['date']], format='%Y-%m-%d')
    
    # Construct Field of Interest Df (Subject, Date, Value)
    vis_metadata <- select(mimic_data_full, c('Name','Forecast_Date_Leave_ICU','TEST_date_pass_away','TEST_date_leave_hospital','TEST_date_leave_icu')) %>%
      merge(trans_mimic_data, by='Name', how = 'left')
    
    convert_to_day_date <- function(x) {
      return(as.Date(x, format='%Y-%m-%d'))
    }
    
    vis_metadata$TEST_date_leave_hospital <- as.Date(vis_metadata$TEST_date_leave_hospital, format='%Y-%m-%d')
    vis_metadata$TEST_date_leave_icu <- as.Date(vis_metadata$TEST_date_leave_icu, format='%Y-%m-%d')
    vis_metadata$TEST_date_pass_away <- as.Date(vis_metadata$TEST_date_pass_away, format='%Y-%m-%d')
    # 
    TEST_date_forecast_los_icu_df <- select(filter(vis_metadata, vis_metadata$Forecast_Date_Leave_ICU == vis_metadata$date), c('Name','date','value'))
    #TEST_Forecast_Date_Leave_Hospital_df <- select(filter(vis_metadata, vis_metadata$Forecast_Date_Leave_Hospital == vis_metadata$date), c('Name','date','value'))
    TEST_date_leave_hospital_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_hospital == vis_metadata$date), c('Name','date','value'))
    TEST_date_leave_icu_df <- select(filter(vis_metadata, vis_metadata$TEST_date_leave_icu == vis_metadata$date), c('Name','date','value'))
    TEST_date_pass_away_df <- select(filter(vis_metadata, vis_metadata$TEST_date_pass_away == vis_metadata$date), c('Name','date','value'))
    # 
    # # rename value columns
    names(TEST_date_forecast_los_icu_df)[names(TEST_date_forecast_los_icu_df) == 'value'] <- 'ICU_LOS_Forecast'
    #names(TEST_Forecast_Date_Leave_Hospital_df)[names(TEST_Forecast_Date_Leave_Hospital_df) == 'value'] <- 'ICU_LOS_Forecast'
    names(TEST_date_leave_hospital_df)[names(TEST_date_leave_hospital_df) == 'value'] <- 'Actual_Date_Left_Hospital'
    names(TEST_date_leave_icu_df)[names(TEST_date_leave_icu_df) == 'value'] <- 'Actual_Date_Leave_ICU'
    names(TEST_date_pass_away_df)[names(TEST_date_pass_away_df) == 'value'] <- 'Actual_Date_Passed_Away'
    
    # Merge Datasets Together
    vis_df <- trans_mimic_data %>%
      merge(mimic_data_full, by = 'Name') %>%
      merge(TEST_date_forecast_los_icu_df, by = c("Name", "date"), all.x = TRUE) %>%
      merge(TEST_date_leave_hospital_df, by = c("Name", "date"), all.x = TRUE) %>%
      merge(TEST_date_leave_icu_df, by = c("Name", "date"), all.x = TRUE) %>%
      merge(TEST_date_pass_away_df, by = c("Name", "date"), all.x = TRUE)
    vis_df$Name <-factor(vis_df$Name, levels = unique(vis_df[order(vis_df$Current_Risk_Score, decreasing = TRUE),]$Name))
    
    vis_df %>%
      
      ggplot() +
      geom_line(aes(x=date, y = value, color = Name, linetype = Risk_Class)) +
      scale_color_manual(values=colors_picked) +
      labs(x = 'Date', y = 'Risk Score (Mortality Risk)') +
      # Plot datapoints of interest (Last line has higher priority to override other dots)
      geom_point(mapping= aes(date, Actual_Date_Leave_ICU),size =3, shape = 0) +
      geom_point(mapping= aes(date, Actual_Date_Left_Hospital), size =3, shape = 2) +
      geom_point(mapping= aes(date, ICU_LOS_Forecast), color = 'black') +
      geom_point(mapping= aes(date, Actual_Date_Passed_Away), size =3, shape = 'star')
  })
}

# Create the Shiny app object ---------------------------------------
shinyApp(ui, server)
