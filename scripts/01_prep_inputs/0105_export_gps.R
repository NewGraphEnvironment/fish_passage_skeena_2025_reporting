# export gps

dir_out <- "~/Library/CloudStorage/OneDrive-Personal(2)/Projects/2025_data/gps"

rfp::rfp_gpx_import(
  dir_gpx_waypoints = "/Volumes/GARMIN/Garmin/GPX/",
  dir_gpx_tracks = c("/Volumes/GARMIN/Garmin/GPX/Archive/",
                     "/Volumes/GARMIN/Garmin/GPX/Current/"),
  dir_out = dir_out,
  time_start = "2025-01-01",
  time_end = "2099-01-01",
  layer_output_name = "2025_ai",
  gpkg_name = "gps_2025",
  dates_view = FALSE,
  gpx_layer_type = c("waypoints", "tracks", "track_points")
)

# now the other unit
rfp::rfp_gpx_import(
  dir_gpx_waypoints = "/Volumes/GARMIN/Garmin/GPX/",
  dir_gpx_tracks = c("/Volumes/GARMIN/Garmin/GPX/Archive/",
                     "/Volumes/GARMIN/Garmin/GPX/Current/"),
  dir_out = dir_out,
  time_start = "2025-01-01",
  time_end = "2099-01-01",
  layer_output_name = "2025_ls",
  gpkg_name = "gps_2025",
  dates_view = FALSE,
  gpx_layer_type = c("waypoints", "tracks", "track_points")
)


# see what we have
sf::st_layers(
  fs::path(
    dir_out, "gps_2025.gpkg"
  )
)
