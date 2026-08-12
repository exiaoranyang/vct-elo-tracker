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
data_dir <- file.path(input_dir, "all_ids/")

folder_list <- list.dirs(path = input_dir, full.names = TRUE, recursive = FALSE)

### Load Data ----

dictionary <- list.files(path = data_dir, 
                         pattern = "\\.csv$", 
                         full.names = TRUE) 

for (file in dictionary) {
  df_name <- tools::file_path_sans_ext(basename(file))
  assign(df_name, read.csv(file))
}

full_scores <- parse_df(root_folders = folder_list, sub_dir = "matches", target = "scores.csv")
stacked_full_scores <- stack_dfs(target_dfs = full_scores, "stacked_scores", output_dir, TRUE)

### append ids ----

# NRG name fix

stacked_full_scores <- stacked_full_scores %>%
  mutate(`Team A` = if_else(`Team A` == "Mega Minors", "NRG", `Team A`),
         `Team B` = if_else(`Team B` == "Mega Minors", "NRG", `Team B`))

stacked_full_scores <- stacked_full_scores %>% 
  rename(Match.Type = "Match Type", 
         Match.Name = "Match Name")

stacked_full_scores <- stacked_full_scores %>%
  left_join(all_matches_games_ids %>%
              select(Tournament, Match.Type, Match.Name, Match.ID) %>% 
              distinct(Tournament, Match.Type, Match.Name, .keep_all = TRUE), 
            by = c("Tournament", "Match.Type", "Match.Name"))

# some team names repeat, so have to use by year team IDs

team_ids_by_year <- parse_df(folder_list, "ids", "teams_ids.csv")

stacked_full_scores <- map(team_ids_by_year, function(file) {
  
  id_year <- str_extract(dirname(file), "\\d{4}") |> 
    as.integer()
  
  team_ids <- read.csv(file)
  
  stacked_full_scores %>%
    filter(year == id_year) %>%
    left_join(
      team_ids,
      by = c("Team A" = "Team"),
      relationship = "many-to-one"
    ) %>%
    rename(Team.A.ID = Team.ID)
  
}) %>%
  list_rbind()

stacked_full_scores <- map(team_ids_by_year, function(file) {
  
  id_year <- str_extract(dirname(file), "\\d{4}") |> 
    as.integer()
  
  team_ids <- read.csv(file)
  
  stacked_full_scores %>%
    filter(year == id_year) %>%
    left_join(
      team_ids,
      by = c("Team B" = "Team"),
      relationship = "many-to-one"
    ) %>%
    rename(Team.B.ID = Team.ID)
  
}) %>%
  list_rbind()

### fix chronology ----

stacked_full_scores <- order_matches(stacked_full_scores)


### export ----

output_csv_path <- file.path(output_dir, "cleaned_matches.csv")
fwrite(stacked_full_scores, output_csv_path)
