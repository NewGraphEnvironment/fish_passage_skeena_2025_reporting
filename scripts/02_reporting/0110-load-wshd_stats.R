# This script does 2 things watershed-related:
# 1. Retrieves the watershed polygons for the watersheds included in the project study area (big scale)
# 2. Retrieves the upstream watershed stats and site elevations for the phase 2 habitat confirmation sites (small scale)


# Load required objects -------------------------------------------------

# `0165-read-sqlite.R` reads in the `bcfishpass` object
source("scripts/02_reporting/0120-read-sqlite.R")


# 1 - Retrieve the watershed polygons for the watersheds included in the project study area (big scale)  -------------------------------------------------

# Grab the watershed polygons included in the project study area - this is displayed in the interactive map
wshd_study_areas <- fpr::fpr_db_query(
  glue::glue( "SELECT * FROM whse_basemapping.fwa_watershed_groups_poly a
              WHERE a.watershed_group_code IN ({glue::glue_collapse(glue::single_quote(params$wsg_code), sep = ', ')})"
  )) |>
  # casts geometries to type "POLYGON" (instead of Multipolygon)
  sf::st_cast("POLYGON") |>
  sf::st_transform(crs = 4326)


# Add to the sqlite
conn <- readwritesqlite::rws_connect("data/bcfishpass.sqlite")
readwritesqlite::rws_list_tables(conn)

# load the watersheds for the  phase 2 habitat confirmation sites
lngr_drop_table_if_exists("wshd_study_areas", conn)
readwritesqlite::rws_write(wshd_study_areas, exists = F, delete = TRUE,
                           conn = conn, x_name = "wshd_study_areas")

readwritesqlite::rws_list_tables(conn)
readwritesqlite::rws_disconnect(conn)



# 2 - Retrieve the upstream watershed stats and site elevations for the phase 2 habitat confirmation sites (small scale)  -------------------------------------------------
# A season with no Phase 2 habitat confirmations (a monitoring-only year, for
# example) reaches here with `pscis_phase2` empty. Everything below assumes at
# least one site: the `str_detect()` pattern built from `pscis_crossing_id`
# collapses to "" and matches nothing useful, and `fpr_sp_watershed()` has no
# crossings to delineate from.
#
# Drop `wshds` rather than leaving it. In a repo spawned from another region the
# stale table is the *previous* region's site watersheds, and the interactive map
# in 0400-results.Rmd will happily draw them. `0120-read-sqlite.R` tolerates the
# table being absent.
# Sites needing an upstream watershed: Phase 2 habitat confirmations and
# effectiveness monitoring sites. Monitoring sites were previously excluded,
# which left a monitoring-only season with no watershed polygons at all and no
# way to draw a site map.
sites_wshd <- unique(c(
  pscis_phase2$pscis_crossing_id,
  form_monitoring$pscis_crossing_id
))
sites_wshd <- sites_wshd[!is.na(sites_wshd)]

if (length(sites_wshd) == 0) {

  conn <- readwritesqlite::rws_connect("data/bcfishpass.sqlite")
  lngr_drop_table_if_exists("wshds", conn)
  readwritesqlite::rws_disconnect(conn)

  message("No Phase 2 or monitoring sites - `wshds` dropped and ",
          "per-site watershed stats skipped.")

} else {

  ## Filter the bcfishpass data to just the phase 2 sites -------------------------------------------------
  bcfishpass_phase2 <- bcfishpass |>
    dplyr::filter(stream_crossing_id %in% as.character(sites_wshd))


  ## Remove crossings on first order streams -------------------------------------------------
  # we needed to remove crossings that are first order because the fwapgr api kicks us off

  bcfishpass_phase2_clean <- bcfishpass_phase2 |>
    dplyr::filter(stream_order != 1)

  # for this years data there is none
  bcfishpass_phase2_1st_order <- bcfishpass_phase2 |>
    dplyr::filter(stream_order == 1)



  ## Extract the watershed data -------------------------------------------------

  # call fwapgr
  wshds_fwapgr <- fpr::fpr_sp_watershed(bcfishpass_phase2_clean)

  # If there was first order watersheds, then combine the following:
  # wshds_combined <- bind_rows(
  #   wshds_fwapgr,
  #   wshds_1ord
  # )



  ## Calculate the watershed stats -------------------------------------------------
  wshds_raw <- fpr::fpr_sp_wshd_stats(dat = wshds_fwapgr) |>
    dplyr::mutate(area_km = round(area_ha/100, 1)) |>
    dplyr::mutate(dplyr::across(contains('elev'), round, 0)) |>
    dplyr::arrange(stream_crossing_id)



  ## Add the site elevations -------------------------------------------------

  # This should eventually get done in `0130_pscis_export_to_template.Rmd`, see issue  https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/56
  # extract the site elevations
  pscis_all_sf <- form_pscis |>
    dplyr::group_split(source) |>
    purrr::map(sngr_get_elev) |>
    dplyr::bind_rows()


  # add in the site elevations to the watershed stats
  wshds <-  dplyr::left_join(
    wshds_raw |> dplyr::mutate(stream_crossing_id = as.numeric(stream_crossing_id)),

    pscis_all_sf |> dplyr::distinct(pscis_crossing_id, .keep_all = T) |>
      sf::st_drop_geometry() |>
      dplyr::select(pscis_crossing_id, elev_site = elev),

    by = c('stream_crossing_id' = 'pscis_crossing_id')) |>
    # put elev_site before elev_min
    dplyr::relocate(elev_site, .before = elev_min)



  ## Add to the geopackage -------------------------------------------------
  path_gis_wshds <- fs::path("~/Projects/gis/", params$gis_project_name, "data_field", params$project_year, "fishpass_mapping.gpkg")

  wshds |>
    sf::st_write(dsn = path_gis_wshds,
                 layer = 'hab_wshds',
                 delete_layer = T,
                 append = F) ##might want to f the append....


  ## Burn to a kml -------------------------------------------------
  #burn to kml as well so we can see elevations
  sf::st_write(wshds |>
                 rename(name = stream_crossing_id),
               append = F,
               delete_layer = T,
               driver = 'kml',
               dsn = "data/inputs_extracted/wshds.kml")



  ## Add to the sqlite -------------------------------------------------
  conn <- readwritesqlite::rws_connect("data/bcfishpass.sqlite")
  readwritesqlite::rws_list_tables(conn)
  lngr_drop_table_if_exists("wshds", conn)  # tolerant - the table is absent on a first run
  readwritesqlite::rws_write(wshds, exists = F, delete = TRUE,
                             conn = conn, x_name = "wshds")
  readwritesqlite::rws_list_tables(conn)
  readwritesqlite::rws_disconnect(conn)

}
