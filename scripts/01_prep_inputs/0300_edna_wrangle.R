# Clean up the eDNA from and burn back to geopackage

# Params ----------------------
{
  year <- 2025


  # read in the mega form and convert to sf object
  path_form_edna_raw <- fs::path("~/Projects/repo/fish_passage_template_reporting/data/backup/", year, paste0("form_edna_", year, ".csv"))

  form_edna_raw <- readr::read_csv(path_form_edna_site_raw) |>
    fpr::fpr_sp_assign_sf_from_utm()



  ##### Fix the timezone #####
  # We need to fix the times because they are in UTC and we need them in PDT. This issue is documented here https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/18

  form_edna_time_fix <- form_edna_raw |>
    # make a new column for the time as is with different name then mutate to PST
    # we don't need the new column but will leave here for now so we can visualize and confirm the time is correct
    dplyr::mutate(
      date_time_sample_raw = date_time_sample,
      date_time_sample = lubridate::force_tz(date_time_sample_raw, tzone = "UTC"),
      date_time_sample = lubridate::with_tz(date_time_sample, tzone = "America/Vancouver")
    ) |>
    dplyr::relocate(date_time_sample_raw, .after = date_time_sample)


  ## Double check the time is correct and now remove the date_time_start_raw column
  form_edna_raw <- form_edna_time_fix |>
    dplyr::select(-date_time_sample_raw)

  ##### END time hack




  # clean up the form -----------------------
  form_edna_prep1 <- form_edna_raw |>
    # split the local_name into the site, location, and ef
    tidyr::separate(site_id, into = c("site", "location", "ed"), remove = FALSE) |>
    dplyr::mutate(site_id = stringr::str_trim(site_id),
                  # Fix some vocabulary. Change "trib" to long version "Tributary" etc.
                  stream_name = stringr::str_to_title(stream_name),
                  stream_name = stringr::str_replace_all(stream_name, 'Trib ', 'Tributary '),
                  crew_members_sample = stringr::str_replace_all(crew_members_sample, "[,\\.]", " ") |>
                    # Collapse multiple spaces into a single space
                    stringr::str_replace_all("\\s+", " ") |>
                    # Trim leading/trailing spaces
                    stringr::str_trim() |>
                    # Convert to uppercase
                    stringr::str_to_upper(),
                  # lower-case a named set of columns
                  dplyr::across(
                    .cols = dplyr::all_of(c(
                      "site_description_habitat_type",
                      "method_sample",
                      "method_preservation"
                    )),
                    .fns = ~ stringr::str_to_lower(.x)
                  ),
                  filter_type = stringr::str_to_lower(filter_type),
                  comments_field = stringr::str_trim(comments_field),
                  comments_lab = stringr::str_trim(comments_lab))



  # burn back to projects -----------------

  form_edna_export <- form_edna_prep1 |>
    dplyr::group_split(source)

  purrr::walk(
    .x = form_edna_export,
    .f = ~ sf::st_write(
      obj = .x,
      dsn = unique(.x$source)[1],
      append = FALSE,
      delete_dsn = TRUE
    )
  )

  # backup -----------------

  source("scripts/01_prep_inputs/0100_backup_forms.R")

}
