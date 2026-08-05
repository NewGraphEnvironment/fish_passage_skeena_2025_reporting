# Cache the context layers the site maps draw ------------------------------
#
# NOT sourced during book rendering. Run it by hand when the cached layers need
# regenerating, then commit what it writes to `data/gis/`.
#
# The book must build from a fresh `git clone` with no database and no network,
# so everything the map needs beyond `data/bcfishpass.sqlite` is pulled here once
# and committed. `scripts/02_reporting/0420-map-site.R` reads the caches and
# never opens a connection.
#
# Prerequisites:
#   - SSH tunnel to the bcfishpass database, and PG_*_SHARE set in ~/.Renviron
#     (fpr::fpr_db_conn reads PG_DB_SHARE / PG_HOST_SHARE / PG_PORT_SHARE /
#     PG_USER_SHARE / PG_PASS_SHARE)
#   - outbound HTTPS to s3.ca-central-1.amazonaws.com for the MRDEM-30 COG,
#     which flooded::fl_dem_aoi() range-reads via /vsicurl/
#   - outbound HTTPS to basemaps.cartocdn.com for the Positron tiles
#
# Writes, per map unit:
#   data/gis/map_<id>.gpkg          streams, habitat, hydro, roads, rail
#   data/gis/map_<id>_dem.tif       MRDEM-30 clip, for the hillshade
#   data/gis/map_<id>_basemap.tif   Positron RGB, reprojected to BC Albers
#   data/gis/map_<id>_meta.rds      bcfishpass model version + build date
#
# Tile attribution: the Positron basemap is (c) OpenStreetMap contributors and
# (c) CARTO. That has to appear on the map or in its caption - see
# lfpr_map_site()'s caption text.

if (!exists("params") || !isTRUE(params$update_gis)) {
  stop("0410-map-site-prep.R rebuilds committed caches and hits the database ",
       "and the network. Set params$update_gis: TRUE in index.Rmd and run it ",
       "deliberately - it is not part of the book build.", call. = FALSE)
}

library(sf)
sf::sf_use_s2(FALSE)

dir_gis <- "data/gis"
fs::dir_create(dir_gis)

# One map unit per appendix. Both are effectiveness monitoring sites.
map_units <- list(
  c(197962),   # Peacock Creek, Morice FSR
  c(124421)    # Waterfall Creek, 11th Avenue
)

species <- params$model_species  # "bt" here; drives which streams_*_vw is pulled

# --- helpers ---------------------------------------------------------------

pull <- function(sql) {
  out <- try(fpr::fpr_db_query(sql), silent = TRUE)
  if (inherits(out, "try-error")) {
    warning("query failed, layer skipped: ", sub("\n.*", "", attr(out, "condition")$message))
    return(NULL)
  }
  if (!inherits(out, "sf") || nrow(out) == 0) return(NULL)
  sf::st_transform(out, 3005)
}

# bbox as a WKT polygon in BC Albers, for the spatial predicates
bbox_wkt <- function(bb) sf::st_as_text(sf::st_as_sfc(bb))

write_layer <- function(x, path, layer) {
  if (is.null(x) || nrow(x) == 0) {
    message("  ", layer, ": empty, not written")
    return(invisible(NULL))
  }
  sf::st_write(x, path, layer = layer, append = FALSE, quiet = TRUE)
  message("  ", layer, ": ", nrow(x), " features")
}

# --- per map unit ----------------------------------------------------------

for (unit in map_units) {
  id <- as.character(min(unit))
  message("\n=== map unit ", id, " (", paste(unit, collapse = ", "), ") ===")

  # Cache at WATERSHED extent, not survey extent. The main map frames the whole
  # upstream watershed so the reader can see how the crossings and the habitat
  # model interact across the drainage; the survey detail is the keymap. Framing
  # on the union of watershed + crossings + tracks covers both, and the crossing
  # is included explicitly because the watershed polygons do not always contain
  # their own crossings (fpr#130).
  lyr <- lfpr_read_site_local(unit)
  focus <- c(sf::st_as_sfc(sf::st_bbox(lyr$wshd)),
             sf::st_as_sfc(sf::st_bbox(lyr$subject)),
             sf::st_as_sfc(sf::st_bbox(lyr$tracks)))
  bb <- lfpr_bbox_asp(sf::st_bbox(sf::st_buffer(sf::st_as_sfc(sf::st_bbox(focus)), 1500)),
                      asp = 9 / 7)
  wkt <- bbox_wkt(bb)
  message("  extent: ", round((bb[["xmax"]] - bb[["xmin"]]) / 1000, 1), " x ",
          round((bb[["ymax"]] - bb[["ymin"]]) / 1000, 1), " km")

  path_gpkg <- fs::path(dir_gis, paste0("map_", id, ".gpkg"))
  if (fs::file_exists(path_gpkg)) fs::file_delete(path_gpkg)

  # Modelled habitat for the report's species. mapping_code carries both axes:
  # habitat use (SPAWN/REAR/ACCESS) and downstream barrier status.
  write_layer(pull(glue::glue(
    "SELECT segmented_stream_id, blue_line_key, gnis_name, stream_order, gradient,
            channel_width, access, spawning, rearing, mapping_code, geom
     FROM bcfishpass.streams_{species}_vw
     WHERE ST_Intersects(geom, ST_Transform(ST_GeomFromText('{wkt}', 3005), 3005))
       AND mapping_code IS NOT NULL;")), path_gpkg, "habitat")

  # Full stream network for context, including the unmodelled small stuff.
  write_layer(pull(glue::glue(
    "SELECT linear_feature_id, gnis_name, stream_order, geom
     FROM whse_basemapping.fwa_stream_networks_sp
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005))
       AND edge_type != 6010;")), path_gpkg, "streams")

  write_layer(pull(glue::glue(
    "SELECT waterbody_key, gnis_name_1 AS gnis_name, geom
     FROM whse_basemapping.fwa_lakes_poly
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "lakes")

  write_layer(pull(glue::glue(
    "SELECT waterbody_key, geom FROM whse_basemapping.fwa_wetlands_poly
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "wetlands")

  write_layer(pull(glue::glue(
    "SELECT waterbody_key, gnis_name_1 AS gnis_name, geom
     FROM whse_basemapping.fwa_rivers_poly
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "rivers")

  write_layer(pull(glue::glue(
    "SELECT transport_line_id, transport_line_type_code, structured_name_1 AS name, geom
     FROM whse_basemapping.transport_line
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "roads")

  write_layer(pull(glue::glue(
    "SELECT railway_track_id, track_name, owner_name, geom
     FROM whse_basemapping.gba_railway_tracks_sp
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "railway")

  # Modelled crossings that are not PSCIS-assessed. Inside the upstream
  # watershed these are the candidate barriers still to look at, so the map can
  # say what is left to assess above the site rather than only what was done.
  write_layer(pull(glue::glue(
    "SELECT aggregated_crossings_id, stream_crossing_id, modelled_crossing_id,
            crossing_source, barrier_status, geom
     FROM bcfishpass.crossings_vw
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005))
       AND modelled_crossing_id IS NOT NULL;")), path_gpkg, "crossings_modelled")

  # Known fish presence - the QGIS maps carry these as labelled triangles and
  # they are the only direct evidence of what is actually in the system.
  write_layer(pull(glue::glue(
    "SELECT fish_observation_point_id, species_code, observation_date, geom
     FROM bcfishobs.fiss_fish_obsrvtn_events_vw
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "fish_obs")

  # Natural barriers, annotated with height on the QGIS maps
  write_layer(pull(glue::glue(
    "SELECT fiss_obstacle_point_id, obstacle_name, height, geom
     FROM whse_fish.fiss_obstacles_pnt_sp
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005))
       AND obstacle_name != 'Culvert';")), path_gpkg, "obstacles")

  write_layer(pull(glue::glue(
    "SELECT protected_lands_name AS name, geom
     FROM whse_tantalis.ta_park_ecores_pa_svw
     WHERE ST_Intersects(geom, ST_GeomFromText('{wkt}', 3005));")), path_gpkg, "parks")

  # --- DEM for the hillshade ---
  aoi <- sf::st_as_sf(sf::st_as_sfc(bb))
  dem <- try(flooded::fl_dem_aoi(aoi, buffer = 300), silent = TRUE)
  if (!inherits(dem, "try-error")) {
    terra::writeRaster(
      terra::as.int(dem), fs::path(dir_gis, paste0("map_", id, "_dem.tif")),
      overwrite = TRUE, datatype = "INT2S",
      gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"))
    message("  dem: ", paste(dim(dem)[1:2], collapse = " x "), " cells")
  } else {
    warning("DEM fetch failed for ", id, " - hillshade will be skipped")
  }

  # --- Positron basemap tiles ---
  # Request tiles for a padded bbox. Tiles arrive in Web Mercator and are
  # reprojected to BC Albers, which turns the covered area into a slightly
  # rotated quad - request exactly the frame and the corners come back empty,
  # leaving white wedges. The padding is proportionally more important at small
  # extents, where the rotation is a larger share of the frame.
  pos <- try(maptiles::get_tiles(
    sf::st_transform(sf::st_buffer(sf::st_as_sfc(bb),
                                   (bb[["xmax"]] - bb[["xmin"]]) * 0.10), 4326),
    provider = "CartoDB.PositronNoLabels", zoom = 12, crop = TRUE), silent = TRUE)
  if (!inherits(pos, "try-error")) {
    pos <- terra::project(pos, "EPSG:3005", method = "bilinear")
    terra::writeRaster(
      pos, fs::path(dir_gis, paste0("map_", id, "_basemap.tif")),
      overwrite = TRUE, datatype = "INT1U",
      gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
    message("  basemap: ", paste(dim(pos)[1:2], collapse = " x "), " cells")
  } else {
    warning("tile fetch failed for ", id, " - basemap will be skipped")
  }

  # --- version stamp, so the caption can cite the model with no database ---
  ver <- try(fpr::fpr_db_query(
    "SELECT MAX(model_run_id) AS model_run_id FROM bcfishpass.log_parameters_habitat_thresholds;"),
    silent = TRUE)
  saveRDS(list(
    map_unit     = unit,
    species      = species,
    model_run_id = if (inherits(ver, "try-error")) NA else ver$model_run_id[1],
    built        = Sys.Date(),
    bbox         = bb
  ), fs::path(dir_gis, paste0("map_", id, "_meta.rds")))
}

# --- what this cost us in repo size ---------------------------------------
cache <- fs::dir_info(dir_gis)
message("\ndata/gis cache: ", nrow(cache), " files, ",
        round(sum(as.numeric(cache$size)) / 1024^2, 1), " MB")
# as.numeric first - fs_bytes has no unary minus, so order(-cache$size) errors
print(cache[order(as.numeric(cache$size), decreasing = TRUE), c("path", "size")], n = 30)
