# Load packages -----------------------------------------------------
library(shiny)
library(shinydashboard)
library(glue)
library(tidyverse)
library(feather)
library(DT) # Data Tables

# Load data ---------------------------------------------------------
load("data/movies.Rdata")
mimic_data <- read_feather('./data/mimic_data_train.feather'
                           #, columns = c('subject_id','hadm_id')
                           )

#print(mimic_data$hours_until_icu_admission)

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
        #   # Value box: avg IMDB rating
        #   valueBox(
        #     round(mean(movies$imdb_rating), 2),
        #     "Avg IMDB score",
        #     icon = icon("thumbs-up", lib = "glyphicon"),
        #     color = "fuchsia"
        #   ),
        #   # Value box: number of Oscar wins
        #   valueBox(
        #     sum(movies$best_pic_win == "yes"),
        #     "Oscar wins",
        #     icon = icon("trophy"),
        #     color = "yellow"
        #   )
        ),
        # Data reference
        h4("Overview of Patients in the Hospital")
      ),
      
      # Tab 2
      tabItem(
        tabName = "patient_view",
        
        # Row 1
        # fluidRow(
        #   # Box: Select title type
        #   box(
        #     title = "Select title type", status = "warning", solidHeader = TRUE,
        #     "Select a title type using the drop down menu below.",
        #     selectInput(inputId = "title_type", 
        #                 label = "Title type:",
        #                 choices = unique(movies$title_type), 
        #                 selected = "Feature Film")
        #   )
        # ),
        #Row 2
        fluidRow(
          # Box: Select variables to plot
        #   box(
        #     title = "Select variables to plot:",
        #     status = "primary",
        #     
        #     # Select variable for y-axis
        #     selectInput(inputId = "y", 
        #                 label = "Y-axis:",
        #                 choices = c("IMDB rating" = "imdb_rating", 
        #                             "IMDB number of votes" = "imdb_num_votes", 
        #                             "Critics Score" = "critics_score", 
        #                             "Audience Score" = "audience_score", 
        #                             "Runtime" = "runtime"), 
        #                 selected = "audience_score"),
        #     
        #     # Select variable for x-axis
        #     selectInput(inputId = "x", 
        #                 label = "X-axis:",
        #                 choices = c("IMDB rating" = "imdb_rating", 
        #                             "IMDB number of votes" = "imdb_num_votes", 
        #                             "Critics Score" = "critics_score", 
        #                             "Audience Score" = "audience_score", 
        #                             "Runtime" = "runtime"), 
        #                 selected = "critics_score"),
        #     
        #     # Select variable for color
        #     selectInput(inputId = "z", 
        #                 label = "Color by:",
        #                 choices = c("Genre" = "genre", 
        #                             "MPAA Rating" = "mpaa_rating", 
        #                             "Critics Rating" = "critics_rating", 
        #                             "Audience Rating" = "audience_rating"),
        #                 selected = "mpaa_rating")
        #   ),
          # Box: plot
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
  
  # Scatterplot
  # output$scatterplot <- renderPlot({
  #   movies %>% 
  #     filter(title_type == input$title_type) %>%
  #     ggplot(aes_string(x = input$x, y = input$y, 
  #                       color = input$z)) +
  #     geom_point() +
  #     labs(x = prettify_label(input$x),
  #          y = prettify_label(input$y),
  #          color = prettify_label(input$z))
  # })
  output$tbl = renderDT(
    mimic_data %>%
      filter(anytime_expire_flag == 1) %>%
      
      arrange(desc(days_until_death)) %>%
      
      head(5)
  )
  
  output$scatterplot <- renderPlot({
    mimic_data %>%
      filter(anytime_expire_flag == 1) %>%
      
      arrange(desc(days_until_death)) %>%
      
      head(5) %>%
      
      # Change the point size, and shape
      ggplot(aes(x=icu_admit_age, y=days_until_death)) +
      geom_point(shape=23) + 
      labs(x = 'Age',
           y = 'Days until Death')
    # mimic_data %>% 
    #   #filter(anytime_expire_flag == input$anytime_expire_flag) %>%
    #   ggplot(aes_string(x = input$hours_until_icu_admission # $x
    #                     , y = input$hours_until_death,# $y
    #                     color = input$anytime_expire_flag 
    #                     )) +
    #   geom_point(x = 'hours_until_icu_admission',
    #              y = 'hours_until_death',
    #              color = 'anytime_expire_flag') #+
      # labs(x = 'hours_until_icu_admission',
      #      y = 'hours_until_death',
      #      color = 'anytime_expire_flag')
  })
}

# Create the Shiny app object ---------------------------------------
shinyApp(ui, server)
