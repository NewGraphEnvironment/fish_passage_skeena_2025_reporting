# copy all forms to data_field_{year} directory
year <- 2025

path_gis <- "/Users/lucy/Projects/gis"

# list projects
name_projects <- c(
  "sern_peace_fwcp_2023",
  "sern_fraser_2024",
  "sern_skeena_2023"
)

# define data dir
dir_out <-   fs::path(
  path_gis, name_projects, "data_field", year
)

dir_in <- fs::path(
  path_gis, name_projects
)


### Wrangle PSCIS forms ------------------------

# initialize a list to store the results
results <- list()

for (i in seq_along(name_projects)) {

  path_form_pscis <- fs::path(dir_out[i], paste0("form_pscis_", year, ".gpkg"))

  #read in cleaned form from Q after review and finalization
  form_pscis_raw <- fpr::fpr_sp_gpkg_backup(
    path_gpkg = path_form_pscis,
    update_utm = TRUE,
    update_site_id = TRUE, ## Turn this off after adding pscis ids
    write_back_to_path = FALSE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE)



  # Do some more cleaning
  form_pscis_clean <- form_pscis_raw |>
    dplyr::mutate(date_time_start = lubridate::ymd_hms(date_time_start, tz = "America/Vancouver"),
                  date = lubridate::date(date_time_start),

                  # Fix the vocabulary
                  stream_name = stringr::str_replace_all(stream_name, 'Trib ', 'Tributary '),
                  stream_name = stringr::str_to_title(stream_name),
                  road_name = stringr::str_to_title(road_name),
                  road_name = stringr::str_replace_all(road_name, 'Hwy', 'Highway '),
                  road_name = stringr::str_replace_all(road_name, 'Fsr', 'FSR'),
                  road_name = stringr::str_replace_all(road_name, 'Rd', 'Road '),
                  crew_members = stringr::str_to_upper(crew_members),

                  # remove white space from comments
                  assessment_comment = stringr::str_squish(assessment_comment),
                  dplyr::across(tidyselect::matches("assessment_comment|_notes"),
                                ~ stringr::str_trim(.x))) |>

    # Add in the scores using the new xfm_ functions
    fpr::fpr_xfm_paw_all_scores_result() |>
    fpr::fpr_xfm_paw_xing_fix_size()



  #Burn back to geopackage
  form_pscis_clean |>
    sf::st_write(dsn = path_form_pscis,
                 append = FALSE,
                 delete_dsn = TRUE)


  # add cleaned pscis df to results so we can check to make sure everything looks good.
  results[[name_projects[i]]] <- form_pscis_clean

  # Backup our changes
  source("scripts/01_prep_inputs/0100_backup_forms.R")
}


