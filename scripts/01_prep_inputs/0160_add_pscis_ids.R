# Add PSCIS IDs ---------------
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
    update_site_id = TRUE, ## Turn this off after adding pscis ids
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
    dplyr::select(-stream_crossing_id)



## Burn back to geopackage ------------------
  form_pscis_with_ids |>
    sf::st_write(dsn = path_form_pscis,
                 append = FALSE,
                 delete_dsn = TRUE)


## Backup our changes ------------------
  source("scripts/01_prep_inputs/0100_backup_forms.R")
