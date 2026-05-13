# Regenerate climate-departure data for the report appendix.
#
# NOT run during book rendering — only to regenerate cached data in
# data/gis/. Same script is reused across regional reports; only the
# `wsg_codes` and `town_names` vectors below need editing for a new
# AOI. Filenames are AOI-neutral so the rest of the chain
# (`0820-appendix-climate-departure.Rmd`-style appendix, body
# rollup chunks) is portable across reports.
#
# Generates (under data/gis/):
#   climate_departure.gpkg                 multi-layer GeoPackage with sf
#                                          layers: aoi, wsgs, ecoregions,
#                                          towns, lakes, rivers, streams,
#                                          highways
#   climate_departure.rds                  cd outputs: named list with
#                                          `regional` (ts/bl/ano/trn/cmp/
#                                          cmp_pct) and `ecoregion`
#                                          (per-ecoregion same shape,
#                                          keyed by ecoregion code)
#   climate_departure_tmean.tif            spatial tmean departure raster
#                                          (2015-2025 mean minus
#                                          1951-1980 mean, masked to AOI)
#   climate_departure_wsg_ecoregion.csv    WSG × ecoregion percentage
#                                          crosswalk
#
# Phase 1 (this script as committed): AOI + context + ecoregions →
#   climate_departure.gpkg
# Phase 2 (separate commit): extends this script with the cd pipeline
#   to produce the rds + tif + csv.
#
# Prerequisites:
#   - SSH tunnel to fwapg PostgreSQL up; PG_* env vars set
#     (defaults of fresh::frs_db_conn())
#   - bcdata package installed (ecoregions are pulled from BCDC, not
#     fwapg)
#   - cd >= 0.3.0 (used in Phase 2 — checked at the top so the script
#     fails fast)

# ---- params -------------------------------------------------------------

wsg_codes <- c("LCHL", "NECR", "FRAN", "MORK", "UFRA", "TABR", "WILL")

# Towns to label on AOI maps. Curated list of cities / towns / villages
# inside or adjacent to the AOI. Missing names are logged so the list
# can be revised if a place renames or wasn't in the gns table.
town_names <- c(
  "Prince George", "Quesnel", "Williams Lake", "Vanderhoof",
  "Fraser Lake", "100 Mile House", "McBride", "Valemount"
)

# Lake size threshold and stream-order cutoff are tuned for a multi-WSG
# regional AOI of this scale — same tuning Peace used for its ~73,000
# km² AOI.
min_lake_area_ha <- 1000
min_stream_order <- 7

# Buffer applied to AOI bbox when fetching context layers. Catches
# towns and highway segments just outside the AOI for orientation
# without dragging in distant features.
context_buffer_m <- 30000

# Geometry simplification tolerance for the bundled gpkg. 200 m is
# fine for regional-scale maps and cuts file size ~10x.
simplify_tol_m <- 200

# ---- preflight ----------------------------------------------------------

stopifnot(
  "cd >= 0.3.0 required (window/test defaults used in Phase 2)" =
    utils::packageVersion("cd") >= "0.3.0"
)

# ---- env ----------------------------------------------------------------

library(fresh)
library(sf)
library(bcdata)

out_dir <- file.path("data", "gis")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_gpkg <- file.path(out_dir, "climate_departure.gpkg")

# Wipe the gpkg at start so we never carry stale layers across re-runs.
if (file.exists(out_gpkg)) file.remove(out_gpkg)

write_layer <- function(x, layer_name) {
  sf::st_write(x, out_gpkg, layer = layer_name,
               delete_layer = TRUE, append = TRUE, quiet = TRUE)
}

# ---- 1. DB connection ---------------------------------------------------

message("Connecting to fwapg ...")
conn <- fresh::frs_db_conn()
on.exit(try(DBI::dbDisconnect(conn), silent = TRUE), add = TRUE)

# ---- 2. Watershed groups + dissolved AOI --------------------------------

message("Fetching ", length(wsg_codes), " watershed group boundaries ...")
wsg_codes_sql <- paste0("'", wsg_codes, "'", collapse = ", ")
wsgs <- sf::st_read(
  conn,
  query = sprintf("
    SELECT watershed_group_code AS code,
           watershed_group_name AS name,
           area_ha,
           geom
    FROM whse_basemapping.fwa_watershed_groups_poly
    WHERE watershed_group_code IN (%s)", wsg_codes_sql),
  quiet = TRUE
)
wsgs <- sf::st_zm(wsgs, drop = TRUE, what = "ZM")
missing_wsgs <- setdiff(wsg_codes, wsgs$code)
if (length(missing_wsgs)) {
  stop("Missing WSG codes in fwa_watershed_groups_poly: ",
       paste(missing_wsgs, collapse = ", "))
}
message(sprintf("  found: %s", paste(wsgs$code, collapse = ", ")))

# AOI = dissolved union of the WSGs. Keep in 3005 for spatial-filter
# queries below; transform to 4326 just before the final write.
aoi_3005 <- sf::st_union(wsgs)
aoi_3005 <- sf::st_sf(region = "FWCP Fraser climate-departure",
                      geom = aoi_3005)
aoi_km2 <- as.numeric(sum(sf::st_area(aoi_3005))) / 1e6
message(sprintf("  AOI area: %.0f km²", aoi_km2))

# Bbox + envelope SQL for context-layer queries.
bb <- sf::st_bbox(aoi_3005)
env_sql <- sprintf(
  "ST_MakeEnvelope(%s, %s, %s, %s, 3005)",
  bb["xmin"] - context_buffer_m, bb["ymin"] - context_buffer_m,
  bb["xmax"] + context_buffer_m, bb["ymax"] + context_buffer_m
)
aoi_wkt <- sf::st_as_text(sf::st_geometry(aoi_3005))
aoi_geom_sql <- sprintf("ST_GeomFromText('%s', 3005)", aoi_wkt)

# ---- 3. Towns -----------------------------------------------------------

message("Fetching town locations ...")
town_list_sql <- paste0("'", gsub("'", "''", town_names), "'",
                        collapse = ", ")
towns <- fresh::frs_db_query(conn, sprintf("
  SELECT geographical_name AS name, feature_type, geom
  FROM whse_basemapping.gns_geographical_names_sp
  WHERE feature_type IN ('City', 'Town', 'Village', 'Village (1)',
                         'Locality', 'Community',
                         'Unincorporated Community',
                         'District Municipality (1)')
    AND geographical_name IN (%s)", town_list_sql))
towns <- towns[!duplicated(towns$name), ]
message(sprintf("  found: %s", paste(towns$name, collapse = ", ")))
missing_towns <- setdiff(town_names, towns$name)
if (length(missing_towns)) {
  message(sprintf("  missing from gns: %s",
                  paste(missing_towns, collapse = ", ")))
}

# ---- 4. Lakes -----------------------------------------------------------

message(sprintf("Fetching lakes > %d ha intersecting AOI bbox ...",
                min_lake_area_ha))
lakes <- fresh::frs_db_query(conn, sprintf("
  SELECT gnis_name_1 AS name, area_ha, geom
  FROM whse_basemapping.fwa_lakes_poly
  WHERE area_ha > %d
    AND ST_Intersects(geom, %s)", min_lake_area_ha, env_sql))
message(sprintf("  %d lakes", nrow(lakes)))

# ---- 5. Rivers ----------------------------------------------------------

message("Fetching named river polygons inside AOI ...")
rivers <- fresh::frs_db_query(conn, sprintf("
  SELECT gnis_name_1 AS name,
         ST_Intersection(geom, %s) AS geom
  FROM whse_basemapping.fwa_rivers_poly
  WHERE gnis_name_1 IS NOT NULL
    AND ST_Intersects(geom, %s)", aoi_geom_sql, aoi_geom_sql))
rivers <- sf::st_zm(rivers, drop = TRUE, what = "ZM")
message(sprintf("  %d named river polygons", nrow(rivers)))

# ---- 6. Streams (order >= min_stream_order, clipped to AOI) ------------

message(sprintf("Fetching stream network (order >= %d, clipped to AOI) ...",
                min_stream_order))
streams <- fresh::frs_db_query(conn, sprintf("
  SELECT gnis_name AS name, stream_order,
         ST_Intersection(geom, %s) AS geom
  FROM whse_basemapping.fwa_stream_networks_sp
  WHERE stream_order >= %d
    AND ST_Intersects(geom, %s)",
  aoi_geom_sql, min_stream_order, aoi_geom_sql))
streams <- sf::st_zm(streams, drop = TRUE, what = "ZM")
message(sprintf("  %d stream segments", nrow(streams)))

# ---- 7. Highways --------------------------------------------------------

message("Fetching highway segments inside AOI + buffer ...")
highways <- fresh::frs_db_query(conn, sprintf("
  SELECT transport_line_type_code AS road_type, geom
  FROM whse_basemapping.transport_line
  WHERE transport_line_type_code IN ('RH1', 'RH2')
    AND ST_Intersects(geom, %s)", env_sql))
highways <- sf::st_zm(highways, drop = TRUE, what = "ZM")
message(sprintf("  %d highway segments", nrow(highways)))

# Disconnect — bcdata calls below don't need the postgres connection.
DBI::dbDisconnect(conn)

# ---- 8. Ecoregions (BCDC) clipped to AOI -------------------------------

message("Fetching ecoregions intersecting AOI from BCDC ...")
ecoregions_bc <- bcdc_query_geodata("d00389e0-66da-4895-bd56-39a0dd64aa78") |>
  bcdata::filter(bcdata::INTERSECTS(aoi_3005)) |>
  collect()
ecoregions <- suppressWarnings(sf::st_intersection(
  sf::st_transform(ecoregions_bc, 3005), aoi_3005
))
ecoregions$area_km2 <- as.numeric(sf::st_area(ecoregions)) / 1e6
ecoregions <- ecoregions[ecoregions$area_km2 > 50, ]
ecoregions <- ecoregions[, c("ECOREGION_CODE", "ECOREGION_NAME",
                              "area_km2")]
names(ecoregions)[1:2] <- c("code", "name")
message(sprintf("  found: %s",
                paste(ecoregions$code, collapse = ", ")))

# ---- 9. Simplify + transform to WGS84 ----------------------------------

message("Simplifying geometries to ", simplify_tol_m, " m tolerance ...")
simplify_layer <- function(x) {
  sf::st_simplify(x, dTolerance = simplify_tol_m,
                  preserveTopology = TRUE)
}
lakes      <- simplify_layer(lakes)
rivers     <- simplify_layer(rivers)
streams    <- simplify_layer(streams)
highways   <- simplify_layer(highways)
wsgs       <- simplify_layer(wsgs)
ecoregions <- simplify_layer(ecoregions)

# AOI gets simplified too but the WSG union has clean shared boundaries,
# so simplification is light.
aoi <- simplify_layer(aoi_3005)

to_4326 <- function(x) sf::st_transform(x, 4326)
aoi        <- to_4326(aoi)
wsgs       <- to_4326(wsgs)
ecoregions <- to_4326(ecoregions)
towns      <- to_4326(towns)
lakes      <- to_4326(lakes)
rivers     <- to_4326(rivers)
streams    <- to_4326(streams)
highways   <- to_4326(highways)

# ---- 10. Write multi-layer gpkg ----------------------------------------

message("Writing ", out_gpkg, " ...")
write_layer(aoi,        "aoi")
write_layer(wsgs,       "wsgs")
write_layer(ecoregions, "ecoregions")
write_layer(towns,      "towns")
write_layer(lakes,      "lakes")
write_layer(rivers,     "rivers")
write_layer(streams,    "streams")
write_layer(highways,   "highways")

message(sprintf("  layers: %s",
                paste(sf::st_layers(out_gpkg)$name, collapse = ", ")))
message(sprintf("  size: %.1f MB",
                file.size(out_gpkg) / 1024^2))

# ============================================================================
# Phase 2 — cd pipeline outputs
# ============================================================================

library(cd)

# Variables where percent change is the meaningful comparison metric
# (pct_normal anomaly type — see cd_variables()). Temperature variables
# get mean_diff via regional_cmp below; these get a second comparison
# in pct_change form for the recent-vs-baseline table.
pct_normal_vars <- c("prcp", "soil_moisture", "swe", "snowfall", "snowmelt")

# ---- 11. STAC catalog + regional pipeline -------------------------------

# GDAL retry env vars — the regen pulls ~1300 COG range requests from
# S3 across AOI + 8 ecoregions, so we want resilience to transient
# network blips even when not in CI.
Sys.setenv(
  GDAL_HTTP_MAX_RETRY = "3",
  GDAL_HTTP_RETRY_DELAY = "2",
  VSI_CACHE = "TRUE"
)

message("Fetching STAC catalog ...")
catalog <- cd::cd_catalog()

message("Regional cd_extract on AOI ...")
regional_ts  <- cd::cd_extract(catalog, aoi)
regional_bl  <- cd::cd_baseline(regional_ts, baseline_years = 1951:1980)
regional_ano <- cd::cd_anomaly(regional_ts, regional_bl)
regional_trn <- cd::cd_trend(regional_ano, trend_start = c(1951, 1981))
# Defaults: window_a = 2015:2025, window_b = 1951:1980, test = "t".
regional_cmp <- cd::cd_compare(regional_ts, method = "mean_diff")
regional_cmp_pct <- cd::cd_compare(
  regional_ts[regional_ts$variable %in% pct_normal_vars, ],
  method = "pct_change"
)

# ---- 12. Per-ecoregion cd pipeline --------------------------------------

# Order ecoregions by area descending so the rds list iterates
# largest-first (same convention Peace uses for stable plotting order).
ecoregions_for_cd <- ecoregions[order(-ecoregions$area_km2), ]

ecoregion_results <- lapply(seq_len(nrow(ecoregions_for_cd)), function(i) {
  er <- ecoregions_for_cd[i, ]
  message(sprintf("Ecoregion %s (%d/%d) cd_extract ...",
                  er$code, i, nrow(ecoregions_for_cd)))
  ts  <- cd::cd_extract(catalog, er)
  bl  <- cd::cd_baseline(ts, baseline_years = 1951:1980)
  ano <- cd::cd_anomaly(ts, bl)
  trn <- cd::cd_trend(ano, trend_start = c(1951, 1981))
  cmp_pct <- cd::cd_compare(
    ts[ts$variable %in% pct_normal_vars, ],
    method = "pct_change"
  )
  list(ts = ts, ano = ano, trn = trn, cmp_pct = cmp_pct)
})
names(ecoregion_results) <- ecoregions_for_cd$code

# Checkpoint: save the cd pipeline outputs before the spatial-tmean
# raster step, so a failure there doesn't cost the ~10-minute cd
# extracts.
out_rds <- file.path(out_dir, "climate_departure.rds")
saveRDS(
  list(
    regional = list(
      ts = regional_ts, bl = regional_bl, ano = regional_ano,
      trn = regional_trn, cmp = regional_cmp, cmp_pct = regional_cmp_pct
    ),
    ecoregion = ecoregion_results,
    ecoregion_codes = ecoregions_for_cd$code
  ),
  out_rds,
  compress = "xz"
)
message(sprintf("Checkpoint: wrote %s (%.0f KB)",
                out_rds, file.size(out_rds) / 1024))

# ---- 13. Spatial tmean departure raster --------------------------------

message("Building spatial tmean departure raster ...")
tmean_row <- catalog[catalog$variable == "tmean" & catalog$period == "annual", ]
r_tmean <- cd::cd_crop(tmean_row$href, aoi)
years <- as.integer(names(r_tmean))
recent_idx     <- which(years >= 2015 & years <= 2025)
historical_idx <- which(years >= 1951 & years <= 1980)
# Use terra::app() rather than base::mean() — mean(SpatRaster) doesn't
# always dispatch to the terra S4 method, depending on package load
# order. app() is unambiguous.
recent_mean     <- terra::app(r_tmean[[recent_idx]],     fun = "mean")
historical_mean <- terra::app(r_tmean[[historical_idx]], fun = "mean")
departure <- recent_mean - historical_mean
departure <- terra::mask(departure, terra::vect(aoi))
names(departure) <- "tmean_departure"

# ---- 14. WSG × ecoregion percentage crosswalk --------------------------

message("Computing WSG × ecoregion percentage crosswalk ...")
sf::sf_use_s2(FALSE)
wsgs_3005       <- sf::st_transform(wsgs, 3005)
ecoregions_3005 <- sf::st_transform(ecoregions, 3005)

overlap <- lapply(seq_len(nrow(wsgs_3005)), function(i) {
  w <- wsgs_3005[i, ]
  inter <- suppressWarnings(sf::st_intersection(ecoregions_3005, w))
  if (nrow(inter) == 0) return(NULL)
  inter$area_km2 <- as.numeric(sf::st_area(inter)) / 1e6
  data.frame(
    wsg_code = w$code,
    wsg_name = w$name,
    ecoregion_code = inter$code,
    area_km2 = inter$area_km2,
    stringsAsFactors = FALSE
  )
})
overlap_df <- do.call(rbind, overlap)

ecoregion_codes_sorted <- ecoregions_for_cd$code
wide <- overlap_df |>
  dplyr::group_by(wsg_code, wsg_name, ecoregion_code) |>
  dplyr::summarise(area_km2 = sum(area_km2), .groups = "drop") |>
  tidyr::pivot_wider(
    id_cols = c(wsg_code, wsg_name),
    names_from = ecoregion_code,
    values_from = area_km2,
    values_fill = 0
  )
for (ec in ecoregion_codes_sorted) {
  if (!ec %in% names(wide)) wide[[ec]] <- 0
}
wide <- wide[, c("wsg_code", "wsg_name", ecoregion_codes_sorted)]

wide$total_km2 <- rowSums(wide[, ecoregion_codes_sorted])
pct_cols <- paste0(ecoregion_codes_sorted, "_pct")
for (i in seq_along(ecoregion_codes_sorted)) {
  wide[[pct_cols[i]]] <- round(100 * wide[[ecoregion_codes_sorted[i]]] / wide$total_km2, 1)
}

wsg_xref <- wide[, c("wsg_code", "wsg_name", "total_km2", pct_cols)]
wsg_xref$total_km2 <- round(wsg_xref$total_km2, 0)
wsg_xref <- wsg_xref[order(wsg_xref$wsg_code), ]
sf::sf_use_s2(TRUE)

# ---- 15. Write spatial + crosswalk outputs -----------------------------

# rds was written at the checkpoint above (section 12).

out_tif <- file.path(out_dir, "climate_departure_tmean.tif")
terra::writeRaster(
  departure, out_tif,
  overwrite = TRUE,
  gdal = c("COMPRESS=DEFLATE", "TILED=YES")
)
message(sprintf("Wrote %s (%.0f KB)",
                out_tif, file.size(out_tif) / 1024))

out_csv <- file.path(out_dir, "climate_departure_wsg_ecoregion.csv")
write.csv(wsg_xref, out_csv, row.names = FALSE)
message(sprintf("Wrote %s (%.0f KB)",
                out_csv, file.size(out_csv) / 1024))

# ---- 16. Snapshot manifest ---------------------------------------------

manifest <- file.path("data",
                     "climate_departure_inputs_snapshot_manifest.txt")
files <- c(out_gpkg, out_rds, out_tif, out_csv)
shas <- vapply(files, function(f) unname(tools::md5sum(f)), character(1))
stamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
cd_ver <- as.character(utils::packageVersion("cd"))
lines <- c(
  sprintf("# Climate-departure snapshot generated %s", stamp),
  sprintf("# cd version: %s", cd_ver),
  sprintf("# WSG codes: %s", paste(wsg_codes, collapse = ",")),
  sprintf("# Ecoregions: %s", paste(ecoregions_for_cd$code, collapse = ",")),
  "",
  paste0(format(basename(files), width = 38), "  ", shas)
)
writeLines(lines, manifest)
message(sprintf("Wrote %s", manifest))

message("\nDone.")
