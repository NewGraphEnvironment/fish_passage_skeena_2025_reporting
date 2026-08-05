# Static habitat confirmation site maps ------------------------------------
#
# Builds the per-site map that appears in each `0800-appendix-*.Rmd`. Replaces
# the JPEGs that were exported by hand from QGIS print layouts - two of the
# 2025 sites never got one, so the report shipped "(Figure ??)".
#
# Sourced from `index.Rmd` after `scripts/02_reporting/0120-read-sqlite.R`,
# which populates the globals this reads: `wshds`, `habitat_confirmation_tracks`,
# `pscis_assessment_svw`, `form_pscis`.
#
# Everything here works offline from `data/bcfishpass.sqlite` plus the caches in
# `data/gis/`. The pull that builds those caches is `0410-map-site-prep.R` and is
# never sourced by the book.
#
# Two gotchas worth knowing before editing:
#
# 1. The three sqlite spatial tables carry THREE different CRSs and all of them
#    report `st_crs()$epsg` as NA, because readwritesqlite round-trips the WKT
#    without an authority code. `wshds` and `habitat_confirmation_tracks` are
#    WGS84 lon/lat; `pscis_assessment_svw` is BC Albers. Assigning a CRS rather
#    than transforming silently relocates whichever table you guessed wrong -
#    hence `lfpr_crs_bc()` below transforms and then asserts.
#
# 2. Survey track labels do not all match real crossing ids. Three of six 2025
#    sites are filed under ids that exist in no form or PSCIS table, Stony among
#    them. `data/gis/xref_tracks_site.csv` carries the mapping and the distance
#    evidence for each row.

#' Registry: gq main merged with our own fish-passage layers
#'
#' Layers we reuse across reports that the shared registry has no entry for -
#' survey tracks, the assessed-site marker, eDNA samples, the upstream
#' watershed, muted inset context styles, and a neutral fallback for class
#' values the registry does not carry. Kept local while the set is still
#' settling; promote to gq once it stops changing.
lfpr_reg <- function(path = "data/gis/gq_reg_fish_passage.csv") {
  if (!fs::file_exists(path)) return(gq::gq_reg_main())
  gq::gq_reg_merge(gq::gq_reg_main(), gq::gq_reg_custom(path))
}

#' Label rules for map layers
#'
#' Kept in a CSV beside the style registry rather than inside it: a row in the
#' style registry REPLACES the matching gq entry, which would drop the
#' classification on layers like crossings_pscis_assessment. These are hints to
#' the consumer - which field to label, and which features are worth labelling -
#' the same shape proposed upstream in NewGraphEnvironment/gq#7.
#'
#' label_scope values:
#'   watershed           only where the feature falls inside the upstream watershed
#'   watershed_or_stream inside the watershed, or on the subject stream
#'   all                 every feature in frame
lfpr_label_rules <- function(path = "data/gis/xref_map_labels.csv") {
  if (!fs::file_exists(path)) return(NULL)
  readr::read_csv(path, show_col_types = FALSE)
}

lfpr_label_rule <- function(rules, key) {
  if (is.null(rules)) return(NULL)
  r <- rules[rules$layer_key == key, ]
  if (nrow(r) == 0) NULL else as.list(r[1, ])
}

#' Apply a label rule's scope, returning the features that should carry a label
lfpr_label_scope <- function(x, rule, wshd, stream_buf) {
  if (is.null(x) || nrow(x) == 0 || is.null(rule)) return(NULL)
  keep <- switch(
    rule$label_scope,
    watershed = if (nrow(wshd) > 0) lengths(sf::st_intersects(x, sf::st_union(wshd))) > 0 else rep(FALSE, nrow(x)),
    watershed_or_stream = {
      a <- if (nrow(wshd) > 0) lengths(sf::st_intersects(x, sf::st_union(wshd))) > 0 else rep(FALSE, nrow(x))
      b <- if (!is.null(stream_buf)) lengths(sf::st_intersects(x, stream_buf)) > 0 else rep(FALSE, nrow(x))
      a | b
    },
    all = rep(TRUE, nrow(x)),
    rep(FALSE, nrow(x))
  )
  out <- x[keep & !is.na(x[[rule$label_field]]), ]
  if (nrow(out) == 0) return(NULL)
  if (!is.na(rule$label_max) && nrow(out) > rule$label_max) {
    message("  ", nrow(out), " ", rule$layer_key, " labels in scope - suppressed above ", rule$label_max)
    return(NULL)
  }
  out$lfpr_lab <- as.character(out[[rule$label_field]])
  out
}

# small accessors so the call sites read as styles, not hex
lfpr_sty <- function(reg, key, what = c("stroke", "fill", "mark", "label")) {
  what <- match.arg(what)
  gq::gq_style(reg, key)[[what]]
}

# EPSG:3005 BC Albers. Everything is mapped in it - no tiles at render time
# means no Web Mercator, so the bbox aspect maths needs no cos(lat) correction.
lfpr_crs_map <- 3005

# Generous envelope for BC in BC Albers, used only to catch a CRS that has been
# assigned rather than transformed. A lon/lat table wrongly stamped as 3005
# lands near (0, 0) and fails this immediately.
lfpr_bc_bounds <- c(xmin = 100000, xmax = 2000000, ymin = 200000, ymax = 1800000)

#' Transform to BC Albers and assert the result is actually in BC
#'
#' @param x sf object with a defined CRS (proj4 is enough - an authority code is
#'   not required, and none of the sqlite tables have one).
#' @param what character label used in the error message.
lfpr_crs_bc <- function(x, what = deparse(substitute(x))) {
  if (is.na(sf::st_crs(x))) {
    stop("`", what, "` has no CRS at all - cannot transform it safely. ",
         "Do not assign one without checking the coordinate ranges first.",
         call. = FALSE)
  }
  out <- sf::st_transform(x, lfpr_crs_map)
  bb <- sf::st_bbox(out)
  ok <- bb[["xmin"]] > lfpr_bc_bounds[["xmin"]] &&
        bb[["xmax"]] < lfpr_bc_bounds[["xmax"]] &&
        bb[["ymin"]] > lfpr_bc_bounds[["ymin"]] &&
        bb[["ymax"]] < lfpr_bc_bounds[["ymax"]]
  if (!ok) {
    stop("`", what, "` is not in British Columbia after transforming to EPSG:",
         lfpr_crs_map, ". bbox was [", paste(round(bb), collapse = ", "), "]. ",
         "This usually means the source CRS was assigned rather than transformed.",
         call. = FALSE)
  }
  out
}

#' Survey tracks for a site, with the label defects corrected
#'
#' @param site one or more `stream_crossing_id`.
#' @param tracks the `habitat_confirmation_tracks` table.
#' @param path_xref hand-curated label -> crossing id mapping.
lfpr_tracks_site <- function(site,
                             tracks = habitat_confirmation_tracks,
                             path_xref = "data/gis/xref_tracks_site.csv") {
  xref <- readr::read_csv(path_xref, show_col_types = FALSE) |>
    dplyr::mutate(stream_crossing_id = as.character(stream_crossing_id))

  missing <- setdiff(tracks$name_new, xref$name_new)
  if (length(missing)) {
    stop("survey tracks are missing from ", path_xref, ": ",
         paste(missing, collapse = ", "),
         ". Add a row for each, with the nearest-crossing distance in `note`.",
         call. = FALSE)
  }

  tracks |>
    dplyr::left_join(xref, by = "name_new") |>
    dplyr::filter(stream_crossing_id %in% as.character(site)) |>
    lfpr_crs_bc(what = "habitat_confirmation_tracks")
}

#' Pad a bbox to a target canvas aspect ratio
#'
#' Ports the aspect match from `gq/vignettes/gq-tmap-composition.Rmd:110-140`.
#' That version corrects for latitude because it works in lon/lat; in a
#' projected CRS the ratio is just dx/dy, so the correction is dropped.
#'
#' @param x sf object or bbox, already in `lfpr_crs_map`.
#' @param asp target width/height, i.e. `fig.width / fig.height`.
#' @param margin fraction of each dimension added so features never touch the frame.
lfpr_bbox_asp <- function(x, asp, margin = 0.02) {
  bb <- if (inherits(x, "bbox")) x else sf::st_bbox(x)
  dx <- bb[["xmax"]] - bb[["xmin"]]
  dy <- bb[["ymax"]] - bb[["ymin"]]

  if (dx / dy > asp) {
    pad <- ((dx / asp) - dy) / 2
    bb[["ymin"]] <- bb[["ymin"]] - pad
    bb[["ymax"]] <- bb[["ymax"]] + pad
  } else {
    pad <- ((dy * asp) - dx) / 2
    bb[["xmin"]] <- bb[["xmin"]] - pad
    bb[["xmax"]] <- bb[["xmax"]] + pad
  }

  mx <- (bb[["xmax"]] - bb[["xmin"]]) * margin
  my <- (bb[["ymax"]] - bb[["ymin"]]) * margin
  bb[["xmin"]] <- bb[["xmin"]] - mx
  bb[["xmax"]] <- bb[["xmax"]] + mx
  bb[["ymin"]] <- bb[["ymin"]] - my
  bb[["ymax"]] <- bb[["ymax"]] + my
  bb
}

#' Gather every local layer a site map needs, in BC Albers
#'
#' @param site one or more `stream_crossing_id`. Tabor passes two.
lfpr_read_site_local <- function(site) {
  site_chr <- as.character(site)

  # Upstream watershed. 196085 and 203582 share an identical polygon, so dedupe
  # on geometry rather than id or it draws twice at doubled stroke opacity.
  wshd <- wshds |>
    dplyr::mutate(stream_crossing_id = as.character(stream_crossing_id)) |>
    dplyr::filter(stream_crossing_id %in% site_chr) |>
    lfpr_crs_bc(what = "wshds")
  wshd <- wshd[!duplicated(sf::st_as_text(sf::st_geometry(wshd))), ]

  tracks <- lfpr_tracks_site(site)

  crossings <- pscis_assessment_svw |>
    dplyr::mutate(stream_crossing_id = as.character(stream_crossing_id)) |>
    lfpr_crs_bc(what = "pscis_assessment_svw")

  subject <- crossings |> dplyr::filter(stream_crossing_id %in% site_chr)

  list(wshd = wshd, tracks = tracks, crossings = crossings, subject = subject)
}

#' Read the committed context cache for a map unit
#'
#' Written by `0410-map-site-prep.R`. Absent caches degrade to a local-data-only
#' map rather than failing - a fresh clone that has not run prep still builds.
lfpr_read_site_cache <- function(site, dir_gis = "data/gis") {
  id <- as.character(min(site))
  path_gpkg <- fs::path(dir_gis, paste0("map_", id, ".gpkg"))
  if (!fs::file_exists(path_gpkg)) return(list())

  have <- sf::st_layers(path_gpkg)$name
  # st_zm() because the FWA network carries Z/M dimensions and GEOS refuses
  # XYM/XYZM - st_filter() against the bbox fails outright without it.
  out <- lapply(stats::setNames(have, have), function(l)
    sf::st_zm(sf::st_read(path_gpkg, layer = l, quiet = TRUE), drop = TRUE, what = "ZM"))
  out$dem     <- lfpr_rast_or_null(fs::path(dir_gis, paste0("map_", id, "_dem.tif")))
  out$basemap <- lfpr_rast_or_null(fs::path(dir_gis, paste0("map_", id, "_basemap.tif")))
  path_meta   <- fs::path(dir_gis, paste0("map_", id, "_meta.rds"))
  out$meta    <- if (fs::file_exists(path_meta)) readRDS(path_meta) else NULL
  out
}

lfpr_rast_or_null <- function(path) {
  if (!fs::file_exists(path)) return(NULL)
  terra::rast(path)
}

#' Positron basemap multiplied by a hillshade derived from our own DEM
#'
#' Esri's shaded relief service caps at zoom 13, which is too coarse for a site
#' map, so the relief comes from the MRDEM-30 clip rather than a tile service.
#' The multiply-with-gamma is the same operator as
#' `gq/vignettes/gq-tmap-composition.Rmd:148-150`; only the relief source differs.
lfpr_basemap_blend <- function(basemap, dem, bb, weight = 0.35) {
  if (is.null(basemap)) return(NULL)
  bm <- terra::crop(basemap, terra::ext(bb[["xmin"]], bb[["xmax"]], bb[["ymin"]], bb[["ymax"]]))
  if (terra::ncell(bm) == 0) return(NULL)
  if (is.null(dem)) return(bm)

  # Soften the 30 m stair-steps before deriving slope - at ~1:15 000 a raw
  # MRDEM cell is several screen pixels across and the hillshade reads blocky.
  d <- terra::disagg(terra::crop(dem, terra::ext(bm)), fact = 3, method = "bilinear")
  hs <- terra::shade(terra::terrain(d, "slope", unit = "radians"),
                     terra::terrain(d, "aspect", unit = "radians"),
                     angle = 45, direction = 315)
  hs <- terra::resample(hs, bm, method = "bilinear")
  # Pull the hillshade toward 1 before multiplying. At full strength the relief
  # swamps the basemap and the map reads as a grayscale DEM with lines on it -
  # the point is terrain as a backdrop, not terrain as the subject.
  hs <- 1 - weight * (1 - terra::clamp(hs, 0, 1))
  terra::clamp((bm / 255) * hs * 255, lower = 0, upper = 255)
}

# Decode a bcfishpass mapping_code into readable text.
#
# Ported from fish_passage_peace_2025_reporting/0760-appendix-habitat-connectivity.Rmd:158-171.
# The gq registry labels the ACCESS habitat token "No known barriers", which
# collides with the second token's own status wording and renders as
# "No known barriers; known barrier". Decoded here so the legend reads correctly;
# fix-at-source belongs in the gq registry.
lfpr_tok_use    <- c(SPAWN = "Spawning", REAR = "Rearing", ACCESS = "Accessible")
lfpr_tok_status <- c(NONE = "no known barriers", MODELLED = "potential barrier",
                     ASSESSED = "known barrier", DAM = "dam", REMEDIATED = "remediated")

lfpr_label_mapping_code <- function(tokens) {
  parts <- strsplit(tokens, ";", fixed = TRUE)
  vapply(parts, function(p) {
    use <- lfpr_tok_use[p[1]]
    st  <- if (length(p) > 1) lfpr_tok_status[p[2]] else NA
    int <- if (any(p == "INTERMITTENT")) " (intermittent)" else ""
    paste0(ifelse(is.na(use), p[1], use),
           ifelse(is.na(st), "", paste0("; ", st)), int)
  }, character(1))
}

#' North arrow built on the New Graph mark
#'
#' `tm_compass()` cannot take a custom image - it hard-aborts on any type
#' outside arrow/4star/8star/radar/rose - so the arrow is a grid grob placed
#' with `tm_inset()`, which does accept one.
#'
#' The NGE mark cannot carry direction on its own: it is two mirrored chevrons
#' with 2-fold rotational symmetry (profile correlation against its own reverse
#' is 0.992 vertically). So it becomes the hub, with a spear above it and the N
#' on top.
#'
#' @param angle degrees to rotate the whole assembly. Pass the negative grid
#'   convergence to point at true rather than grid north - in BC Albers that is
#'   about `(lon + 126) * 0.809`, so roughly -3 degrees near Prince George.
lfpr_grob_north <- function(logo = system.file("logo", "nge_icon_200.png", package = "gq"),
                            col = "#2c3e50",
                            angle = 0,
                            label = "N") {
  stopifnot(nzchar(logo), file.exists(logo))
  img <- png::readPNG(logo)

  grid::gTree(
    children = grid::gList(
      grid::polygonGrob(
        x  = grid::unit(c(0.50, 0.30, 0.50, 0.70), "npc"),
        y  = grid::unit(c(0.62, 0.10, 0.24, 0.10), "npc"),
        gp = grid::gpar(fill = col, col = NA)
      ),
      grid::rasterGrob(
        img,
        width  = grid::unit(0.42, "npc"),
        height = grid::unit(0.42, "npc"),
        y      = grid::unit(0.64, "npc")
      ),
      grid::textGrob(
        label,
        y  = grid::unit(0.94, "npc"),
        gp = grid::gpar(fontsize = 9, fontface = "bold", col = col)
      )
    ),
    vp = grid::viewport(angle = angle)
  )
}

#' Grid convergence in BC Albers, degrees
#'
#' BC Albers grid north is not true north away from the 126 W central meridian.
lfpr_convergence <- function(x) {
  ll <- sf::st_coordinates(sf::st_centroid(sf::st_as_sfc(sf::st_bbox(
    sf::st_transform(x, 4326)))))
  (ll[1, "X"] + 126) * 0.809
}

#' Keymap: the ground actually surveyed
#'
#' The main map frames the whole upstream watershed, which is the context a
#' reader needs to see how the crossings and the habitat model interact. At that
#' scale the survey extent is a fraction of a percent of the frame, so the
#' detail moves here - the crossing, the reach walked upstream and downstream,
#' and the modelled habitat immediately around it.
lfpr_keymap_survey <- function(tracks, subject, habitat, cls, ctx = NULL,
                               edna = NULL, buffer = 550,
                               crossings = NULL, xing_cls = NULL, reg = NULL,
                               rules = NULL) {
  bb <- lfpr_bbox_asp(sf::st_bbox(sf::st_buffer(
    c(sf::st_as_sfc(sf::st_bbox(tracks)), sf::st_as_sfc(sf::st_bbox(subject))), buffer)), asp = 1)
  bb_sfc <- sf::st_as_sfc(bb)
  cut <- function(x) {
    if (is.null(x) || nrow(x) == 0) return(NULL)
    out <- sf::st_filter(x, bb_sfc)
    if (nrow(out) == 0) NULL else out
  }

  k <- tmap::tm_shape(bb_sfc, bbox = bb, is.main = TRUE) +
    tmap::tm_borders(lwd = 0, col = NA)

  # Context - without waterbodies and roads the surveyed reach floats on white
  # and the reader cannot place it against anything.
  rd <- NULL
  if (!is.null(ctx)) {
    for (nm in c("rivers", "lakes")) {
      x <- cut(ctx[[nm]])
      if (!is.null(x)) k <- k + tmap::tm_shape(x) +
        tmap::tm_polygons(fill = "#c9e2f0", col = "#7fa8c4", lwd = 0.4)
    }
    st <- cut(ctx$streams)
    if (!is.null(st)) k <- k + tmap::tm_shape(st) + tmap::tm_lines(col = "#a9d3ec", lwd = 0.7)
    rd <- cut(ctx$roads)
    if (!is.null(rd)) k <- k + tmap::tm_shape(rd) + tmap::tm_lines(col = "#5a5a5a", lwd = 0.9)
    rl <- cut(ctx$railway)
    if (!is.null(rl)) k <- k + tmap::tm_shape(rl) +
      tmap::tm_lines(col = "#000000", lwd = 1.1, lty = "42")
  }

  h <- cut(habitat)
  if (!is.null(h)) {
    h$col_gq <- unname(cls$values[h$mapping_code])
    h$col_gq[is.na(h$col_gq)] <- "#999999"
    h$lwd_gq <- unname(cls$widths[h$mapping_code]) * 2.4
    h$lwd_gq[is.na(h$lwd_gq)] <- 1
    k <- k + tmap::tm_shape(h) +
      tmap::tm_lines(col = "col_gq", col.scale = tmap::tm_scale_asis(),
                     col.legend = tmap::tm_legend_hide(),
                     lwd = "lwd_gq", lwd.scale = tmap::tm_scale_asis(),
                     lwd.legend = tmap::tm_legend_hide())
  }

  k <- k + tmap::tm_shape(tracks) + tmap::tm_lines(col = "#e216c4", lwd = 2.6)

  # Road names - one label per named road, placed on the longest segment so the
  # label lands on a piece of road actually in frame.
  if (!is.null(rd) && "name" %in% names(rd)) {
    rn <- rd[!is.na(rd$name) & nzchar(rd$name), ]
    if (nrow(rn) > 0) {
      rn$len <- as.numeric(sf::st_length(rn))
      rn <- do.call(rbind, lapply(split(rn, rn$name), function(x) x[which.max(x$len), ]))
      k <- k + tmap::tm_shape(rn) +
        tmap::tm_text("name", size = 0.42, col = "#3a3a3a",
                      options = tmap::opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
    }
  }

  # eDNA sample sites, labelled with their sample id
  ed <- cut(edna)
  if (!is.null(ed)) {
    k <- k + tmap::tm_shape(ed) +
      tmap::tm_symbols(shape = 23, fill = "#00a99d", col = "white", lwd = 0.6, size = 0.55)
  }

  # Other PSCIS crossings, symbolised and labelled exactly as on the main map -
  # a reader moving between the two should not have to re-learn the symbols.
  xin <- cut(crossings)
  if (!is.null(xin) && !is.null(xing_cls)) {
    xin <- xin[!xin$stream_crossing_id %in% as.character(subject$stream_crossing_id), ]
    if (nrow(xin) > 0) {
      xin$col_gq <- unname(xing_cls$values[xin$barrier_result_code])
      xin$col_gq[is.na(xin$col_gq)] <- "#999999"
      k <- k + tmap::tm_shape(xin) +
        tmap::tm_symbols(shape = 21, fill = "col_gq", fill.scale = tmap::tm_scale_asis(),
                         fill.legend = tmap::tm_legend_hide(),
                         col = "white", lwd = 0.7, size = 0.5)
      xr <- lfpr_label_rule(rules, "crossings_pscis_assessment")
      if (!is.null(xr)) {
        xin$lfpr_lab <- as.character(xin[[xr$label_field]])
        k <- k + tmap::tm_shape(xin) +
          tmap::tm_text("lfpr_lab", size = 0.42, col = xr$label_color, ymod = 0.6,
                        options = tmap::opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
      }
    }
  }

  # Subject crossings: yellow ring with the barrier result in the centre, the
  # same two-part symbol the main map uses.
  sub_mk   <- if (!is.null(reg)) lfpr_sty(reg, "site_assessed", "mark") else NULL
  core_r   <- if (!is.null(reg)) lfpr_sty(reg, "site_assessed_core", "mark")$radius else 0.34
  ring_col <- if (!is.null(sub_mk)) sub_mk$color else "#ffd400"
  subj <- subject
  if (!is.null(xing_cls)) {
    subj$core <- unname(xing_cls$values[subj$barrier_result_code])
    subj$core[is.na(subj$core)] <- "#999999"
  } else subj$core <- ring_col
  k <- k + tmap::tm_shape(subj) +
    tmap::tm_symbols(shape = 21, fill = ring_col, col = "#1a1a1a", lwd = 1.2, size = 0.85) +
    tmap::tm_shape(subj) +
    tmap::tm_symbols(shape = 21, fill = "core", fill.scale = tmap::tm_scale_asis(),
                     fill.legend = tmap::tm_legend_hide(), col = NA,
                     size = 0.85 * (core_r / 0.8))

  # Stagger paired sites above/below. Both at the same offset collide and
  # remove_overlap silently drops one, leaving a labelled crossing next to an
  # unlabelled one.
  lab <- subj
  lab$lab <- as.character(lab$stream_crossing_id)
  lab <- lab[order(lab$lab), ]
  for (i in seq_len(nrow(lab))) {
    k <- k + tmap::tm_shape(lab[i, ]) +
      tmap::tm_text("lab", size = 0.55, fontface = "bold", col = "#1a1a1a",
                    ymod = if (i %% 2 == 1) 0.95 else -0.95,
                    options = tmap::opt_tm_text(shadow = TRUE))
  }
  k <- k +
    # n = 2, not 1. tmap drops the final break's label whatever you do, so a
    # single-segment bar ends up labelled only "0.0 km" - useless. Two segments
    # keep two readable numbers. allow_clipping = FALSE stops the bar being
    # trimmed against the inset frame.
    tmap::tm_scalebar(breaks = lfpr_scale_breaks(bb, n = 2), text.size = 0.4,
                      allow_clipping = FALSE,
                      position = tmap::tm_pos_in("left", "bottom"),
                      margins = c(0, 0, 0, 0)) +
    tmap::tm_layout(frame = TRUE, bg.color = "white",
                    inner.margins = c(0.004, 0.004, 0.004, 0.004))
  k
}

#' Scale bar breaks appropriate to the map extent
#'
#' Returns breaks in km. The whole bar is sized to about a third of the frame
#' width - size it off `span/3` per interval instead and the bar overruns the
#' frame, which tmap reports as "not all scale bar breaks could be plotted" and
#' then silently drops every label but the last.
lfpr_scale_breaks <- function(bb, n = 3, share = 0.35) {
  span_km <- (bb[["xmax"]] - bb[["xmin"]]) / 1000
  raw <- span_km * share / n
  mag <- 10 ^ floor(log10(raw))
  step <- c(1, 2, 5, 10)[which.min(abs(c(1, 2, 5, 10) - raw / mag))] * mag
  seq(0, step * n, by = step)
}

#' Static habitat confirmation site map
#'
#' @param site one or more `stream_crossing_id` to map.
#' @param asp target canvas aspect ratio. Defaults to the current chunk's
#'   `fig.width / fig.height`, which is why the appendix chunks set both.
#' @param extent what the map extent is fitted to. "survey" frames the crossing
#'   and the ground actually walked; "watershed" frames the whole upstream
#'   watershed polygon.
#' @param buffer metres of context added around the survey extent before the
#'   aspect match, so the map is not cropped hard to the GPS tracks.
lfpr_map_site <- function(site,
                          scale = c("watershed", "site"),
                          asp = NULL,
                          buffer = NULL,
                          keymap = TRUE,
                          north = TRUE,
                          species = if (exists("params")) params$model_species else "bt",
                          label_max_modelled = 25) {
  scale <- match.arg(scale)
  if (is.null(buffer)) buffer <- if (scale == "watershed") 1200 else 250

  # Fraction of canvas width reserved for the legend panel. The bbox has to be
  # matched to the aspect of the MAP PANEL, not of the whole canvas - fit it to
  # the canvas and tmap letterboxes the difference into white bands top and
  # bottom, which is exactly the "map fills to frame" rule being broken.
  panel_right <- 0.25

  # s2 off is required for the planar operations below, but this function is
  # sourced into a book that also renders leaflet maps and dozens of sf calls -
  # so restore it rather than leaving it off process-wide.
  old_s2 <- sf::sf_use_s2()
  sf::sf_use_s2(FALSE)
  on.exit(sf::sf_use_s2(old_s2), add = TRUE)

  if (is.null(asp)) {
    w <- knitr::opts_current$get("fig.width")
    h <- knitr::opts_current$get("fig.height")
    asp <- if (!is.null(w) && !is.null(h)) w / h else 9 / 7
  }
  asp_canvas <- asp                 # width/height of the whole canvas
  asp <- asp * (1 - panel_right)   # ...of the map panel

  lyr <- lfpr_read_site_local(site)
  ctx <- lfpr_read_site_cache(site)
  rules <- lfpr_label_rules()

  # "On the subject stream" - the habitat reaches sharing a blue_line_key with
  # the reach nearest the subject crossing, buffered. pscis_assessment_svw
  # carries no blue_line_key, so the stream has to be derived spatially.
  stream_buf <- NULL
  if (!is.null(ctx$habitat) && nrow(ctx$habitat) > 0 && nrow(lyr$subject) > 0 &&
      "blue_line_key" %in% names(ctx$habitat)) {
    blk <- ctx$habitat$blue_line_key[sf::st_nearest_feature(lyr$subject, ctx$habitat)]
    reach <- ctx$habitat[ctx$habitat$blue_line_key %in% blk, ]
    if (nrow(reach) > 0) stream_buf <- sf::st_union(sf::st_buffer(reach, 150))
  }

  focus <- switch(
    scale,
    # Whole upstream watershed plus the crossings and tracks - the watershed
    # polygons do not reliably contain their own crossings (fpr#130), so the
    # crossings are unioned in explicitly rather than assumed inside.
    watershed = c(sf::st_as_sfc(sf::st_bbox(lyr$wshd)),
                  sf::st_as_sfc(sf::st_bbox(lyr$subject)),
                  sf::st_as_sfc(sf::st_bbox(lyr$tracks))),
    site      = c(sf::st_as_sfc(sf::st_bbox(lyr$tracks)),
                  sf::st_as_sfc(sf::st_bbox(lyr$subject)))
  )
  bb <- lfpr_bbox_asp(sf::st_bbox(sf::st_buffer(sf::st_as_sfc(sf::st_bbox(focus)), buffer)),
                      asp = asp)
  # At watershed scale, clamp to the extent the cache was built for. Framing
  # wider than the cached basemap leaves white bands top and bottom - the map
  # has to fill the frame.
  if (scale == "watershed" && !is.null(ctx$basemap)) {
    # Clamp to the basemap's ACTUAL extent, not the bbox it was requested for.
    # Tiles are fetched in Web Mercator and reprojected to BC Albers, and the
    # reprojected quad inscribes a smaller rectangle than the request - so the
    # requested bbox leaves white bands top and bottom even though the pull
    # "succeeded".
    # Inset the clamp. Tiles are fetched in Web Mercator and reprojected to BC
    # Albers, so the valid data is a slightly rotated quad while terra::ext()
    # reports its bounding box - framing to that box leaves empty wedges in the
    # corners. 4% off each side keeps the frame inside the quad.
    cb <- as.vector(terra::ext(ctx$basemap))
    inx <- (cb[["xmax"]] - cb[["xmin"]]) * 0.04
    iny <- (cb[["ymax"]] - cb[["ymin"]]) * 0.04
    cb <- c(xmin = cb[["xmin"]] + inx, xmax = cb[["xmax"]] - inx,
            ymin = cb[["ymin"]] + iny, ymax = cb[["ymax"]] - iny)
    bb[["xmin"]] <- max(bb[["xmin"]], cb[["xmin"]]); bb[["xmax"]] <- min(bb[["xmax"]], cb[["xmax"]])
    bb[["ymin"]] <- max(bb[["ymin"]], cb[["ymin"]]); bb[["ymax"]] <- min(bb[["ymax"]], cb[["ymax"]])
    bb <- lfpr_bbox_asp(bb, asp = asp, margin = 0)
    # Shrinking to the aspect can push back outside the cache, so clamp again
    # and accept whichever dimension binds.
    bb[["xmin"]] <- max(bb[["xmin"]], cb[["xmin"]]); bb[["xmax"]] <- min(bb[["xmax"]], cb[["xmax"]])
    bb[["ymin"]] <- max(bb[["ymin"]], cb[["ymin"]]); bb[["ymax"]] <- min(bb[["ymax"]], cb[["ymax"]])
  }
  bb_sfc <- sf::st_as_sfc(bb)

  crossings_in <- sf::st_filter(lyr$crossings, bb_sfc)

  reg <- lfpr_reg()
  # Return NULL rather than a zero-row sf - tmap's tm_shape() errors with
  # "subscript out of bounds" on an empty geometry set rather than skipping it.
  clip <- function(x) {
    if (is.null(x) || nrow(x) == 0) return(NULL)
    out <- sf::st_filter(x, bb_sfc)
    if (nrow(out) == 0) NULL else out
  }

  tmap::tmap_mode("plot")

  # --- 1. basemap: Positron multiplied by hillshade from our own DEM --------
  # The frame is set by an explicit main shape carrying `bbox`. Without it tmap
  # frames on the union of every layer, and clip() keeps whole features that
  # merely intersect the bbox - so a stream crossing the edge drags the frame
  # out past the basemap and leaves white bands.
  blend <- lfpr_basemap_blend(ctx$basemap, ctx$dem, bb)
  m <- tmap::tm_shape(bb_sfc, bbox = bb, is.main = TRUE) +
    tmap::tm_borders(lwd = 0, col = NA)
  if (!is.null(blend)) m <- m + tmap::tm_shape(blend) + tmap::tm_rgb()

  # --- 2. hydrography and wetlands under everything ------------------------
  for (nm in c("wetlands", "rivers")) {
    x <- clip(ctx[[nm]])
    if (!is.null(x)) m <- m + tmap::tm_shape(x) +
      do.call(tmap::tm_polygons, gq::gq_tmap_style(reg, if (nm == "wetlands") "wetland" else "rivers_poly"))
  }

  streams <- clip(ctx$streams)
  if (!is.null(streams)) {
    sty <- gq::gq_style(reg, "streams_all")
    m <- m + tmap::tm_shape(streams) +
      tmap::tm_lines(col = sty$classification$values[[1]],
                     lwd = sty$classification$widths[[1]] * 2)
  }

  # --- 3. survey extent: translucent casing UNDER the habitat lines --------
  cas <- lfpr_sty(reg, "survey_track_casing")
  m <- m + tmap::tm_shape(lyr$tracks) +
    tmap::tm_lines(col = cas$color, lwd = cas$width, col_alpha = cas$opacity)

  # --- 4. modelled habitat, thin to thick so SPAWN lands on top ------------
  habitat <- clip(ctx$habitat)
  cls <- gq::gq_tmap_classes(reg, paste0("streams_", species))
  present <- character(0)
  if (!is.null(habitat) && "mapping_code" %in% names(habitat)) {
    habitat$use <- sub(";.*", "", habitat$mapping_code)
    present <- intersect(names(cls$values), unique(habitat$mapping_code))
    for (u in c("ACCESS", "REAR", "SPAWN")) {
      h <- habitat[habitat$use == u, ]
      if (nrow(h) == 0) next
      # gq_tmap_style() collapses lwd to a scalar, dropping the width axis
      # entirely, so widths come from gq_tmap_classes() and are applied per
      # feature with tm_scale_asis().
      # Width alone is a weak cue at watershed scale against the barrier-status
      # colour, and ACCESS outnumbers the rest roughly 2:1. Widen the spread and
      # let accessible recede so modelled spawning and rearing actually read.
      h$lwd_gq <- unname(cls$widths[h$mapping_code]) * 3.1
      h$lwd_gq[is.na(h$lwd_gq)] <- min(cls$widths, na.rm = TRUE) * 3.1
      alpha_u <- switch(u, ACCESS = 0.55, REAR = 0.95, SPAWN = 1)
      # Intermittent reaches are drawn in two passes rather than with a
      # per-feature lty - tmap 4.2 rejects a mixed character lty column under
      # tm_scale_asis() ("values should conform visual variable lty").
      for (int in c(FALSE, TRUE)) {
        hh <- h[grepl(";INTERMITTENT", h$mapping_code) == int, ]
        if (nrow(hh) == 0) next
        m <- m + tmap::tm_shape(hh) +
          tmap::tm_lines(
            col = "mapping_code",
            col.scale = tmap::tm_scale_categorical(values = cls$values, levels = names(cls$values)),
            col.legend = tmap::tm_legend_hide(),
            lwd = "lwd_gq", lwd.scale = tmap::tm_scale_asis(), lwd.legend = tmap::tm_legend_hide(),
            col_alpha = alpha_u,
            lty = if (int) "22" else "solid"
          )
      }
    }
  }

  # --- 5. lakes above streams, then transport ------------------------------
  lakes <- clip(ctx$lakes)
  if (!is.null(lakes)) m <- m + tmap::tm_shape(lakes) +
    do.call(tmap::tm_polygons, gq::gq_tmap_style(reg, "lake"))

  roads <- clip(ctx$roads)
  roads_other <- NULL
  if (!is.null(roads)) {
    road_cls <- gq::gq_style(reg, "roads_dra")$classification
    # The registry knows 26 transport_line_type_codes; FWA carries a few it does
    # not ("T" for trail). tmap builds the scale from registry levels and errors
    # on an unknown value rather than falling back, so those draw neutral.
    roads_known <- roads[roads$transport_line_type_code %in% names(road_cls$values), ]
    roads_other <- roads[!roads$transport_line_type_code %in% names(road_cls$values), ]
    if (nrow(roads_known) > 0) {
      m <- m + tmap::tm_shape(roads_known) +
        do.call(tmap::tm_lines, gq::gq_tmap_style(reg, "roads_dra", field = "transport_line_type_code"))
    }
    if (nrow(roads_other) > 0) {
      m <- m + tmap::tm_shape(roads_other) +
        tmap::tm_lines(col = "grey55", lwd = 0.6, lty = "dotted")
    }
  }

  rail <- clip(ctx$railway)
  rail_sty <- gq::gq_style(reg, "railway")
  if (!is.null(rail)) {
    m <- m + tmap::tm_shape(rail) +
      tmap::tm_lines(col = rail_sty$stroke$color, lwd = rail_sty$stroke$width * 2) +
      tmap::tm_shape(rail) +
      tmap::tm_lines(col = "white", lwd = rail_sty$stroke$width, lty = "42")
  }

  # Name the roads the assessed crossings actually sit on. Labelling every road
  # at watershed scale is unreadable; the road at the crossing is the one a
  # reader needs, and it is what the appendix prose refers to.
  if (!is.null(roads) && "name" %in% names(roads) && nrow(lyr$subject) > 0) {
    near <- roads[sf::st_nearest_feature(lyr$subject, roads), ]
    near <- near[!is.na(near$name) & nzchar(near$name), ]
    if (nrow(near) > 0) {
      near <- near[!duplicated(near$name), ]
      m <- m + tmap::tm_shape(near) +
        # Below the marker - the crossing id label sits above it.
        tmap::tm_text("name", size = 0.5, col = "#2a2a2a", fontface = "italic",
                      ymod = -0.95,
                      options = tmap::opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
    }
  }

  # --- 6. upstream watershed boundary over the context ---------------------
  if (nrow(lyr$wshd) > 0) {
    m <- m + tmap::tm_shape(lyr$wshd) +
      tmap::tm_polygons(fill = lfpr_sty(reg, "watershed_upstream", "fill")$color,
                        fill_alpha = lfpr_sty(reg, "watershed_upstream", "fill")$opacity,
                        col = lfpr_sty(reg, "watershed_upstream")$color,
                        lwd = lfpr_sty(reg, "watershed_upstream")$width)
  }

  # --- 7. survey extent core -----------------------------------------------
  trk <- lfpr_sty(reg, "survey_track")
  m <- m + tmap::tm_shape(lyr$tracks) +
    tmap::tm_lines(col = trk$color,
                   lwd = trk$width * if (scale == "watershed") 1.4 else 1)

  # --- 8. known fish presence ----------------------------------------------
  fish <- clip(ctx$fish_obs)
  if (!is.null(fish)) {
    fish_sty <- gq::gq_style(reg, "bcfishobs_fiss_fish_observations")
    m <- m + tmap::tm_shape(fish) +
      tmap::tm_symbols(shape = 24, fill = fish_sty$mark$color,
                       col = "white", lwd = 0.4, size = 0.22)
    fr <- lfpr_label_rule(rules, "fish_obs")
    fl <- lfpr_label_scope(fish, fr, lyr$wshd, stream_buf)
    if (!is.null(fl)) {
      m <- m + tmap::tm_shape(fl) +
        tmap::tm_text("lfpr_lab", size = fr$label_size, col = fr$label_color,
                      fontface = "bold", ymod = -0.45,
                      options = tmap::opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
    }
  }

  obst <- clip(ctx$obstacles)
  if (!is.null(obst)) {
    obst_sty <- gq::gq_style(reg, "fiss_obstacles")
    m <- m + tmap::tm_shape(obst) +
      tmap::tm_symbols(shape = 22, fill = obst_sty$mark$color, col = "white",
                       lwd = 0.4, size = 0.3)
  }

  # --- 9. eDNA sample sites, when the project has them ---------------------
  edna <- NULL
  edna_all <- NULL
  if (exists("form_edna")) {
    e <- try(lfpr_crs_bc(form_edna, what = "form_edna"), silent = TRUE)
    if (!inherits(e, "try-error")) { edna_all <- e; edna <- clip(e) }
  }
  if (!is.null(edna)) {
    ed_sty <- lfpr_sty(reg, "edna_sample", "mark")
    m <- m + tmap::tm_shape(edna) +
      tmap::tm_symbols(shape = 23, fill = ed_sty$color, col = "white",
                       lwd = 0.6, size = ed_sty$radius)
  }

  # --- 9b. modelled crossings, inside the upstream watershed only ----------
  # These are candidate barriers that have never been assessed. Restricted to
  # the upstream watershed deliberately: across the whole frame they are noise,
  # but above the site they are the work still outstanding. Labelled with the
  # modelled crossing id where one exists.
  mx <- clip(ctx$crossings_modelled)
  if (!is.null(mx) && nrow(lyr$wshd) > 0) {
    mx <- sf::st_filter(mx, sf::st_union(lyr$wshd))
    if (nrow(mx) > 0) {
      mx_sty <- gq::gq_style(reg, "crossings_modelled")
      m <- m + tmap::tm_shape(mx) +
        tmap::tm_symbols(shape = 21, fill = mx_sty$mark$color, col = "#4a4a4a",
                         lwd = 0.6, size = 0.3)
      mr <- lfpr_label_rule(rules, "crossings_modelled")
      lab_mx <- lfpr_label_scope(mx, mr, lyr$wshd, stream_buf)
      if (!is.null(lab_mx)) {
        m <- m + tmap::tm_shape(lab_mx) +
          tmap::tm_text("lfpr_lab", size = mr$label_size, col = mr$label_color, ymod = 0.5,
                        options = tmap::opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
      }
    } else mx <- NULL
  } else mx <- NULL

  # --- 10. crossings, classified by barrier result, labelled on the map ----
  xing_cls <- gq::gq_style(reg, "crossings_pscis_assessment")$classification
  if (nrow(crossings_in) > 0) {
    x <- crossings_in
    x$col_gq <- unname(xing_cls$values[x$barrier_result_code])
    x$col_gq[is.na(x$col_gq)] <- "grey50"
    m <- m + tmap::tm_shape(x) +
      tmap::tm_symbols(shape = 21, fill = "col_gq", fill.scale = tmap::tm_scale_asis(),
                       fill.legend = tmap::tm_legend_hide(),
                       col = "white", lwd = 0.7, size = 0.45)
    xr <- lfpr_label_rule(rules, "crossings_pscis_assessment")
    xl <- lfpr_label_scope(x, xr, lyr$wshd, stream_buf)
    if (!is.null(xl)) {
      xl <- xl[!xl$stream_crossing_id %in% as.character(lyr$subject$stream_crossing_id), ]
      if (nrow(xl) > 0) {
        m <- m + tmap::tm_shape(xl) +
          tmap::tm_text("lfpr_lab", size = xr$label_size, col = xr$label_color,
                        ymod = 0.55,
                        options = tmap::opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
      }
    }
  }

  # Subject crossings drawn larger, and labelled. Labels go on the map rather
  # than into the legend so the legend can stay identical from map to map.
  # Yellow ring marks "assessed by this project"; the centre is filled with the
  # PSCIS barrier result, so one symbol carries both facts. No extra legend row -
  # the Crossings - PSCIS block already defines those colours.
  sub_sty <- lfpr_sty(reg, "site_assessed", "mark")
  core_r  <- lfpr_sty(reg, "site_assessed_core", "mark")$radius
  ring_sz <- sub_sty$radius * if (scale == "watershed") 1 else 1.1
  subj <- lyr$subject
  subj$core <- unname(xing_cls$values[subj$barrier_result_code])
  subj$core[is.na(subj$core)] <- lfpr_sty(reg, "class_unknown", "mark")$color
  m <- m + tmap::tm_shape(subj) +
    tmap::tm_symbols(shape = 21, fill = sub_sty$color, col = sub_sty$stroke_color,
                     lwd = sub_sty$stroke_width, size = ring_sz) +
    tmap::tm_shape(subj) +
    tmap::tm_symbols(shape = 21, fill = "core", fill.scale = tmap::tm_scale_asis(),
                     fill.legend = tmap::tm_legend_hide(),
                     col = NA, size = core_r * (ring_sz / sub_sty$radius))

  # Label the subject crossings on the map, not in the legend, so the legend can
  # stay identical from map to map. Paired sites sit a few hundred metres apart,
  # which is a single pixel at watershed scale, so they get one combined label
  # rather than two overlapping ones - the keymap separates them.
  if (nrow(lyr$subject) > 0) {
    ids <- sort(unique(as.character(lyr$subject$stream_crossing_id)))
    sep_m <- if (nrow(lyr$subject) > 1) max(sf::st_distance(lyr$subject)) else units::set_units(0, "m")
    frame_m <- bb[["xmax"]] - bb[["xmin"]]
    if (as.numeric(sep_m) < frame_m * 0.04) {
      lab <- sf::st_sf(label = paste(ids, collapse = " / "),
                       geometry = sf::st_centroid(sf::st_union(lyr$subject)))
    } else {
      lab <- lyr$subject
      lab$label <- as.character(lab$stream_crossing_id)
    }
    m <- m + tmap::tm_shape(lab) +
      tmap::tm_text("label", size = 0.6, fontface = "bold", col = "#1a1a1a",
                    ymod = 0.9, options = tmap::opt_tm_text(shadow = TRUE))
  }

  # --- 11. legends ---------------------------------------------------------
  # Deliberately GENERIC: the same rows appear on every map whether or not the
  # class occurs in this frame. Subsetting to what is present means the legend
  # shifts shape from appendix to appendix, which costs per-map fiddling and
  # makes the maps harder to compare against each other.
  m <- m +
    tmap::tm_add_legend(
      type = "lines",
      title = paste0("Modelled habitat (", toupper(species), ")"),
      labels = unname(lfpr_tok_use[c("SPAWN", "REAR", "ACCESS")]),
      col = rep("grey35", 3),
      lwd = c(1.7, 1.0, 0.4) * 3.1
    ) +
    tmap::tm_add_legend(
      type = "lines", title = "Barrier status downstream",
      labels = unname(lfpr_tok_status[c("NONE", "MODELLED", "ASSESSED", "DAM", "REMEDIATED")]),
      col = unname(cls$values[paste0("SPAWN;", c("NONE", "MODELLED", "ASSESSED", "DAM", "REMEDIATED"))]),
      lwd = rep(2, 5)
    ) +
    tmap::tm_add_legend(
      type = "symbols", title = "Crossings - PSCIS",
      labels = c(unname(xing_cls$labels), "Modelled, not assessed", "Assessed this project"),
      fill = c(unname(xing_cls$values),
               gq::gq_style(reg, "crossings_modelled")$mark$color, "#ffd400"),
      shape = rep(21, length(xing_cls$values) + 2),
      size = c(rep(0.45, length(xing_cls$values)), 0.35, 0.7)
    ) +
    tmap::tm_add_legend(
      type = "symbols", title = "Observations",
      labels = c("Fish observation (FISS)", "Natural obstacle", "eDNA sample"),
      fill = c(gq::gq_style(reg, "bcfishobs_fiss_fish_observations")$mark$color,
               gq::gq_style(reg, "fiss_obstacles")$mark$color, "#00a99d"),
      shape = c(24, 22, 23), size = c(0.35, 0.35, 0.45)
    ) +
    tmap::tm_add_legend(
      type = "lines", title = "Features",
      labels = c("Surveyed", "Road", "Railway"),
      col = c("#e216c4", "#484848", rail_sty$stroke$color),
      lwd = c(2, 1, 1.2), lty = c("solid", "solid", "twodash")
    ) +
    tmap::tm_add_legend(
      type = "polygons",
      labels = c("Upstream watershed", "Lake"),
      fill = c("#4a90c4", gq::gq_style(reg, "lake")$fill$color),
      fill_alpha = c(0.22, 1)
    )

  # Four-corner rule: legend bottom-left, scalebar bottom-centre, keymap
  # bottom-right, logo top-right, north arrow top-left. Five elements, five
  # slots, nothing doubled up.
  m <- m +
    # Non-zero bottom margin - at zero the labels sit on the frame edge and get
    # clipped.
    tmap::tm_scalebar(breaks = lfpr_scale_breaks(bb), text.size = 0.5,
                      position = tmap::tm_pos_in("left", "bottom"),
                      margins = c(0.02, 0.02, 0, 0)) +
    tmap::tm_layout(
      frame = TRUE,
      frame.lwd = 0.5,
      asp = 0,
      # Legend outside the map frame, as in the QGIS layouts it replaces - a
      # legend this size occludes real map content when it sits on top.
      legend.position = tmap::tm_pos_out("right", "center"),
      legend.frame = FALSE,
      legend.text.size = 0.52,
      legend.title.size = 0.64,
      inner.margins = c(0.001, 0.001, 0.001, 0.001),
      # room under the scalebar so its labels are not clipped by the frame
      outer.margins.bottom = 0.005,
      outer.margins = c(0.003, 0.003, 0.003, 0.003),
      # Reserve the right-hand panel for the legend. meta.margins = 0 leaves no
      # room outside the frame, which makes an out-position legend collapse to
      # zero size and fail with "invalid 'cex' value".
      meta.margins = c(0, 0, 0, panel_right)
    )

  if (north) {
    # The New Graph mark stands in for a north arrow. It is close enough to
    # north at this scale, it is what the QGIS layouts this replaces used, and
    # it doubles as the branding - so there is no separate logo element.
    m <- m + tmap::tm_logo(system.file("logo", "nge_icon_200.png", package = "gq"),
                           position = tmap::tm_pos_in("left", "top"), height = 2.4,
                           margins = c(0, 0, 0, 0))
  }

  # The keymap is pinned to the bottom of the legend panel with a grid
  # viewport rather than tm_inset(). tmap will not place an inset and a legend
  # at different vertical positions in the same outer cell - it fails inside the
  # component stacker with "missing value where TRUE/FALSE needed" - and
  # stacking it directly under the legend leaves it floating mid-panel. The
  # keymap sits outside the map frame anyway, so it does not need tmap's margin
  # arithmetic.
  key_grob <- NULL
  if (keymap && scale == "watershed" && nrow(lyr$tracks) > 0) {
    # Build the grob on a device the size the keymap will actually be drawn at.
    # tmap sizes scale bars, text and margins in ABSOLUTE units against the
    # current device; grid viewports scale npc but not inches, so a grob built
    # against the full 9-inch canvas and then squeezed into a 2-inch inset keeps
    # a scale bar sized for a 9-inch map - it renders wider than the inset
    # itself. Rendering to a correctly-sized offscreen device first makes the
    # absolute units come out right.
    # component.offset defaults to c(0.75, 0, 0, 0) - three quarters of a line
    # of padding that holds the scale bar well off the corner. Zero it for the
    # keymap so the bar sits where it was asked to.
    old_opt <- tmap::tmap_options(component.offset = c(0, 0, 0, 0))
    on.exit(tmap::tmap_options(old_opt), add = TRUE)
    key_side_in <- grDevices::dev.size("in")[1] * panel_right * 0.99
    cur_dev <- grDevices::dev.cur()
    tmp_png <- tempfile(fileext = ".png")
    grDevices::png(tmp_png, width = key_side_in, height = key_side_in,
                   units = "in", res = 150)
    key_grob <- try(tmap::tmap_grob(
      lfpr_keymap_survey(lyr$tracks, lyr$subject, clip(ctx$habitat), cls,
                         ctx = ctx, edna = edna_all,
                         crossings = lyr$crossings, xing_cls = xing_cls,
                         reg = reg, rules = rules),
      show = FALSE), silent = TRUE)
    grDevices::dev.off()
    unlink(tmp_png)
    if (cur_dev > 1) grDevices::dev.set(cur_dev)
    if (inherits(key_grob, "try-error")) key_grob <- NULL
  }

  print(m)
  if (!is.null(key_grob)) {
    # Square, right-aligned in the panel, sitting just above the bottom margin.
    side <- panel_right * 0.99
    grid::pushViewport(grid::viewport(
      x = 1 - panel_right / 2, y = 0.012 + (side * asp_canvas) / 2,
      width = side, height = side * asp_canvas, just = "centre"))
    grid::grid.draw(key_grob)
    grid::popViewport()
  }

  # Border around the whole page - map and legend panel together - matching the
  # "Border" rectangle item the QGIS layouts carry.
  grid::grid.rect(gp = grid::gpar(col = "#1a1a1a", fill = NA, lwd = 1.2))
  invisible(m)
}

#' Attribution line for a site map caption
#'
#' The Positron basemap tiles are (c) OpenStreetMap contributors and (c) CARTO.
#' Baking them into a committed GeoTIFF and shipping them in a public report
#' carries that attribution obligation, so every caption states it.
lfpr_map_credit <- function(site, dir_gis = "data/gis") {
  meta <- fs::path(dir_gis, paste0("map_", as.character(min(site)), "_meta.rds"))
  model <- if (fs::file_exists(meta)) readRDS(meta)$model_run_id else NA
  paste0(
    "Modelled habitat from bcfishpass",
    if (!is.na(model)) paste0(" (model run ", model, ")") else "",
    ". Basemap (c) OpenStreetMap contributors, (c) CARTO; relief from MRDEM-30."
  )
}
