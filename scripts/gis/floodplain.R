# Regenerate floodplain data for the WSG appendix.
#
# Adapted from flooded/data-raw/wsg_vignette_data.R. NOT run during
# book rendering — only to regenerate cached data in data/gis/.
#
# Generic — runs for any BC watershed group. Set `wsg` and `species_view`
# below.
#
# Generates (under data/gis/, namespaced by WSG code):
#   <wsg>.gpkg              multi-layer GeoPackage with the sf layers:
#                             aoi, streams, waterbodies, <sp>_ff<nn>,
#                             railways, roads, reserves, parks,
#                             named_streams, municipalities
#   <wsg>_dem.tif           MRDEM-30 clip cropped to streams + 2 km buffer
#   <wsg>_meta.rds          provenance: bcfishpass model stamp, plus the
#                           floodplain source URL and its md5
#
# Bundling the sf layers into a single multi-layer gpkg matches how QGIS
# expects a per-WSG project bundle and keeps the cache to three files per
# WSG. Rasters stay separate (terra writes COG/GeoTIFF, not into gpkg).
#
# The floodplain is NOT delineated here. It is already published to the
# stac-floodplains-bc collection (https://images.a11s.one), so section 6
# downloads it rather than re-running flooded::fl_valley_confine(). The
# layer keeps the name it carries on the catalogue (`<sp>_ff<nn>`, e.g.
# `co_ff04`) so the cached copy is traceable back to its STAC item without
# a lookup table. Re-run the delineation only to publish a group the
# catalogue does not yet carry.
#
# Streams come from `bcfishpass.streams_co_vw` (coho accessible
# network — every row has `access IN (1, 2)` by construction). Filtering
# to `access IN (1, 2) AND stream_order >= min_order` plus the
# `watershed_group_code` filter gives "best accessible habitat order 3+"
# without needing a working-table classification pipeline.
#
# Species matters for more than the streams layer: the published
# floodplain was delineated on a specific species-accessible network, so
# `species_view` must match the species in the STAC item id or the
# "streams within floodplain" metric measures two different networks
# against each other.
#
# Waterbodies (lakes + wetlands) are picked up via `waterbody_key`
# linkage from the filtered stream list — only those physically anchored
# to the network are included. They are carried for the appendix maps.
#
# To swap species: change `species_view` to e.g. `"streams_ch_vw"` for
# chinook or `"streams_st_vw"` for steelhead — same column shape
# (`access`, `spawning`, `rearing`) — and confirm the catalogue carries a
# matching item.
#
# Prerequisites:
#   - SSH tunnel to the bcfishpass PostgreSQL up; PG_*_SHARE env vars set
#     (defaults of fresh::frs_db_conn()). This is bcfishpass, NOT the
#     fwapg database — the whse_* schemas queried below live in the same
#     bcfishpass database.
#   - Outbound HTTPS to s3.ca-central-1.amazonaws.com for MRDEM /vsicurl/
#     and to stac-floodplains-bc.s3.us-west-2.amazonaws.com for the
#     published floodplain
#   - flooded package installed (pak::pak("NewGraphEnvironment/flooded"))

# ---- params -------------------------------------------------------------

wsg <- "BULK"                       # any 4-letter BC watershed group code
species_view <- "streams_co_vw"     # bcfishpass species-accessible view
min_order <- 3                      # minimum stream order to keep

# These streams are NOT the network the published floodplain was delineated
# on, and cannot be. That network was built by `link` orchestrating `fresh`
# over a local fwapg database (floodplains/scripts/floodplain_lcc/
# 01_network_extract.R); this is bcfishpass, a different pipeline. The two are
# aligned by intent, not construction — link only reached parity on access
# segmentation at 0.44.0, and 0.43.x over-credited reaches above gradient>15%
# barriers. So "streams within floodplain" is a close estimate, not an exact
# intersection, and the appendix says so.
#
# The delineation's own network is not published to the catalogue: the item
# ships only polygon layers, no line geometry. Publishing it, and the network
# provenance, is NewGraphEnvironment/stac_floodplains_bc#17 (upstream of that,
# NewGraphEnvironment/link#127). Until then this cannot be made exact here.
#
# Keep `species_view` and `min_order` matching the published scenario anyway,
# so the estimate stays as close as it can be. The model's parameters are in
# the floodplains driver repo at config/<wsg>/flood_scenarios.csv — for
# BULK / co_ff04 that is species co, min_order 3, flood_factor 4. Species and
# flood factor are self-enforcing, since both are composed into the STAC item
# id below and a mismatch 404s on download. **min_order is not** — it appears
# in neither the item id nor the item properties, so changing it here leaves
# the download succeeding and the reported lengths quietly further off.
flood_factor <- 4                   # selects the published ff<nn> scenario

# Vertex thinning for the context layers only (railways, roads, reserves,
# parks, named_streams, municipalities) — everything routed through
# fetch_layer() below. These are drawn but never measured. 10 m sits well
# under the ~22 m/pixel of the appendix detail map and ~91 m/pixel of the
# watershed-wide map, so it is invisible at render scale while cutting the
# roads layer by about a third. Deliberately NOT applied to aoi, streams,
# waterbodies or the floodplain: those feed the reported areas and lengths,
# and thinning them would silently move the numbers.
simplify_tol_m <- 10

# stac-floodplains-bc asset base. Item ids are <wsg>_<species>_ff<nn>;
# `scenario` is not exposed as a queryable STAC property
# (NewGraphEnvironment/stac_floodplains_bc#9), so it is composed here.
stac_base <- "https://stac-floodplains-bc.s3.us-west-2.amazonaws.com"

# ---- env ----------------------------------------------------------------

Sys.setenv(
  GDAL_HTTP_MAX_RETRY = "3",
  GDAL_HTTP_RETRY_DELAY = "2",
  VSI_CACHE = "TRUE"
)

library(flooded)
library(fresh)
library(sf)
library(terra)

out_dir <- file.path("data", "gis")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

stub <- tolower(wsg)
out <- function(name) file.path(out_dir, paste0(stub, "_", name))   # rasters

# Single multi-layer GeoPackage for all sf layers. Wipe at the start of
# each run so we never carry stale layers across re-runs.
gpkg <- file.path(out_dir, paste0(stub, ".gpkg"))
if (file.exists(gpkg)) file.remove(gpkg)

write_layer <- function(x, layer) {
  sf::st_write(x, gpkg, layer = layer, delete_layer = TRUE,
               append = TRUE, quiet = TRUE)
}

# ---- 1. WSG boundary ----------------------------------------------------

message("Fetching ", wsg, " watershed group boundary ...")
conn <- fresh::frs_db_conn()
on.exit(try(DBI::dbDisconnect(conn), silent = TRUE), add = TRUE)

aoi <- sf::st_read(
  conn,
  query = sprintf(
    "SELECT watershed_group_code, watershed_group_name, area_ha, geom
     FROM whse_basemapping.fwa_watershed_groups_poly
     WHERE watershed_group_code = '%s'",
    wsg
  ),
  quiet = TRUE
)
write_layer(aoi, "aoi")
message(sprintf("  area: %.0f km²", aoi$area_ha[1] / 100))

# ---- 2. Streams: accessible, order 3+ -----------------------------------

message(sprintf("Fetching %s accessible order %d+ streams from bcfishpass.%s ...",
                wsg, min_order, species_view))
streams <- sf::st_read(
  conn,
  query = sprintf("
    SELECT segmented_stream_id, linear_feature_id, blue_line_key,
           waterbody_key, downstream_route_measure, upstream_area_ha,
           map_upstream, channel_width, gnis_name, stream_order,
           gradient, mapping_code, access, spawning, rearing,
           dam_dnstr_ind, watershed_group_code, geom
    FROM bcfishpass.%s
    WHERE watershed_group_code = '%s'
      AND access IN (1, 2)
      AND stream_order >= %d", species_view, wsg, min_order),
  quiet = TRUE
)
streams <- sf::st_zm(streams)
write_layer(streams, "streams")
message(sprintf("  %d segments (assessed: %d, modelled: %d)",
                nrow(streams),
                sum(streams$access == 1L, na.rm = TRUE),
                sum(streams$access == 2L, na.rm = TRUE)))

# ---- 3. Waterbodies on the accessible network ---------------------------

wb_keys <- unique(streams$waterbody_key)
wb_keys <- wb_keys[!is.na(wb_keys) & wb_keys != 0]
message(sprintf("Fetching waterbodies on %d distinct waterbody_keys ...",
                length(wb_keys)))

if (length(wb_keys) > 0L) {
  keys_sql <- paste(wb_keys, collapse = ", ")
  lakes <- sf::st_read(
    conn,
    query = sprintf(
      "SELECT waterbody_key, geom FROM whse_basemapping.fwa_lakes_poly
       WHERE waterbody_key IN (%s)", keys_sql),
    quiet = TRUE
  )
  wetlands <- sf::st_read(
    conn,
    query = sprintf(
      "SELECT waterbody_key, geom FROM whse_basemapping.fwa_wetlands_poly
       WHERE waterbody_key IN (%s)", keys_sql),
    quiet = TRUE
  )
  lakes_min <- sf::st_sf(waterbody_type = rep("L", nrow(lakes)),
                         geom = sf::st_geometry(lakes))
  wetlands_min <- sf::st_sf(waterbody_type = rep("W", nrow(wetlands)),
                            geom = sf::st_geometry(wetlands))
  waterbodies <- rbind(lakes_min, wetlands_min)
  # Drop any non-polygon geoms (degenerate features in source data
  # occasionally come through as MULTILINESTRING and break terra::rasterize).
  keep <- sf::st_geometry_type(waterbodies) %in% c("POLYGON", "MULTIPOLYGON")
  if (any(!keep)) {
    message(sprintf("  dropping %d non-polygon waterbody geom(s)", sum(!keep)))
    waterbodies <- waterbodies[keep, ]
  }
  message(sprintf("  lakes: %d, wetlands: %d, total: %d",
                  nrow(lakes), nrow(wetlands), nrow(waterbodies)))
} else {
  waterbodies <- sf::st_sf(waterbody_type = character(0),
                           geom = sf::st_sfc(crs = sf::st_crs(streams)))
  message("  no waterbodies on streams")
}
waterbodies <- sf::st_zm(waterbodies)
write_layer(waterbodies, "waterbodies")

# ---- 4. Context layers (railways, roads, reserves, parks) --------------

# Spatial intersect with the WSG boundary. Each query becomes a layer in
# the multi-layer gpkg. Geometry-only attributes plus a name field where
# the source carries one.

fetch_layer <- function(query_sql, layer_name, label) {
  layer <- try(sf::st_read(conn, query = query_sql, quiet = TRUE),
               silent = TRUE)
  if (inherits(layer, "try-error") || nrow(layer) == 0L) {
    message(sprintf("  %s: 0 features (skipping)", label))
    return(invisible(NULL))
  }
  layer <- sf::st_zm(layer)
  if (simplify_tol_m > 0) {
    layer <- suppressWarnings(
      sf::st_simplify(layer, dTolerance = simplify_tol_m,
                      preserveTopology = TRUE)
    )
  }
  write_layer(layer, layer_name)
  message(sprintf("  %s: %d features", label, nrow(layer)))
}

aoi_wkt <- sf::st_as_text(sf::st_geometry(aoi))
intersect_clause <- function(geom_col = "geom") {
  sprintf("ST_Intersects(%s, ST_GeomFromText('%s', 3005))", geom_col, aoi_wkt)
}

message("Fetching context layers (railways, roads, reserves, parks) ...")

fetch_layer(
  sprintf("SELECT track_name, geom FROM whse_basemapping.gba_railway_tracks_sp
           WHERE %s", intersect_clause()),
  "railways", "railways")

fetch_layer(
  sprintf("SELECT transport_line_id, structured_name_1, transport_line_type_code,
                  highway_route_1, geom
           FROM whse_basemapping.transport_line
           WHERE %s", intersect_clause()),
  "roads", "roads")

fetch_layer(
  sprintf("SELECT english_name, band_name, geom
           FROM whse_admin_boundaries.adm_indian_reserves_bands_sp
           WHERE %s", intersect_clause()),
  "reserves", "First Nations reserves")

fetch_layer(
  sprintf("SELECT protected_lands_name, protected_lands_designation, geom
           FROM whse_tantalis.ta_park_ecores_pa_svw
           WHERE %s", intersect_clause()),
  "parks", "parks / protected")

# Named streams come pre-filtered by watershed_group_code — no spatial join.
fetch_layer(
  sprintf("SELECT gnis_name, blue_line_key, stream_order, geom
           FROM whse_basemapping.fwa_named_streams
           WHERE watershed_group_code = '%s'", wsg),
  "named_streams", "named streams")

fetch_layer(
  sprintf("SELECT admin_area_name, geom
           FROM whse_legal_admin_boundaries.abms_municipalities_sp
           WHERE %s", intersect_clause()),
  "municipalities", "municipalities")

# Cache the bcfishpass model version + date so the vignette can stamp
# data provenance without needing a DB connection at render time.
# Written to disk at the end of section 6, once the floodplain source and
# checksum are known, so provenance for both inputs lands in one file.
message("Caching bcfishpass version stamp ...")
bp_log <- DBI::dbGetQuery(conn, "
  SELECT model_version, date_completed
  FROM bcfishpass.log
  WHERE model_type = 'LINEAR'
  ORDER BY date_completed DESC LIMIT 1")

DBI::dbDisconnect(conn)

# ---- 5. MRDEM-30 clip via fl_dem_aoi() ----------------------------------

message("Fetching MRDEM-30 clip (heaviest network step) ...")
dem <- fl_dem_aoi(streams, buffer = 2000)
terra::writeRaster(
  terra::as.int(dem), out("dem.tif"),
  overwrite = TRUE,
  datatype = "INT2S",
  gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES")
)
message(sprintf("  %d x %d cells (%.1f Mcells)",
                ncol(dem), nrow(dem),
                ncol(dem) * nrow(dem) / 1e6))

# ---- 6. Floodplain from stac-floodplains-bc -----------------------------

# Already delineated and published, so fetch rather than re-run the VCA.
# Both the item id and the layer name are the catalogue's, not ours.

species  <- sub("^streams_(.+)_vw$", "\\1", species_view)
scenario <- sprintf("ff%02d", flood_factor)
item_id  <- paste(stub, species, scenario, sep = "_")
fp_layer <- paste(species, scenario, sep = "_")
fp_url   <- sprintf("%s/%s/floodplain.gpkg", stac_base, item_id)

message("Fetching published floodplain: ", fp_url, " ...")
fp_tmp <- tempfile(fileext = ".gpkg")
utils::download.file(fp_url, fp_tmp, mode = "wb", quiet = TRUE)
fp_md5 <- unname(tools::md5sum(fp_tmp))

# The asset carries ff02/ff04/ff06; we keep only the requested scenario.
if (!fp_layer %in% sf::st_layers(fp_tmp)$name) {
  stop(sprintf("Layer '%s' absent from %s — layers present: %s",
               fp_layer, fp_url,
               paste(sf::st_layers(fp_tmp)$name, collapse = ", ")))
}
floodplain <- sf::st_read(fp_tmp, layer = fp_layer, quiet = TRUE)
write_layer(floodplain, fp_layer)
unlink(fp_tmp)

message(sprintf("  %s: %.2f km²", fp_layer,
                as.numeric(sum(sf::st_area(floodplain))) / 1e6))
message("  md5: ", fp_md5)

saveRDS(
  list(bcfishpass_version = bp_log$model_version,
       bcfishpass_date    = format(bp_log$date_completed, "%Y-%m-%d"),
       floodplain_item    = item_id,
       floodplain_layer   = fp_layer,
       floodplain_url     = fp_url,
       floodplain_md5     = fp_md5),
  file.path(out_dir, paste0(stub, "_meta.rds"))
)

# ---- 7. Report cache size -----------------------------------------------

cache_files <- c(gpkg, list.files(out_dir,
                                  pattern = paste0("^", stub, "_.*\\.(tif|rds)$"),
                                  full.names = TRUE))
cache_sizes <- file.info(cache_files)$size
total_mb <- sum(cache_sizes) / 1024^2
message(sprintf("Cache for %s total: %.1f MB across %d files",
                wsg, total_mb, length(cache_files)))
for (i in seq_along(cache_files)) {
  message(sprintf("  %-40s %.2f MB", basename(cache_files[i]),
                  cache_sizes[i] / 1024^2))
}
message(sprintf("  gpkg layers: %s",
                paste(sf::st_layers(gpkg)$name, collapse = ", ")))
