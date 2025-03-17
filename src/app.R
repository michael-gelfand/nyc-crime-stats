options(shiny.port = 8050, shiny.autoreload = TRUE)

library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(ggiraph)
library(tidyverse)

# Load crime data
# Filter down to only include crimes against individuals
data <- read_csv("../data/raw/nypd_complaint_data.csv") |>
  filter(borough != "(null)") |>
  filter(victim_sex %in% c("F", "M")) |>
  mutate(
    victim_sex = case_when(victim_sex == "F" ~ "Female", victim_sex == "M" ~ "Male"),
    category = case_when(
      category == "FELONY" ~ "Felony",
      category == "MISDEMEANOR" ~ "Misdemeanor",
      category == "VIOLATION" ~ "Violation"
    ),
    borough = str_to_title(borough)
  )

# Load borough population data
nyc_population <- read_csv("../data/raw/borough_pop.csv") |>
  mutate(Borough = str_to_title(Borough))

# Dropdown menu choices
gender_choices <- c("Female", "Male")
cat_choices <- c("Felony", "Misdemeanor", "Violation")
crime_choices <- unique(na.omit(data$offense))

# Gender select dropdown input
gender_select_in <- selectInput(
  'gender_filter',
  'Victim Gender',
  choices = c("", gender_choices),
  selected = ""
)

# Category select dropdown input
cat_select_in <- selectInput(
  'cat_filter',
  'Offense Category',
  choices = cat_choices,
  selected = NULL,
  multiple = TRUE
)

# Crime select dropdown input
crime_select_in <- selectInput(
  'crime_filter',
  'Crime',
  choices = crime_choices,
  selected = NULL,
  multiple = TRUE
)

# Normalize toggle input
normalize_toggle_in <- input_switch("normalize", "Show Crime Rate Per Capita", FALSE)

# Reset button input
reset_button_in <- actionButton("reset", "Reset Filters")

# Girafe plot output
girafe_output <- girafeOutput("bar_chart", height = "500px")


# About section
about_section <- div(
  style = "margin-top: 30px; padding: 20px; background-color: #f8f9fa;
           border-radius: 10px; line-height: 1.2;",
  h3("About This Dashboard"),
  p(
    "This dashboard visualizes crime data from the NYPD complaint database.
       Users can filter data by victim gender, offense category, and specific crimes.",
    style = "font-size: 14px;"
  ),
  p(
    "The crime rate per capita option normalizes the data based on borough population.",
    style = "font-size: 14px;"
  ),
  p(
    "Data sources: ",
    a("NYPD Complaint Data", href = "https://data.cityofnewyork.us/d/qgea-i56i",
      target = "_blank"),
    a("NYC Borough Populations", href = "https://www.nyc.gov/assets/planning/download/pdf/planning-level/nyc-population/population-estimates/current-population-estimates-2023-June2024-release.pdf?r=1",
      target = "_blank"),
    style = "font-size: 14px;"
  ),
  p("Created by Michael Gelfand", style = "font-size: 14px;"),
  p("Last Updated: March 15th, 2025", style = "font-size: 14px;")
)

# UI Layout
ui <- page_fluid(
  titlePanel(h1("New York City Crime Rates"), windowTitle = "NYC Crime"),
  sidebarLayout(
    sidebarPanel(
      h4("Filters"),
      gender_select_in,
      cat_select_in,
      crime_select_in,
      normalize_toggle_in,
      reset_button_in
    ),
    mainPanel(card(
      card_header("Crime Data by Borough"), card_body(girafe_output)
    ))
  ),
  about_section
)

# Server side logic
server <- function(input, output, session) {
  observeEvent(input$reset, {
    updateSelectInput(session, "gender_filter", selected = "")
    updateSelectInput(session, "cat_filter", selected = character(0))
    updateSelectInput(session, "crime_filter", selected = character(0))
  })
  
  # Render Crime Count Bar Chart
  output$bar_chart <- renderGirafe({
    filtered_data <- data
    if (input$gender_filter != "") {
      filtered_data <- filtered_data |>
        filter(victim_sex == input$gender_filter)
    }
    
    if (!is.null(input$cat_filter)) {
      filtered_data <- filtered_data |>
        filter(category %in% input$cat_filter)
    }
    
    if (!is.null(input$crime_filter)) {
      filtered_data <- filtered_data |>
        filter(offense %in% input$crime_filter)
    }
    
    # Get crime counts by borough
    df_summary <- filtered_data |>
      count(borough, name = "crime_count") |>
      left_join(nyc_population, by = c("borough" = "Borough")) |>
      mutate(Population = replace_na(Population, 1))
    
    # Toggle input behavior for normalization
    if (input$normalize) {
      df_summary <- df_summary %>%
        mutate(metric_value = round((crime_count / Population) * 100000, 2),
               metric_label = "Crimes per 100,000 Residents")
    } else {
      df_summary <- df_summary %>%
        mutate(metric_value = crime_count, metric_label = "Total Crimes")
    }
    
    # Handle empty dataframe
    if (nrow(df_summary) == 0) {
      girafe_obj <- girafe(
        ggobj = ggplot() +
          annotate(
            "text",
            x = 1,
            y = 1,
            label = "No data available. Please adjust filters.",
            size = 6,
            color = "red",
            fontface = "bold"
          ) +
          theme_void(),
        options = list(opts_toolbar(saveaspng = FALSE))
      )
      return(girafe_obj)
    }
    
    
    # Create the bar chart
    plot <- ggplot(
      df_summary,
      aes(
        x = fct_reorder(borough, replace_na(metric_value, 0)),
        y = metric_value,
        tooltip = paste0("Borough: ", borough, "<br>Crimes: ", metric_value),
        data_id = borough
      )
    ) +
      geom_col_interactive(fill = "steelblue") +
      labs(x = "Borough", y = unique(df_summary$metric_label)) +
      theme_minimal(base_size = 13) +
      theme(
        text = element_text(family = "DejaVu Sans"),
        axis.title = element_text(family = "DejaVu Sans"),  
        axis.text = element_text(family = "DejaVu Sans"),  
        panel.grid.major.x = element_blank()
      )
    
    # Convert ggplot2 plot to girafe object for tooltip hover
    girafe(
      ggobj = plot,
      options = list(
        opts_hover(css = "fill:orange;"),
        opts_selection(type = "none"),
        opts_zoom(min = 1, max = 1),
        opts_toolbar(saveaspng = FALSE)
      )
    )
  })
}

# Run the app/dashboard
shinyApp(ui, server)
