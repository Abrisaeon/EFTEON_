library(tidyverse)
library(lubridate)
library(digest)
library(dplyr)

# =========================================================
# DIRECTORIES
# =========================================================

data_dir <- "D:/NextCloud-Arcus/EFTEON/EFTEON Data/Automatic Weather Stations/EFTEON MCP Mabasa TA AWS/Level zero data"
#data_dir <- "D:/NextCloud-Arcus/EFTEON/EFTEON Data/Enhanced Rain Stations/EFTEON NDR Zingela ERS/Level zero data"
#data_dir <- "D:/Documents/SAEON/EFTEON/SAPRI/Marion Climavue test/5 Mar download"


output_dir <- "D:/NextCloud-Arcus/EFTEON/EFTEON Data/Automatic Weather Stations/EFTEON MCP Mabasa TA AWS/Masterfiles"
#output_dir <- "D:/NextCloud-Arcus/EFTEON/EFTEON Data/Enhanced Rain Stations/EFTEON NDR Zingela ERS/Masterfiles"
#output_dir <- "D:/Documents/SAEON/EFTEON/SAPRI/Marion Climavue test/5 Mar download/Masterfiles"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# =========================================================
# NOMENCLATURE STANDARDIZATION MAP
# =========================================================

var_name_map <- c(
  
  "AirTemp_Avg" = "temp_air_avg",
  "AirTemp_Min" = "temp_air_min",
  "AirTemp_TMn" = "temp_air_min_time",
  "AirTemp_Max" = "temp_air_max",
  "AirTemp_TMx" = "temp_air_max_time",
  
  "RH" = "humid_rel",
  "RH_Min" = "humid_rel_min",
  "RH_TMn" = "humid_rel_min_time",
  "RH_Max" = "humid_rel_max",
  "RH_TMx" = "humid_rel_max_time",
  
  "DewPointTemp_Avg" = "temp_dew_point_avg",
  "DewPointTemp_Min" = "temp_dew_point_min",
  "DewPointTemp_Max" = "temp_dew_point_max",
  
  "Temp_Avg" = "temp_ground_avg",
  "SoilTemp_Avg" = "temp_ground_avg",
  "Temp_Min" = "temp_ground_min",
  "SoilTemp_Min" = "temp_ground_min",
  "Temp_TMn" = "temp_ground_min_time",
  "SoilTemp_TMn" = "temp_ground_min_time",
  "Temp_Max" = "temp_ground_max",
  "SoilTemp_Max" = "temp_ground_max",
  "Temp_TMx" = "temp_ground_max_time",
  "SoilTemp_TMx" = "temp_ground_max_time",
  
  "SlrW_Avg" = "rad_short_in_avg",
  "SlrMJ_Tot" = "rad_short_in_tot",
  "SlrW_Max" = "rad_short_in_max",
  "SlrW_TMx" = "rad_short_in_max_time",
  
  "UVSlrW_Avg" = "rad_uv_avg",
  "UV_W_Avg" = "rad_uv_avg",
  "UVSlrW_Max" = "rad_uv_max",
  "UV_W_Max" = "rad_uv_max",
  "UVSlrW_TMx" = "rad_uv_max_time",
  
  "Rain_Tot" = "rain_tot",
  
  "LeafWetmV_Avg" = "leaf_mv_avg",
  "LWmV_Avg" = "leaf_mv_avg",
  "LeafDryCount_Tot" = "leaf_dry_tot",
  "LWMDry_Tot" = "leaf_dry_tot",
  "LeafConCount_Tot" = "leaf_con_tot",
  "LWMCon_Tot" = "leaf_con_tot",
  "LeafWetCount_Tot" = "leaf_wet_tot",
  "LWMWet_Tot" = "leaf_wet_tot",
  
  "BPress_Avg" = "press_atm_avg",
  "BPressure_Avg" = "press_atm_avg",
  
  "BPress_Min" = "pressure_atm_min",
  "BPressure_Min" = "pressure_atm_min",
  
  "BPress_TMn" = "pressure_atm_min_time",
  "BPressure_TMn" = "pressure_atm_min_time",
  
  "BPress_Max" = "pressure_atm_max",
  "BPressure_Max" = "pressure_atm_max",
  
  "BPress_TMx" = "pressure_atm_max_time",
  "BPressure_TMx" = "pressure_atm_max_time",
  
  "WDir_Avg" = "wind_dir_avg",
  "WindDir_D1_WVT" = "wind_dir_avg",
  
  "WDir_Std" = "wind_dir_sd",
  "WindDir_SD1_WVT" = "wind_dir_sd",
  
  "WSpd_Avg" = "wind_speed_avg",
  "WSpeed_Avg" = "wind_speed_avg",
  
  "WSpd_Min" = "wind_speed_min",
  "WSpeed_Min" = "wind_speed_min",
  
  "WSpd_TMn" = "wind_speed_min_time",
  "WSpeed_TMn" = "wind_speed_min_time",
  
  "WSpd_Max" = "wind_speed_max",
  "WSpeed_Max" = "wind_speed_max",
  
  "WSpd_TMx" = "wind_speed_max_time",
  "WSpeed_TMx" = "wind_speed_max_time",
  
  "WSpd_Std" = "wind_speed_sd",
  "WSpeed_S_WVT" = "wind_speed_sd",
  
  "LoggerBattery_Min" = "batt_min"
)

# =========================================================
# EFTEON STANDARD VARIABLE NAMES
# =========================================================

standard_names <- unique(unname(var_name_map))

# =========================================================
# DISCOVER FILES
# =========================================================
#identify all .dat files
all_files <- list.files(
  data_dir,
  pattern = "\\.dat$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
#exclude all solar, datatableinfo, status and constants tables
excluded_files <- all_files[
  grepl(
    "(Solar|DataTableInfo|Status|Const)",
    basename(all_files),
    ignore.case = TRUE
  )
]

dat_files <- setdiff(
  all_files,
  excluded_files
)

cat(
  "Excluded",
  length(excluded_files),
  "files\n"
)

print(basename(excluded_files))

# =========================================================
# DETECT RESOLUTION
# =========================================================

detect_resolution <- function(file) {
  
  lines <- tryCatch(
    readLines(file, warn = FALSE),
    error = function(e) NULL
  )
  
  if(is.null(lines))
    return(
      tibble(
        file = file,
        resolution = NA,
        reason = "unreadable"
      )
    )
  
  ts <- stringr::str_extract(
    lines,
    "\\d{4}-\\d{2}-\\d{2}[ T]\\d{2}:\\d{2}:\\d{2}"
  )
  
  ts <- ts[!is.na(ts)]
  
  if(length(ts) < 2)
    return(
      tibble(
        file = file,
        resolution = NA,
        reason = "no_ts"
      )
    )
  
  dt <- lubridate::ymd_hms(ts)
  
  res_min <- round(
    median(diff(as.numeric(dt)),
           na.rm = TRUE) / 60
  )

  resolution <- dplyr::case_when(
    res_min == 5 ~ "5min",
    res_min == 10 ~ "10min",
    res_min == 60 ~ "hourly",
    res_min == 1440 ~ "daily",
    TRUE ~ "irregular"
  )
  
  tibble(
    file = file,
    resolution = resolution,
    reason = "ok"
  )
}

# =========================================================
# READ TOA5 FILE
# =========================================================

read_dat <- function(file) {
  
  header <- scan(
    file,
    what = character(),
    sep = ",",
    quote = "\"",
    skip = 1,
    nlines = 1,
    quiet = TRUE
  )
  
  readr::read_csv(
    file,
    skip = 4,
    col_names = header,
    col_types = readr::cols(.default = "c"),
    progress = FALSE,
    show_col_types = FALSE
  )
}

# =========================================================
# CLASSIFY NOMENCLATURE
# =========================================================

classify_nomenclature <- function(
    df,
    standard_names,
    lookup
) {
  
  vars <- names(df)
  
  vars <- setdiff(
    vars,
    c(
      "TIMESTAMP",
      "RECORD",
      "StationID",
      "LoggerSerialNumber",
      "ProgramName",
      "ProgramSignature"
    )
  )
  
  n_standard <- sum(
    vars %in% standard_names
  )
  
  n_legacy <- sum(
    vars %in% names(lookup)
  )
  
  if(n_standard > n_legacy)
    return("native")
  
  "legacy"
}

# =========================================================
# STANDARDIZE NAMES
# =========================================================

standardize_names <- function(df, lookup) {
  
  new_names <- names(df)
  
  idx <- new_names %in% names(lookup)
  
  new_names[idx] <- lookup[
    new_names[idx]
  ]
  
  names(df) <- make.unique(new_names)
  
  df
}

# =========================================================
# REMOVE DUPLICATES
# =========================================================

deduplicate_aws <- function(df) {
  
  if("RECORD" %in% names(df)) {
    
    df <- df |>
      dplyr::distinct(
        TIMESTAMP,
        RECORD,
        .keep_all = TRUE
      )
    
  } else {
    
    df <- df |>
      dplyr::distinct(
        TIMESTAMP,
        .keep_all = TRUE
      )
  }
  
  df
}

# =========================================================
# BUILD FILE INVENTORY
# =========================================================

res_table <- purrr::map_dfr(
  dat_files,
  detect_resolution
) |>
  dplyr::filter(
    reason == "ok",
    resolution != "irregular"
  )

res_table$nomenclature <- sapply(
  res_table$file,
  function(f) {
    
    df <- try(
      read_dat(f),
      silent = TRUE
    )
    
    if(inherits(df, "try-error"))
      return(NA_character_)
    
    classify_nomenclature(
      df,
      standard_names,
      var_name_map
    )
  }
)

# =========================================================
# SAVE INVENTORY
# =========================================================

readr::write_csv(
  res_table,
  file.path(
    output_dir,
    "File_Inventory.csv"
  )
)

print(
  table(
    res_table$resolution,
    res_table$nomenclature
  )
)

# =========================================================
# BUILD MASTER TABLES
# =========================================================

# =========================================================
# COMPLETE TIME SERIES FUNCTION
# =========================================================

complete_master_timeseries <- function(df, resolution) {
  
  # -------------------------------------------------------
  # Check for TIMESTAMP
  # -------------------------------------------------------
  
  if(!"TIMESTAMP" %in% names(df)) {
    warning("TIMESTAMP column not found.")
    return(df)
  }
  
  # -------------------------------------------------------
  # Convert TIMESTAMP to POSIXct
  # -------------------------------------------------------
  
  timestamp_posix <- suppressWarnings(
    lubridate::parse_date_time(
      df$TIMESTAMP,
      orders = c(
        "ymd HMS",
        "ymd HM",
        "ymd"
      ),
      tz = "Africa/Johannesburg"
    )
  )
  
  # -------------------------------------------------------
  # Remove rows with no valid timestamp
  #
  # IMPORTANT:
  # We are NOT removing rows because their data fields
  # are empty. Only rows without a usable timestamp are
  # excluded because they cannot be positioned in the
  # time series.
  # -------------------------------------------------------
  
  valid_timestamp <- !is.na(timestamp_posix)
  
  df <- df[valid_timestamp, , drop = FALSE]
  timestamp_posix <- timestamp_posix[valid_timestamp]
  
  if(nrow(df) == 0) {
    warning("No valid timestamps found.")
    return(df)
  }
  
  # -------------------------------------------------------
  # Identify start and end time
  # -------------------------------------------------------
  
  start_time <- min(
    timestamp_posix,
    na.rm = TRUE
  )
  
  end_time <- max(
    timestamp_posix,
    na.rm = TRUE
  )
  
  message(
    "Start: ",
    format(
      start_time,
      "%Y-%m-%d %H:%M:%S",
      tz = "Africa/Johannesburg"
    ),
    " | End: ",
    format(
      end_time,
      "%Y-%m-%d %H:%M:%S",
      tz = "Africa/Johannesburg"
    )
  )
  
  # -------------------------------------------------------
  # Determine time interval
  # -------------------------------------------------------
  
  interval_seconds <- dplyr::case_when(
    
    resolution == "5min"   ~ 5 * 60,
    
    resolution == "10min"  ~ 10 * 60,
    
    resolution == "hourly" ~ 60 * 60,
    
    resolution == "daily"  ~ 24 * 60 * 60,
    
    TRUE ~ NA_real_
  )
  
  if(is.na(interval_seconds)) {
    warning(
      "Unknown resolution: ",
      resolution
    )
    return(df)
  }
  
  # -------------------------------------------------------
  # Create complete timestamp sequence
  # -------------------------------------------------------
  
  complete_ts <- seq.POSIXt(
    from = start_time,
    to = end_time,
    by = interval_seconds
  )
  
  complete_df <- tibble::tibble(
    TIMESTAMP_POSIX = complete_ts
  )
  
  # -------------------------------------------------------
  # Add POSIX timestamp to original data
  # -------------------------------------------------------
  
  df$TIMESTAMP_POSIX <- timestamp_posix
  
  # -------------------------------------------------------
  # Remove duplicate timestamps
  #
  # The master-building function already performs
  # deduplication, but this provides an additional safeguard
  # before the time-series join.
  # -------------------------------------------------------
  
  df <- df |>
    dplyr::distinct(
      TIMESTAMP_POSIX,
      .keep_all = TRUE
    )
  
  # -------------------------------------------------------
  # Merge original data onto complete time series
  #
  # All timestamps in complete_ts are retained.
  # Missing timestamps therefore automatically receive NA.
  # -------------------------------------------------------
  
  completed <- complete_df |>
    dplyr::left_join(
      df,
      by = "TIMESTAMP_POSIX"
    )
  
  # -------------------------------------------------------
  # Rebuild TIMESTAMP column
  # -------------------------------------------------------
  
  completed$TIMESTAMP <- format(
    completed$TIMESTAMP_POSIX,
    "%Y-%m-%d %H:%M:%S",
    tz = "Africa/Johannesburg"
  )
  
  # -------------------------------------------------------
  # Remove temporary POSIXct column
  # -------------------------------------------------------
  
  completed <- completed |>
    dplyr::select(
      -TIMESTAMP_POSIX
    )
  
  # -------------------------------------------------------
  # Ensure TIMESTAMP is the first column
  # -------------------------------------------------------
  
  completed <- completed |>
    dplyr::select(
      TIMESTAMP,
      dplyr::everything()
    )
  
  # -------------------------------------------------------
  # Report number of missing timestamps
  # -------------------------------------------------------
  
  n_missing <- sum(
    !(complete_ts %in% timestamp_posix)
  )
  
  message(
    "Complete timestamps expected: ",
    length(complete_ts)
  )
  
  message(
    "Missing timestamps filled with NA: ",
    n_missing
  )
  
  completed
}


# =========================================================
# BUILD MASTER TABLES
# =========================================================

master_tables <- res_table |>
  
  dplyr::group_by(
    resolution,
    nomenclature
  ) |>
  
  dplyr::group_map(~ {
    
    res <- .y$resolution
    nom <- .y$nomenclature
    
    message(
      "\n==== Resolution: ",
      res,
      " | Type: ",
      nom
    )
    
    # -----------------------------------------------------
    # Read all files belonging to this group
    # -----------------------------------------------------
    
    dfs <- purrr::map(
      .x$file,
      function(f) {
        
        df <- read_dat(f)
        
        if(
          classify_nomenclature(
            df,
            standard_names,
            var_name_map
          ) == "legacy"
        ) {
          
          df <- standardize_names(
            df,
            var_name_map
          )
        }
        
        df
      }
    )
    
    # -----------------------------------------------------
    # Remove only completely unreadable/zero-row files
    #
    # DO NOT remove rows because all measurement values
    # are NA.
    # -----------------------------------------------------
    
    dfs <- dfs[
      purrr::map_int(
        dfs,
        nrow
      ) > 0
    ]
    
    if(length(dfs) == 0)
      return(NULL)
    
    # -----------------------------------------------------
    # Combine all files
    # -----------------------------------------------------
    
    tbl <- dplyr::bind_rows(dfs)
    
    # -----------------------------------------------------
    # Remove duplicate observations
    #
    # This does NOT remove rows simply because their
    # measurement values are NA.
    # -----------------------------------------------------
    
    tbl <- deduplicate_aws(tbl)
    
    # -----------------------------------------------------
    # Sort by timestamp
    # -----------------------------------------------------
    
    tbl <- tbl |>
      dplyr::arrange(TIMESTAMP)
    
    # -----------------------------------------------------
    # COMPLETE THE TIME SERIES
    #
    # This inserts missing timestamps and fills all their
    # data fields with NA.
    # -----------------------------------------------------
    
    tbl <- complete_master_timeseries(
      tbl,
      res
    )
    
    # -----------------------------------------------------
    # Store metadata
    # -----------------------------------------------------
    
    attr(tbl, "resolution") <- res
    attr(tbl, "nomenclature") <- nom
    
    tbl
    
  }) |>
  
  purrr::compact()

# =========================================================
# CONVERT EMPTY FIELDS TO NA
# =========================================================

convert_empty_to_na <- function(df) {
  
  df %>%
    mutate(
      across(
        where(is.character),
        ~ {
          x <- trimws(.x)
          x[x == ""] <- NA_character_
          x
        }
      )
    )
}
# =========================================================
# WRITE MASTER FILES
# =========================================================

purrr::iwalk(
  master_tables,
  function(df, i) {
    
    res <- attr(df, "resolution")
    nom <- attr(df, "nomenclature")
    
    fname <- paste0(
      "Master_",
      res,
      "_",
      nom,
      ".csv"
    )
    
    readr::write_csv(
      df,
      file.path(
        output_dir,
        fname
      ),
      na = "NA"
    )
    
    message(
      "✔ Written: ",
      fname
    )
  }
)

message("\nProcessing complete.")
# =========================================================
# WRITE MASTER FILES
# =========================================================

purrr::iwalk(
  master_tables,
  function(df, i) {
    
    res <- attr(df, "resolution")
    nom <- attr(df, "nomenclature")
    
    fname <- paste0(
      "Master_",
      res,
      "_",
      nom,
      ".csv"
    )
    
    readr::write_csv(
      df,
      file.path(
        output_dir,
        fname
      ),
      na = "NA"
    )
    
    message(
      "✔ Written: ",
      fname
    )
  }
)

# =========================================================
# IDENTIFY AND WRITE DATA GAP ROWS
# =========================================================

# Read each master file, generate a complete timestamp sequence,
# identify missing timestamps, and write only the missing rows.

master_files <- list.files(
  output_dir,
  pattern = "^Master_(5min|10min|hourly|daily)_(native|legacy)\\.csv$",
  full.names = TRUE
)

# ---------------------------------------------------------
# Function to generate complete timestamp sequence
# ---------------------------------------------------------

complete_timestamps <- function(start_time, end_time, resolution) {
  
  interval <- dplyr::case_when(
    resolution == "5min"   ~ "5 min",
    resolution == "10min"  ~ "10 min",
    resolution == "hourly" ~ "1 hour",
    resolution == "daily"  ~ "1 day",
    TRUE ~ NA_character_
  )
  
  if(is.na(interval))
    stop("Unknown resolution: ", resolution)
  
  seq.POSIXt(
    from = start_time,
    to = end_time,
    by = interval
  )
}

# ---------------------------------------------------------
# Process each master file
# ---------------------------------------------------------

purrr::walk(
  master_files,
  function(file) {
    
    fname <- basename(file)
    
    message(
      "\nChecking gaps in: ",
      fname
    )
    
    # -----------------------------------------------------
    # Extract resolution and nomenclature from filename
    # -----------------------------------------------------
    
    parts <- stringr::str_match(
      fname,
      "^Master_(5min|10min|hourly|daily)_(native|legacy)\\.csv$"
    )
    
    resolution <- parts[, 2]
    nomenclature <- parts[, 3]
    
    # -----------------------------------------------------
    # Read master file
    # -----------------------------------------------------
    
    master <- readr::read_csv(
      file,
      col_types = readr::cols(
        .default = readr::col_character()
      ),
      show_col_types = FALSE
    )
    
    # -----------------------------------------------------
    # Check that TIMESTAMP exists
    # -----------------------------------------------------
    
    if(!"TIMESTAMP" %in% names(master)) {
      
      warning(
        "Skipping ",
        fname,
        ": TIMESTAMP column not found."
      )
      
      return(NULL)
    }
    
    # -----------------------------------------------------
    # Remove completely empty rows
    # -----------------------------------------------------
    
    master <- master[
      rowSums(is.na(master)) < ncol(master),
    ]
    
    # -----------------------------------------------------
    # Convert TIMESTAMP to POSIXct
    # -----------------------------------------------------
    
    master$TIMESTAMP_POSIX <- as.POSIXct(
      master$TIMESTAMP,
      format = "%Y-%m-%d %H:%M:%S",
      tz = "Africa/Johannesburg"
    )
    
    # -----------------------------------------------------
    # If seconds are not present, try yyyy-mm-dd HH:MM
    # -----------------------------------------------------
    
    if(all(is.na(master$TIMESTAMP_POSIX))) {
      
      master$TIMESTAMP_POSIX <- as.POSIXct(
        master$TIMESTAMP,
        format = "%Y-%m-%d %H:%M",
        tz = "Africa/Johannesburg"
      )
    }
    
    # -----------------------------------------------------
    # Check for invalid timestamps
    # -----------------------------------------------------
    
    if(all(is.na(master$TIMESTAMP_POSIX))) {
      
      warning(
        "Skipping ",
        fname,
        ": TIMESTAMP could not be converted to POSIXct."
      )
      
      return(NULL)
    }
    
    # -----------------------------------------------------
    # Determine start and end timestamps
    # -----------------------------------------------------
    
    start_time <- min(
      master$TIMESTAMP_POSIX,
      na.rm = TRUE
    )
    
    end_time <- max(
      master$TIMESTAMP_POSIX,
      na.rm = TRUE
    )
    
    message(
      "Start: ",
      format(start_time, "%Y-%m-%d %H:%M:%S"),
      " | End: ",
      format(end_time, "%Y-%m-%d %H:%M:%S")
    )
    
    # -----------------------------------------------------
    # Generate complete timestamp sequence
    # -----------------------------------------------------
    
    complete_ts <- complete_timestamps(
      start_time,
      end_time,
      resolution
    )
    
    # -----------------------------------------------------
    # Convert master timestamps to comparable format
    # -----------------------------------------------------
    
    master_ts <- unique(
      master$TIMESTAMP_POSIX[
        !is.na(master$TIMESTAMP_POSIX)
      ]
    )
    
    # -----------------------------------------------------
    # Identify timestamps missing from master
    # -----------------------------------------------------
    
    missing_ts <- complete_ts[
      !(complete_ts %in% master_ts)
    ]
    
    # -----------------------------------------------------
    # If there are no gaps
    # -----------------------------------------------------
    
    if(length(missing_ts) == 0) {
      
      message(
        "✔ No gaps found in ",
        fname
      )
      
      return(NULL)
    }
    
    # -----------------------------------------------------
    # Create gap dataframe
    # -----------------------------------------------------
    
    gap_rows <- data.frame(
      TIMESTAMP = format(
        missing_ts,
        "%Y-%m-%d %H:%M:%S",
        tz = "Africa/Johannesburg"
      ),
      stringsAsFactors = FALSE
    )
    
    # -----------------------------------------------------
    # Add all other columns from master file
    # -----------------------------------------------------
    
    other_columns <- setdiff(
      names(master),
      c("TIMESTAMP", "TIMESTAMP_POSIX")
    )
    
    for(col in other_columns) {
      gap_rows[[col]] <- NA_character_
    }
    
    # Ensure column order matches master file
    gap_rows <- gap_rows[
      names(master)[
        names(master) != "TIMESTAMP_POSIX"
      ]
    ]
    
    # -----------------------------------------------------
    # Sort by timestamp
    # -----------------------------------------------------
    
    gap_rows <- gap_rows[
      order(gap_rows$TIMESTAMP),
    ]
    
    # -----------------------------------------------------
    # Write gap file
    # -----------------------------------------------------
    
    gap_filename <- paste0(
      "GapRows_",
      resolution,
      "_",
      nomenclature,
      ".csv"
    )
    
    readr::write_csv(
      gap_rows,
      file.path(
        output_dir,
        gap_filename
      ),
      na = "NA"
    )
    
    message(
      "✔ Written: ",
      gap_filename,
      " (",
      nrow(gap_rows),
      " missing timestamps)"
    )
  }
)


message("\nProcessing complete.")