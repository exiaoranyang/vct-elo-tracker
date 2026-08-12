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
data_dir <- file.path(output_dir, "cleaned_matches.csv")
dic_dir <- file.path(input_dir, "all_ids")

### Load Data ----

matches <- read_csv(data_dir, show_col_types = FALSE) %>%
  arrange(Match.ID)

#split data

matches_prevct <- subset(matches, year <= 2022) %>%
  arrange(Match.ID)

matches_postvct <- subset(matches, year > 2022) %>%
  arrange(Match.ID)

dictionary <- list.files(path = dic_dir, 
                         pattern = "\\.csv$", 
                         full.names = TRUE) 

for (file in dictionary) {
  df_name <- tools::file_path_sans_ext(basename(file))
  assign(df_name, read.csv(file))
}

matches_severity <- read_csv("../input/match_severity_ratings.csv", show_col_types = FALSE)

### Elo ----

# Full run

run_list <- list(matches, matches_postvct, matches_prevct)

matches_elo <- list()
status <- list()

for (i in seq_along(run_list)){
  
  all_run <- run_elo(run_list[[i]], config = config$elo, matches_severity)
  
  matches_elo[[i]] <- all_run$matches
  status[[i]]      <- all_run$team_status
}

dataset_names <- c("matches", "matches_postvct", "matches_prevct")
names(matches_elo) <- dataset_names
names(status)      <- dataset_names

# format status

for (i in seq_along(status)){
  
  print(i)
  print(class(status[[i]]))
  print(str(status[[i]]))
  
  
  status[[i]] <- data.frame(
    Team.ID = names(status[[i]]),
    Team.Elo = sapply(status[[i]], function(x) x$elo),
    row.names = NULL
  )
  
  status[[i]] <- status[[i]] %>%
    mutate(
      Team.ID = as.integer(Team.ID)
    ) %>%
    left_join(all_teams_ids, by = c("Team.ID"))
  
}


### export ----

for (name in names(matches_elo)) {
  
  output_all_path <- file.path(output_dir, paste0(name, "_all.csv"))
  fwrite(matches_elo[[name]], output_all_path)
  
}

for (name in names(status)) {
  
  output_all_path <- file.path(output_dir, paste0(name, "_teamstatus.csv"))
  fwrite(status[[name]], output_all_path)
  
}
