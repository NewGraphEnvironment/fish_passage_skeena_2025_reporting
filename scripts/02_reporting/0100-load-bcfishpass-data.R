source('scripts/functions.R')

# load the sqlite database with bcfishpass and other info
# The data must be submitted to the province first before proceeding with this script.

# Require params from index.Rmd - fail with helpful error if not set
# See https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/159
if (!exists("params") || is.null(params$wsg_code)) {
  stop("params$wsg_code must be set in index.Rmd. Example: wsg_code: [PARS, CARP, CRKD]")
}
if (!exists("params") || is.null(params$pscis_funding_project_number)) {
  stop("params$pscis_funding_project_number must be set in index.Rmd. Example: pscis_funding_project_number: fraser_2025_phase1")
}
if (!exists("params") || is.null(params$project_year)) {
  stop("params$project_year must be set in index.Rmd. Example: project_year: 2025")
}
if (!exists("params") || is.null(params$repo_name)) {
  stop("params$repo_name must be set in index.Rmd. Example: repo_name: fish_passage_fraser_2025_reporting")
}

# this is the name of the funding project we used to submit our phase 1 data to the province. We use it to filter the raw
# pscis data for our entire study area to obtain just the data we submitted.
my_funding_project_number <- params$pscis_funding_project_number


# Check bcfishpass model version - skip rebuild if unchanged --------------------------
# See https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/157
version_file <- "data/bcfishpass_model_version.txt"
force_rebuild <- isTRUE(params$force_bcfishpass_rebuild)

# Get current model version from remote
current_model_version <- fpr::fpr_db_query(
  "SELECT MAX(model_run_id) as model_run_id FROM bcfishpass.log_parameters_habitat_thresholds"
)$model_run_id

# Check if rebuild needed
rebuild_needed <- TRUE
if (!force_rebuild && file.exists(version_file) && file.exists("data/bcfishpass.sqlite")) {
  local_version <- as.integer(readLines(version_file, n = 1))
  if (identical(local_version, current_model_version)) {
    message("bcfishpass model unchanged (version ", current_model_version, "), skipping rebuild. Set params$force_bcfishpass_rebuild: true to override.")
    rebuild_needed <- FALSE
  }
}

if (rebuild_needed) {
  message("Building bcfishpass.sqlite (model version ", current_model_version, ")...")

  # Grab bcfishpass data --------------------------
  # this object should be called bcfishpass_crossings_vw or something that better reflects what it is
  bcfishpass <- fpr::fpr_db_query(
    glue::glue(
      "SELECT * from bcfishpass.crossings_vw
    WHERE watershed_group_code IN (
    {glue::glue_collapse(glue::single_quote(params$wsg_code), sep = ', ')}
    );"
    )
  ) |>
    sf::st_drop_geometry()

  # grab the bcfishpass modelling parameters for the spawning and rearing tables and put in the database so it can be used to populate the methods
  # like solutions provided here https://github.com/smnorris/bcfishpass/issues/490
  bcfishpass_spawn_rear_model <- fpr::fpr_db_query(
    query = "SELECT * FROM bcfishpass.log_parameters_habitat_thresholds
    WHERE model_run_id = (SELECT MAX(model_run_id)
    FROM bcfishpass.log_parameters_habitat_thresholds);"
  )

  # # Instead of waiting for the new phase 1 to make it into bcfishpass (rebuilds monday afternoons), lets just pull them from bcdata directly which rebuild nightly (mon to friday)
  #
  # # get all the pscis data for the watersheds from the bcdata database (rebuild nightly, mon to friday)
  # pscis_assessment_svw <- bcdata::bcdc_get_data("WHSE_FISH.PSCIS_ASSESSMENT_SVW")
  #
  #
  # # build a cross reference table for the stream_crossing_id and the external_crossing_reference which is the crossing id we assigned it in the field
  # xref_pscis_my_crossing_modelled <- pscis_assessment_svw |>
  #   janitor::clean_names() |>
  #   dplyr::filter(funding_project_number == my_funding_project_number) |>
  #   dplyr::select(external_crossing_reference, stream_crossing_id) |>
  #   dplyr::mutate(external_crossing_reference = as.numeric(external_crossing_reference)) |>
  #   dplyr::arrange(external_crossing_reference) |>
  #   sf::st_drop_geometry()


  # get all the pscis data for the watershed from the database which is updated weekly on our server
  # could consider naming more effectively in the future
  pscis_assessment_svw <- fpr::fpr_db_query(
    glue::glue(
      "SELECT p.*, wsg.watershed_group_code
     FROM whse_fish.pscis_assessment_svw p
     INNER JOIN whse_basemapping.fwa_watershed_groups_poly wsg
     ON ST_Intersects(wsg.geom,p.geom)
    WHERE wsg.watershed_group_code IN (
    {glue::glue_collapse(glue::single_quote(params$wsg_code), sep = ', ')}
    );"
    )
  )

  # build a cross reference table for the stream_crossing_id and the external_crossing_reference which is the crossing id we assigned it in the field
  xref_pscis_my_crossing_modelled <- pscis_assessment_svw |>
    dplyr::filter(funding_project_number == my_funding_project_number) |>
    dplyr::select(external_crossing_reference, stream_crossing_id) |>
    dplyr::mutate(external_crossing_reference = as.numeric(external_crossing_reference)) |>
    dplyr::arrange(external_crossing_reference) |>
    sf::st_drop_geometry()


  # Load the cleaned habitat_confirmations tracks for this project ---------------------------
  # Forgot to duplicate/rename the layer to for 2025 the layer name is `gps_tracks_2025_ai`
  gps_layer_name <- paste0("gps_tracks_", params$project_year, "_ai")

  path_tracks <- fs::path(
    "~/Library/CloudStorage/OneDrive-Personal/Projects", paste0(params$project_year, "_data"), "gps", paste0("gps_", params$project_year, ".gpkg")
  )

  habitat_confirmation_tracks <- sf::st_read(dsn = path_tracks,
                                             layer = gps_layer_name) |>
    dplyr::filter(repo == params$repo_name & cleaned == TRUE)


  # Initialize and write to sqlite -------------------------------------------------------------------------------------
  # Directory and database created automatically if they don't exist - no manual initialization needed
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }

  conn <- readwritesqlite::rws_connect("data/bcfishpass.sqlite")

  # Drop tables if they exist, then write new data (lngr_drop_table_if_exists from functions.R)
  lngr_drop_table_if_exists("bcfishpass", conn)
  readwritesqlite::rws_write(bcfishpass, exists = FALSE, delete = TRUE,
                             conn = conn, x_name = "bcfishpass")

  lngr_drop_table_if_exists("bcfishpass_spawn_rear_model", conn)
  readwritesqlite::rws_write(bcfishpass_spawn_rear_model, exists = FALSE, delete = TRUE,
                             conn = conn, x_name = "bcfishpass_spawn_rear_model")

  lngr_drop_table_if_exists("pscis_assessment_svw", conn)
  readwritesqlite::rws_write(pscis_assessment_svw, exists = FALSE, delete = TRUE,
                             conn = conn, x_name = "pscis_assessment_svw")

  lngr_drop_table_if_exists("xref_pscis_my_crossing_modelled", conn)
  readwritesqlite::rws_write(xref_pscis_my_crossing_modelled, exists = FALSE, delete = TRUE,
                             conn = conn, x_name = "xref_pscis_my_crossing_modelled")

  lngr_drop_table_if_exists("habitat_confirmation_tracks", conn)
  readwritesqlite::rws_write(habitat_confirmation_tracks, exists = FALSE, delete = TRUE,
                             conn = conn, x_name = "habitat_confirmation_tracks")

  # SQLite does not reduce the on-disk file size after tables are dropped or rows are deleted.
  # The removed data leaves free pages inside the database file, but those pages remain allocated
  # until a VACUUM is run. Running VACUUM rebuilds the database and returns unused space to disk.
  DBI::dbExecute(conn, "VACUUM;")

  readwritesqlite::rws_list_tables(conn)
  readwritesqlite::rws_disconnect(conn)

  # Save version file for next run
  writeLines(as.character(current_model_version), version_file)
  message("bcfishpass.sqlite built successfully. Version ", current_model_version, " saved.")
}
