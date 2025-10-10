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




