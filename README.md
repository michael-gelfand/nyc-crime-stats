# Crime Reports Dashboard

## Motivation

**Target audience:** City planners, law enforcement agencies, and policy makers.

Crime data is crucial for understanding trends and making informed policy decisions. This dashboard enables users to explore crime reports, identify trends across boroughs, and analyze key factors such as crime category, crime type, and victim gender. By providing informative visualizations, this tool assists in data-driven decision-making to enhance public safety.

## App Description

## Installation Instructions

### Prerequisites
- Install R
- Install RStudio
- Install `renv` package if not already installed:

  ```r
  install.packages("renv")
  ```

### Setup
1. Clone the repository and set it as your working directory.

2. Restore the package dependencies using `renv`:
   ```r
   renv::restore()
   ```

### Running the App
Run the following command in RStudio or an R terminal:
```r
shiny::runApp("src/app.R")
```

The app should now be accessible in your web browser.

## License
This project is licensed under the terms of the included LICENSE file.

