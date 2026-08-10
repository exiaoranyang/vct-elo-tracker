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
