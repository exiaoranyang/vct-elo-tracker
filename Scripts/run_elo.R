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

matches <- read_csv(data_dir, show_col_types = FALSE)

dictionary <- list.files(path = dic_dir, 
                         pattern = "\\.csv$", 
                         full.names = TRUE) 

for (file in dictionary) {
  df_name <- tools::file_path_sans_ext(basename(file))
  assign(df_name, read.csv(file))
}

### Elo ----

# setup

starting_elo <- config$elo$start

team_status <- list()

matches <- matches %>%
  arrange(Match.ID) %>%
  mutate(
    Team.A.Start.Elo = NA_real_,
    Team.B.Start.Elo = NA_real_,
    Team.A.End.Elo = NA_real_,
    Team.B.End.Elo = NA_real_,
    differential = `Team A Score` - `Team B Score`,
    Team.A.Win = NA_real_,
    E.Team.A = NA_real_,
    E.Team.B = NA_real_,
    K.A = NA_real_,
    K.B = NA_real_,
    Draft.Team.A.Elo = NA_real_,
    Draft.Team.B.Elo = NA_real_
         )

matches <- matches %>%
  mutate(
    BO1 = case_when(`Team A Score` + `Team B Score` > 5 ~ 1, TRUE ~ 0),
    Team.A.Win = case_when(differential > 0 ~ 1, TRUE ~ 0)
    )

# iterate

for (i in seq_len(nrow(matches))) {
  
  current_row <- matches[i, ]
  
  a_id <- current_row$Team.A.ID
  b_id <- current_row$Team.B.ID
  
  # parse team A info
  
  if (is.null(team_status[[as.character(a_id)]])) {

    Team.A.Elo <- starting_elo
    
  } else {
    
    Team.A.Elo <- team_status[[as.character(a_id)]]$elo
  }
  
  # parse Team B info
  
  if (is.null(team_status[[as.character(b_id)]])) {
    
    Team.B.Elo <- starting_elo
    
  } else {
    
    Team.B.Elo <- team_status[[as.character(b_id)]]$elo
  }
  
  # Save pre-match values
  current_row$Team.A.Start.Elo <- Team.A.Elo
  current_row$Team.B.Start.Elo <- Team.B.Elo
  
  # Run elo calculation
  
  current_row <- run_elo_calc(
    i = current_row,
    eloconfigs = config$elo
  )
  
  # Save post-match values
  
  matches$Team.A.Start.Elo[i] <- current_row$Team.A.Start.Elo
  matches$Team.B.Start.Elo[i] <- current_row$Team.B.Start.Elo
  
  matches$E.Team.A[i] <- current_row$E.Team.A
  matches$E.Team.B[i] <- current_row$E.Team.B
  
  matches$K.A[i] <- current_row$K.A
  matches$K.B[i] <- current_row$K.B
  
  matches$Draft.Team.A.Elo[i] <- current_row$Draft.Team.A.Elo
  matches$Draft.Team.B.Elo[i] <- current_row$Draft.Team.B.Elo
  
  matches$Team.A.End.Elo[i] <- current_row$New.Team.A.Elo
  matches$Team.B.End.Elo[i] <- current_row$New.Team.B.Elo
  
  # and status
  
  team_status[[as.character(a_id)]] <- list(
    elo = current_row$New.Team.A.Elo
  )
  
  team_status[[as.character(b_id)]] <- list(
    elo = current_row$New.Team.B.Elo
  )
}

### View all time ----

team_status_view <- data.frame(
  Team.ID = names(team_status),
  Team.Elo = sapply(team_status, function(x) x$elo),
  row.names = NULL
)

team_status_view <- team_status_view %>%
  mutate(
    Team.ID = as.integer(Team.ID)
  ) %>%
  left_join(all_teams_ids, by = c("Team.ID"))

