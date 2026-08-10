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
