
# Run the backup file to get the objects needed for this script. Could do this another way but just trying to get this done.
source("scripts/01_prep_inputs/0100_backup_forms.R")



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

dir_resized_stub <- "/Users/lucy/Projects/current/temp"
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
