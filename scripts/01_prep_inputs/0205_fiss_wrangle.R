# Params
{
year <- 2025


# read in the mega form and convert to sf object
path_form_fiss_site_raw <- fs::path("~/Projects/repo/fish_passage_template_reporting/data/backup/", year, paste0("form_fiss_", year, ".csv"))

form_fiss_site_raw <- readr::read_csv(path_form_fiss_site_raw) |>
  fpr::fpr_sp_assign_sf_from_utm()


# clean

##### Fix the timezone #####
# We need to fix the times because they are in UTC and we need them in PDT. This issue is documented here https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/18

form_fiss_site_time_fix <- form_fiss_site_raw |>
  # make a new column for the time as is with different name then mutate to PST
  # we don't need the new column but will leave here for now so we can visualize and confirm the time is correct
  dplyr::mutate(
    date_time_start_raw = date_time_start,
    date_time_start = lubridate::force_tz(date_time_start_raw, tzone = "UTC"),
    date_time_start = lubridate::with_tz(date_time_start, tzone = "America/Vancouver")
  ) |>
  dplyr::relocate(date_time_start_raw, .after = date_time_start)


## Double check the time is correct and now remove the date_time_start_raw column
form_fiss_site_raw <- form_fiss_site_time_fix |>
  dplyr::select(-date_time_start_raw)

##### END time hack




# clean up the form -----------------------
form_fiss_site_prep1 <- form_fiss_site_raw |>
  # split the local_name into the site, location, and ef
  tidyr::separate(local_name, into = c("site", "location", "ef"), remove = FALSE) |>
  dplyr::mutate(local_name = stringr::str_trim(local_name)) |>
  # split out the date and the time - change type of column first
  dplyr::mutate(date_time_start = lubridate::ymd_hms(date_time_start, tz = "America/Vancouver"),
                date_time_start = lubridate::floor_date(date_time_start, unit = "second"),  # Remove microseconds
                survey_date = lubridate::date(date_time_start),
                time = hms::as_hms(date_time_start),
                # Fix some vocabulary. Change "trib" to long version "Tributary" etc.
                gazetted_names = stringr::str_replace_all(gazetted_names, 'Trib ', 'Tributary '),
                crew_members = toupper(crew_members),
                # fill in text columns from spreadsheet that will likely never change
                waterbody_type = 'stream',
                method_for_utm = 'GPS general',
                method_for_channel_width = 'metre tape',
                method_for_wetted_width = 'metre tape',
                method_for_residual_pool_depth = 'metre stick',
                method_for_bankfull_depth = 'metre stick',
                method_for_gradient = 'clinometer',
                method_for_temperature = 'recording meter',
                method_for_conductivity = 'recording meter',
                method_for_p_h = 'pH meter (general)') |>
  # arrange by surveyor and date/time
  dplyr::arrange(mergin_user, date_time_start) |>
  # ditch the time since we don't need anymore. Time was dropped on gpkg creation due to type conflict
  dplyr::select(-time) |>
  # rearrange the columns for easier QA in QGIS.
  dplyr::select(
    date_time_start,
    local_name,
    gazetted_names,
    crew_members,
    comments,
    everything()) |>
  dplyr::arrange(date_time_start)



## Query database to get 1:50,000 watershed codes ---------------------
# Really kind of humorous that we are getting 1:50,000 watershed codes from the database then the province turns around
# and converts them back to 1:20,000 (pers. comm. Dave McEwan - Fisheries Standards Biologist - 778 698-4010 - Dave.McEwan@gov.bc.ca).

ids <- form_fiss_site_prep1 |>
  dplyr::distinct(site) |>
  dplyr::pull(site)

wscodes_raw <- fpr::fpr_db_query(
  query = glue::glue("
    SELECT DISTINCT ON (a.stream_crossing_id)
      a.stream_crossing_id,
      a.linear_feature_id,
      a.watershed_group_code,
      b.watershed_code_50k,
      b.blue_line_key_20k,
      b.watershed_key_20k,
      b.blue_line_key_50k,
      b.watershed_key_50k,
      b.match_type
    FROM bcfishpass.crossings_vw a
    LEFT OUTER JOIN whse_basemapping.fwa_streams_20k_50k b
      ON a.linear_feature_id = b.linear_feature_id_20k
    WHERE a.stream_crossing_id IN ({glue::glue_collapse(glue::single_quote(ids), sep = ', ')})
    ORDER BY a.stream_crossing_id, b.match_type;
  ")
)


parse_ws_code <- function(code) {
  dplyr::case_when(
    stringr::str_length(code) < 45 ~ NA_character_,
    TRUE ~ stringr::str_c(
      stringr::str_sub(code, 1, 3), "-",  stringr::str_sub(code, 4, 9), "-",  stringr::str_sub(code, 10, 14), "-",
      stringr::str_sub(code, 15, 19), "-", stringr::str_sub(code, 20, 23), "-", stringr::str_sub(code, 24, 27), "-",
      stringr::str_sub(code, 28, 30), "-", stringr::str_sub(code, 31, 33), "-", stringr::str_sub(code, 34, 36), "-",
      stringr::str_sub(code, 37, 39), "-", stringr::str_sub(code, 40, 42), "-", stringr::str_sub(code, 43, 45)
    )
  )
}


wscodes <- wscodes_raw |>
  dplyr::filter(stringr::str_length(watershed_code_50k) == 45) |>
  dplyr::mutate(watershed_code_50k_parsed = parse_ws_code(watershed_code_50k))


## join watershed codes to form_fiss_site
form_fiss_site_prep2 <- dplyr::left_join(
  form_fiss_site_prep1 |>
    dplyr::mutate(site = as.integer(site)),

  wscodes |>
    dplyr::select(stream_crossing_id, watershed_code_50k = watershed_code_50k_parsed, watershed_group_code),

  by = c('site' = 'stream_crossing_id')) |>

  dplyr::mutate(waterbody_id = paste0('00000', watershed_group_code),
                waterbody_type = 'stream')


## Calculate the average of the numeric columns

# aggregate the numeric columns
# as per the example in ?ngr_str_df_col_agg
col_str_negate = "time|method|avg|average"
col_str_to_agg <- c("channel_width", "wetted_width", "residual_pool", "gradient", "bankfull_depth")
columns_result <- c("avg_channel_width_m", "avg_wetted_width_m", "average_residual_pool_depth_m", "average_gradient_percent", "average_bankfull_depth_m")

# we need to convert all the logical columns to numbers, for some reason channel_width_m_7 is a logical right now
form_fiss_site_prep2 <- form_fiss_site_prep2 |>
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::where(is.logical) &
        dplyr::matches(stringr::str_c(col_str_to_agg, collapse = "|")) &
        !dplyr::matches(col_str_negate),
      as.numeric
    )
  )

form_fiss_site_prep3 <- purrr::reduce(
  .x = seq_along(col_str_to_agg),
  .f = function(dat_acc, i) {
    ngr::ngr_str_df_col_agg(
      # we call the dataframe that accumulates results dat_acc
      dat = dat_acc,
      col_str_match = col_str_to_agg[i],
      col_result = columns_result[i],
      col_str_negate = col_str_negate,
      decimal_places = 1
    )
  },
  .init = form_fiss_site_prep2
)



# burn back to projects -----------------

form_fiss_site_export <- form_fiss_site_prep3 |>
  dplyr::group_split(source)

purrr::walk(
  .x = form_fiss_site_export,
  .f = ~ sf::st_write(
    obj = .x,
    dsn = unique(.x$source)[1],
    append = FALSE,
    delete_dsn = TRUE
  )
)

# remove all intermediate prep objects
rm(
  list = ls(pattern = "^form_fiss_site_prep"),
  envir = .GlobalEnv
)


# backup -----------------

source("scripts/01_prep_inputs/0100_backup_forms.R")

}
