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

path_gis <- "/Users/airvine/Projects/gis"

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


# make new version of each form in data_field
# For each dir_in → dir_out pair Back up each of the files listed in name_forms With the stamp "2025"
for (i in seq_along(dir_in)) {
  for (f in name_f) {
    rfp::rfp_fs_backup(
      path_dir_in = dir_in[i],
      path_in_file = f,
      path_dir_out = dir_out[i],
      stamp = "2025"
    )
  }
}


# back up all gpkg in the data_field directories
# ###NOTE that this backs up as is and does not update the easting and northing . prob fine since we have the
# Loop through each project directory, create a year/project-specific backup folder,
# then back up every .gpkg file within it for versioned storage.
for (i in seq_along(name_projects)) {

  dir_backup <- fs::path("data/backup", year, name_projects[i])
  # fs::dir_create(dir_backup)

  path_gpkgs <- fs::dir_ls(dir_out[i], glob = "*.gpkg")

  for (path_gpkg in path_gpkgs) {
    fpr::fpr_sp_gpkg_backup(
      path_gpkg = path_gpkg,
      dir_backup = dir_backup,
      update_utm = TRUE,
      update_site_id = FALSE,  # checks for duplicates
      write_back_to_path = FALSE,
      write_to_csv = TRUE,
      write_to_rdata = TRUE,
      return_object = FALSE
    )
  }
}

# combine all forms together and backup
names_forms <- c("form_edna", "form_fiss", "form_pscis", "form_monitoring")


for (name_form in names_forms) {

  d <- fs::dir_ls(dir_out, glob = paste0("*", name_form, "*")) |>
    purrr::map(\(path) {
      sf::st_read(path, quiet = TRUE) |>
        dplyr::mutate(source = fs::path("~", fs::path_rel(path, start = fs::path_home())))
    }) |>
    purrr::list_rbind()

  dir_backup <- fs::path("data/backup", year)
  # fs::dir_create(dir_backup)

  readr::write_csv(
    d,
    fs::path(dir_backup, paste0(name_form, "_", year, ".csv"))
  )
}

