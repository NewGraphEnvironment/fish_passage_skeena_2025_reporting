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


# make new version of each form in data_field, if it doesn't already exists
# For each dir_in → dir_out pair Back up each of the files listed in name_forms With the stamp "2025"
for (i in seq_along(dir_in)) {
  for (f in name_f) {

    name_core <- stringr::str_remove(f, "\\.gpkg$")

    # path to the "new" version we want to create if it does not exist
    target_file <- fs::path(
      dir_out[i],
      paste0(name_core, "_", year, ".gpkg")
    )

    if(!fs::file_exists(target_file)){
      rfp::rfp_fs_backup(
        path_dir_in = dir_in[i],
        path_in_file = f,
        path_dir_out = dir_out[i],
        stamp = "2025"
      )
    }
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

# combine all forms together and backup -NEED TO CLOSE Q PROJECTs IF THE FORMA ARE ACTIVE
names_forms <- c("form_edna", "form_fiss", "form_pscis", "form_monitoring")

# initialize a list to store the results
results <- list()
for (name_form in names_forms) {

  d <- fs::dir_ls(dir_out, glob = paste0("*", name_form, "*")) |>
    purrr::map(\(path) {
      sf::st_read(path, quiet = TRUE) |>
        dplyr::mutate(source = fs::path("~", fs::path_rel(path, start = fs::path_home()))) |>
        # b/c the monitoring form schemas are not the same we need to have way to turn back into sf object if
        # we want to burn to geojson.  gpkg burn is smarter but geoj needs to be a sf object
        fpr::fpr_sp_assign_utm()
    }) |>
    purrr::list_rbind()

  dir_backup <- fs::path("data/backup", year)
  # fs::dir_create(dir_backup)

  readr::write_csv(
    d,
    fs::path(dir_backup, paste0(name_form, "_", year, ".csv"))
  )
  # also backup as gpkg that can be tracked with mergin - maybe not necessary?
  sf::st_write(
    d,
    dsn   = fs::path(dir_backup, "forms.gpkg"),
    layer = paste0(name_form, "_", year),
    append = TRUE,             # add/update layers in the same GPKG
    delete_layer = TRUE        # overwrite layer if it already exists
  )
  # also backup as geojson that can be viewed natively on Github
  # fix geometry issues, ensure valid 2D shapes in WGS84, and write as GeoJSON
  d |>
    fpr::fpr_sp_assign_sf_from_utm() |>
    # sf::st_as_sf(coords) |>
    # sf::st_make_valid() |>                      # fix any invalid geometries (common after edits/merges)
    sf::st_transform(4326) |>                       # GeoJSON requires coordinates in WGS84 (EPSG:4326)
    # sf::st_zm(drop = TRUE) |>                       # drop Z/M dimensions (GeoJSON supports 2D only)
    # sf::st_cast(unique(sf::st_geometry_type(d))[1]) |> # ensure single consistent geometry type (no mixes)
    sf::st_write(                                   # finally write valid, web-friendly GeoJSON
      fs::path(dir_backup, paste0(name_form, "_", year, ".geojson")),
      append = FALSE, delete_dsn = TRUE
    )
  # put the results in the list
  results[[name_form]] <- d
}

