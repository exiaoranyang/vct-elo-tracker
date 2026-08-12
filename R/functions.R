### parse data sets in this file format ----

parse_df <- function(root_folders, sub_dir, target_df){
  
  target_files <- c()
  
  root_folders <- unique(root_folders)
  
  for (folder in root_folders) {
    if (dir.exists(folder)) {
      
      subfolders <- list.dirs(path = folder, full.names = TRUE, recursive = FALSE)
      target_subf <- subfolders[basename(subfolders) == sub_dir]
      
      for (sub_path in target_subf) {
        targets <- list.files(
          path = sub_path,
          pattern = paste0("^", target_df, "$"),
          full.names = TRUE,
          recursive = TRUE
        )
        
        if (length(targets) > 0 ){
          target_files <- c(target_files, targets[1])
        }
      }
    }
  }

  return(target_files)
}

### stack data ----

stack_dfs <- function(target_dfs, name, output_dir, add_years){
  
  if (add_years) {
    
    years <- str_extract(dirname(target_dfs), "\\d{4}") |> 
      as.integer()
    
    target_csv <- map(
      target_dfs,
      \(x) read_csv(x, show_col_types = FALSE))
    
    target_dfs <- map2(
      target_csv,
      years,
      ~ mutate(.x, year = .y))
    
    stacked <- data.table::rbindlist(
      target_dfs, fill = TRUE )
    
  } 
  
  else {
    
    stacked <- data.table::rbindlist(
      lapply(target_dfs, data.table::fread), fill = TRUE )
    
      }

  output_file_dir <- file.path(output_dir, paste0(name, ".csv"))
  write_csv(stacked, output_file_dir)
  
  return(stacked)
  
}



### elo calc ----

run_elo_calc <- function(i, eloconfigs){
  
      #Set parameters
      
      i$E.Team.A <- 1/(1+10 ^ ((i$Team.B.Start.Elo - i$Team.A.Start.Elo)/400))
      i$E.Team.B <- 1/(1+10 ^ ((i$Team.A.Start.Elo - i$Team.B.Start.Elo)/400))
      
      i$K.A <- dplyr::case_when(
        i$Team.A.Start.Elo < 1200 ~ eloconfigs$K_below_1200,
        i$Team.A.Start.Elo < 1600 ~ eloconfigs$K_below_1600,
        i$Team.A.Start.Elo < 2000 ~ eloconfigs$K_below_2000,
        TRUE ~ eloconfigs$K_above
      )
      
      i$K.B <- dplyr::case_when(
        i$Team.B.Start.Elo < 1200 ~ eloconfigs$K_below_1200,
        i$Team.B.Start.Elo < 1600 ~ eloconfigs$K_below_1600,
        i$Team.B.Start.Elo < 2000 ~ eloconfigs$K_below_2000,
        TRUE ~ eloconfigs$K_above
      )
      
      i$C <- dplyr::case_when(
        i$Severity == 0 ~ eloconfigs$C_low,
        i$Severity == 1 ~ eloconfigs$C_medium,
        i$Severity == 2 ~ eloconfigs$C_high,
        TRUE ~ eloconfigs$C_medium
      )
      
      i$G <- dplyr::case_when(
        i$differential >= 2 & i$BO1 == 0 ~ eloconfigs$G_2,
        TRUE ~ eloconfigs$G_1
      )
  
      # calculate new elos
      
      i$Draft.Team.A.Elo <- i$Team.A.Start.Elo + i$G * i$K.A * 
        ifelse( i$Team.A.Win - i$E.Team.A > 0, 
                i$C * (i$Team.A.Win - i$E.Team.A), 
                ifelse( i$Severity == 2, 0.85 * i$C * (i$Team.A.Win - i$E.Team.A), 
                        i$C * (i$Team.A.Win - i$E.Team.A) ) )
      
      i$Draft.Team.B.Elo <- i$Team.B.Start.Elo + i$G * i$K.B * 
        ifelse( (1 - i$Team.A.Win) - i$E.Team.B > 0,
                i$C * ((1 - i$Team.A.Win) - i$E.Team.B), 
                ifelse( i$Severity == 2, 0.85 * i$C * ((1 - i$Team.A.Win) - i$E.Team.B), 
                        i$C * ((1 - i$Team.A.Win) - i$E.Team.B) ) )
  
      i$New.Team.A.Elo <- pmax(
        eloconfigs$floor,
        i$Draft.Team.A.Elo
      )
      
      i$New.Team.B.Elo <- pmax(
        eloconfigs$floor,
        i$Draft.Team.B.Elo
      )
  
return(i)

    }

### elo full run ----

run_elo <- function(matches, config, matches_severity) {
  
  starting_elo <- config$start
  
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
      C = NA_real_,
      G = NA_real_,
      Draft.Team.A.Elo = NA_real_,
      Draft.Team.B.Elo = NA_real_
    )
  
  matches <- matches %>%
    mutate(
      BO1 = case_when(
        `Team A Score` + `Team B Score` > 5 ~ 1,
        TRUE ~ 0
      ),
      Team.A.Win = case_when(
        differential > 0 ~ 1,
        TRUE ~ 0
      )
    )
  
  matches <- matches %>%
    left_join(
      matches_severity,
      by = c("Match.ID" = "Match ID"),
      multiple = "first"
    )
  
  # Iterate
  for (i in seq_len(nrow(matches))) {
    
    # Get IDs directly from matches
    a_id <- matches$Team.A.ID[i]
    b_id <- matches$Team.B.ID[i]
    
    # Get current Elo for Team A
    if (is.null(team_status[[as.character(a_id)]])) {
      Team.A.Elo <- starting_elo
    } else {
      Team.A.Elo <- team_status[[as.character(a_id)]]$elo
    }
    
    # Get current Elo for Team B
    if (is.null(team_status[[as.character(b_id)]])) {
      Team.B.Elo <- starting_elo
    } else {
      Team.B.Elo <- team_status[[as.character(b_id)]]$elo
    }
    
    # Write start elos
    matches$Team.A.Start.Elo[i] <- Team.A.Elo
    matches$Team.B.Start.Elo[i] <- Team.B.Elo
    
    # extract the row
    current_row <- matches[i, , drop = FALSE]
    
    # Run elo calculation
    current_row <- run_elo_calc(
      i = current_row,
      eloconfigs = config
    )
    
    # Save values
    matches$Team.A.Start.Elo[i] <- current_row$Team.A.Start.Elo
    matches$Team.B.Start.Elo[i] <- current_row$Team.B.Start.Elo
    
    matches$E.Team.A[i] <- current_row$E.Team.A
    matches$E.Team.B[i] <- current_row$E.Team.B
    
    matches$K.A[i] <- current_row$K.A
    matches$K.B[i] <- current_row$K.B
    
    matches$C[i] <- current_row$C
    matches$G[i] <- current_row$G
    
    matches$Draft.Team.A.Elo[i] <- current_row$Draft.Team.A.Elo
    matches$Draft.Team.B.Elo[i] <- current_row$Draft.Team.B.Elo
    
    matches$Team.A.End.Elo[i] <- current_row$New.Team.A.Elo
    matches$Team.B.End.Elo[i] <- current_row$New.Team.B.Elo
    
    # Update team status
    team_status[[as.character(a_id)]] <- list(
      elo = current_row$New.Team.A.Elo
    )
    
    team_status[[as.character(b_id)]] <- list(
      elo = current_row$New.Team.B.Elo
    )
  }
  
  # Return both objects
  list(
    matches = matches,
    team_status = team_status
  )
}