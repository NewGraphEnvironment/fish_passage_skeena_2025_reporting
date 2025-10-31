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


# now put all the photos into directories and rename
cols_match <- c("source", "site_id", "pscis_crossing_id", "my_crossing_reference", "local_name", "photo")
d_deets <- results |>
  purrr::map_dfr(\(x) {
    dplyr::mutate(x, dplyr::across(dplyr::matches(cols_match), as.character))
  }) |>
  # fpr::fpr_tidy_assign_site_id()
  dplyr::select(dplyr::matches(cols_match)) |>
  dplyr::mutate(
    site_id = dplyr::coalesce(site_id, pscis_crossing_id, my_crossing_reference, local_name),
    # for joining
    dir_basename = stringr::str_extract(source, "(?<=/gis/)[^/]+")
  ) |>
  # split out the site and location so we can add deets to the photos if they are us ds ef or ed sites type thing
  tidyr::separate(
    site_id, into = c("site", "location"), extra = "merge"
  )

dir_resized_stub <- "/Users/airvine/Projects/current/temp"
# here is a list of all the photo sources
d_dir <- d_deets |>
  dplyr::select(source, dplyr::matches("photo"), -dplyr::matches("tag")) |>
  tidyr::pivot_longer(dplyr::matches("photo"), values_to = "dir_photo_rel") |>
  dplyr::mutate(dir_photo_rel = fs::path_dir(dir_photo_rel)) |>
  # remove empty results and result of "." (monitioring form edge case that is not true - no photos iin main dir of repo)
  dplyr::filter(!is.na(dir_photo_rel) & dir_photo_rel != ".") |>
  # construct the paths from the source and dir_photo_rel
  dplyr::mutate(
    dir_from_raw = fs::path(
      stringr::str_extract(
        source,
        "^~?/Projects/gis/[^/]+"
      ),
      dir_photo_rel),
    dir_basename = stringr::str_extract(source, "(?<=/gis/)[^/]+"),
    dir_to = fs::path(dir_resized_stub, dir_basename)
  ) |>
  # really we only need distinct dir_from_raw to pull this off
  dplyr::distinct(dir_from_raw, .keep_all = T)

# now add the new locations by joining by source
d <- dplyr::left_join(
  d_deets,

  d_dir |>
    # dplyr::distinct(dir_to, .keep_all = T) |>
    dplyr::distinct(dir_basename, dir_to),
  by = "dir_basename"
)

# for all the photo sources, resize them and copy locally
fs::dir_create(unique(d_dir$dir_to))
# purrr::walk(d, fpr::fpr_photo_resize_batch, dir_target = dir_to)
purrr::walk2(
  d_dir$dir_from_raw, d_dir$dir_to,
  \(x, y) fpr::fpr_photo_resize_batch(dir_source = x, dir_target = y)
)


# becasue we currnetly do not use vectorize dir_ferom and dir_to in function we need to split datframe by
# the dir_to values then run each through the rename funciton
d_split <- d |>
  dplyr::filter(site != 12345) |>
  dplyr::group_split(dir_to)

# since this works
# fpr::fpr_photo_rename(
#   dat = d_split[[1]],
#   col_directories = site,
#   dir_from_stub = unique(d_split[[1]]$dir_to),
#   dir_to_stub = unique(d_split[[1]]$dir_to),
#   col_string_add = TRUE,
#   col_string_append = location,
#   return_df = FALSE
# )

# we run for each in our list of data frames
purrr::walk(
  d_split,
  ~ fpr::fpr_photo_rename(
    dat = .x,
    col_directories = site,
    dir_from_stub = unique(.x$dir_to)[1],
    dir_to_stub   = unique(.x$dir_to)[1],
    col_string_add = TRUE,
    col_string_append = location,
    return_df = FALSE
  )
)
