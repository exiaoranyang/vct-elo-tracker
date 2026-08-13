### Setup ----
library(rstudioapi)

if (!require("pacman")) install.packages("pacman", repos = "http://cran.us.r-project.org"); library(pacman);
pacman::p_load(RKaggle, yaml, here, dplyr, tidyr, readr, stringr, lubridate, openxlsx, data.table, purrr, tidyverse)

if (interactive()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

source("../R/functions.R")

### Set Paths ----

config <- yaml::read_yaml("../config.yaml")

input_dir <- config$paths$input_dir
output_dir <- config$paths$output_dir


### Load data ----

file_names <- list.files(path = output_dir, 
                        pattern = "^matches.*\\.csv$", 
                        full.names = TRUE)

for (file in file_names) {
  df_name <- tools::file_path_sans_ext(basename(file))
  assign(df_name, read.csv(file))
}

### View all time, just 2026

path_2026 <- file.path(input_dir, "vct_2026", "ids", "teams_ids.csv")
ids_2026 <- read_csv(path_2026, show_col_types = FALSE)

rankings_2026 <- matches_teamstatus %>%
  mutate(
    Team.ID = as.integer(Team.ID)
  ) %>%
  inner_join(ids_2026, by = c("Team.ID" = "Team ID"))

# view peaks

max_elo_all <- return_max_elo(matches_all)
max_elo_prevct <- return_max_elo(matches_prevct_all)
max_elo_postvct <- return_max_elo(matches_postvct_all)
