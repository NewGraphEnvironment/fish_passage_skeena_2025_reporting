# Build photo amalgamation for each site

## Params

# for skeena and fraser
dir_photos_onedrive <- fs::path("~/Library/CloudStorage/OneDrive-Personal/Projects/", params$job_name, "/data/photos/", params$project_region, "renamed")

# for peace
# dir_photos_onedrive <- fs::path("~/Library/CloudStorage/OneDrive-Personal/Projects/", params$job_name, "/data/photos/renamed")

# path to form_pscis_<year>
path_form_pscis <- fs::path(
  "~/Projects/gis/",
  params$gis_project_name,
  "/data_field/",
  params$project_year,
  paste0("form_pscis_", params$project_year, ".gpkg")
)


# get a list of sites to burn
sites_l <- fpr::fpr_sp_gpkg_backup(
  path_form_pscis,
  update_site_id = FALSE,
  write_to_rdata = FALSE,
  write_to_csv = FALSE,
  write_back_to_path = FALSE,
  return_object = TRUE
) |>
  dplyr::distinct(site_id) |>
  dplyr::arrange(site_id) |>
  dplyr::pull(site_id)


# burn the amalgamated photos to onedrive
sites_l |>
  purrr::map(fpr::fpr_photo_amalg_cv, dir_photos = paste0(dir_photos_onedrive, "/"))
