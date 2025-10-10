# make map of site vs species to send to UNBC

# for the future - set factor order of how to prioritize species. not useing since is dependent on stream and region. did by hand
# fct_order <- c("BT", "GR", "CH", "RB", "KO")

# read iin edna form
d <- readr::read_csv(
  "data/backup/2025/form_edna_2025.csv"
) |>
  dplyr::select(
    site_id,
    # date_time_sample,
    species_target
    # makes it easier to see where manual changes are helpful
    # source
  ) |>
  dplyr::mutate(
    # Replace commas and periods with spaces
    species_target = stringr::str_replace_all(species_target, "[,\\.]", " ") |>
      # Collapse multiple spaces into a single space
      stringr::str_replace_all("\\s+", " ") |>
      # Trim leading/trailing spaces
      stringr::str_trim() |>
      # Convert to uppercase
      stringr::str_to_upper()
  ) |>
  dplyr::arrange(site_id)


# burn to the repo so we can point the lab to it
d |>
  readr::write_csv(
    "data/backup/2025/edna_species_for_UNBC.csv"
  )


