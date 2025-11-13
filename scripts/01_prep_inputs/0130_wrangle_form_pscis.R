# copy all forms to data_field_{year} directory
year <- 2025

# name your files
name_f <- c(
  "form_edna.gpkg",
  "form_pscis.gpkg",
  "form_fiss_site.gpkg",
  "form_monitoring.gpkg"
)

name_form <- "form_edna.gpkg"

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

for (i in seq_along(name_projects)) {

  dir_backup <- fs::path("data/backup", year, name_projects[i])
  # fs::dir_create(dir_backup)

  path_form_pscis <- fs::path(dir_out[i], paste0("form_pscis_", year, ".gpkg"))

  #read in cleaned form from Q after review and finalization
  # backup to csv and rdata
  form_pscis_raw <- fpr::fpr_sp_gpkg_backup(
    path_gpkg = path_form_pscis,
    dir_backup = dir_backup,
    update_utm = TRUE,
    update_site_id = TRUE, ## Turn this off after adding pscis ids
    write_back_to_path = FALSE,
    write_to_csv = TRUE,
    write_to_rdata = TRUE,
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
                                ~ stringr::str_trim(.x)))



  #Burn back to geopackage
  form_pscis_clean |>
    sf::st_write(dsn = path_form_pscis,
                 append = FALSE,
                 delete_dsn = TRUE)
}


