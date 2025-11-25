# Add PSCIS IDs to form pscis ---------------
# Run once we have the pscis ids - object `xref_pscis_my_crossing_modelled`


## Params ----------

# path to form_pscis_<year>
path_form_pscis <- fs::path(
  "~/Projects/gis/",
  params$gis_project_name,
  "/data_field/",
  params$project_year,
  paste0("form_pscis_", params$project_year, ".gpkg")
)

# Object containing cross reference table of pscis IDs
# `xref_pscis_my_crossing_modelled` must be read in from `0120-read-sqlite`
source("scripts/02_reporting/0120-read-sqlite.R")



## Read in the form and add the pscis IDs -------------
  form_pscis_raw <- fpr::fpr_sp_gpkg_backup(
    path_gpkg = path_form_pscis,
    update_utm = TRUE,
    update_site_id = FALSE, ## Turn this off after adding pscis ids
    write_back_to_path = FALSE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE)


  form_pscis_with_ids <- dplyr::left_join(form_pscis_raw,
                                          xref_pscis_my_crossing_modelled,
                                          by = c('my_crossing_reference' = 'external_crossing_reference')) |>

    dplyr::mutate(pscis_crossing_id = dplyr::case_when(
      is.na(pscis_crossing_id) ~ as.numeric(stream_crossing_id),
      TRUE ~ pscis_crossing_id
    )) |>
    dplyr::select(-stream_crossing_id) |>
    dplyr::mutate(site_id = pscis_crossing_id)





## Burn back to geopackage ------------------
  form_pscis_with_ids |>
    sf::st_write(dsn = path_form_pscis,
                 append = FALSE,
                 delete_dsn = TRUE)


## Backup our changes ------------------
  source("scripts/01_prep_inputs/0100_backup_forms.R")




# Add PSCIS IDs to form eDNA ---------------
# Run once we have the pscis ids - object `xref_pscis_my_crossing_modelled`


## Params ----------

  # path to edna form
  path_form_edna <- fs::path(
    "~/Projects/gis/",
    params$gis_project_name,
    "/data_field/",
    params$project_year,
    paste0("form_edna_", params$project_year, ".gpkg")
  )

# Object containing cross reference table of pscis IDs
# `xref_pscis_my_crossing_modelled` must be read in from `0120-read-sqlite`
source("scripts/02_reporting/0120-read-sqlite.R")



## Read in the form and add the pscis IDs -------------
  form_edna_raw <- fpr::fpr_sp_gpkg_backup(
    path_gpkg = path_form_edna,
    update_utm = TRUE,
    update_site_id = FALSE, ## Turn this off after adding pscis ids
    write_back_to_path = FALSE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE)


  form_edna_with_ids <- dplyr::left_join(form_edna_raw,
                                          xref_pscis_my_crossing_modelled,
                                          by = c('site' = 'external_crossing_reference')) |>


    dplyr::mutate(site = dplyr::case_when(
      !is.na(stream_crossing_id) ~ as.numeric(stream_crossing_id),
      TRUE ~ site
    )) |>
    tidyr::separate(site_id, into = c("old_site_num", "location_to_keep"), sep = "_", extra = "merge", remove = FALSE) |>
    dplyr::mutate(site_id = paste0(site, "_", location_to_keep)) |>
    dplyr::select(-c(stream_crossing_id, old_site_num, location_to_keep))






## Burn back to geopackage ------------------
  form_edna_with_ids |>
    sf::st_write(dsn = path_form_edna,
                 append = FALSE,
                 delete_dsn = TRUE)


## Backup our changes ------------------
  source("scripts/01_prep_inputs/0100_backup_forms.R")




  # Add PSCIS IDs to form FISS ---------------
  # Run once we have the pscis ids - object `xref_pscis_my_crossing_modelled`


  ## Params ----------

  # path to form_fiss_site_<year>
  path_form_fiss_site <- fs::path(
    "~/Projects/gis/",
    params$gis_project_name,
    "/data_field/",
    params$project_year,
    paste0("form_fiss_site_", params$project_year, ".gpkg")
  )

  # Object containing cross reference table of pscis IDs
  # `xref_pscis_my_crossing_modelled` must be read in from `0120-read-sqlite`
  source("scripts/02_reporting/0120-read-sqlite.R")



  ## Read in the form and add the pscis IDs -------------
  form_fiss_raw <- fpr::fpr_sp_gpkg_backup(
    path_gpkg = path_form_fiss_site,
    update_utm = TRUE,
    update_site_id = FALSE, ## Turn this off after adding pscis ids
    write_back_to_path = FALSE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE)


  form_fiss_with_ids <- dplyr::left_join(form_fiss_raw,
                                         xref_pscis_my_crossing_modelled,
                                         by = c('site' = 'external_crossing_reference')) |>


    dplyr::mutate(site = dplyr::case_when(
      !is.na(stream_crossing_id) ~ as.numeric(stream_crossing_id),
      TRUE ~ site
    )) |>
    tidyr::separate(local_name, into = c("old_site_num", "location_to_keep"), sep = "_", extra = "merge", remove = FALSE) |>
    dplyr::mutate(local_name = paste0(site, "_", location_to_keep)) |>
    dplyr::select(-c(stream_crossing_id, old_site_num, location_to_keep))






  ## Burn back to geopackage ------------------
  form_fiss_with_ids |>
    sf::st_write(dsn = path_form_fiss_site,
                 append = FALSE,
                 delete_dsn = TRUE)


  ## Backup our changes ------------------
  source("scripts/01_prep_inputs/0100_backup_forms.R")
