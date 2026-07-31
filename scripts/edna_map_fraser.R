# =============================================================================
# Fraser-only interactive eDNA map.
#
# Reads the snapshotted by_site_target CSV (region-tagged via `source` column),
# filters to Fraser via `source` matching `sern_fraser_2024`, builds a
# mapgl interactive map mirroring the combined-region template map but
# scoped to Fraser sites only.
#
# Output: data/edna_unbc_results_2025_fraser_map.html
#         docs/edna_unbc_results_2025_fraser_map.html   (copied by this script)
#
# The docs/ copy is what `params$report_url` resolves against, so the report's
# map links work. Peace does this copy by hand; scripting it here means a
# refreshed map can't silently fail to reach the published site.
#
# Refresh procedure (when upstream data changes):
#   1. source('scripts/edna_inputs_snapshot.R')  # re-snapshot CSVs from template
#   2. source('scripts/edna_map_fraser.R')       # rebuild this map + docs copy
#
# Logic mirrors fish_passage_template_reporting/scripts/edna_unbc_results_explore.R
# (the combined map). When map-build code stabilizes across both, factor the
# shared bits into a helper (likely in ngr/fpr) — until then, keeping a Fraser
# copy here keeps the report self-contained per issue #10.
# =============================================================================

POS_FLOOR <- 4   # ddPCR confident-call threshold (matches upstream)
FRASER_SOURCE_PATTERN <- "sern_fraser_2024"
out_html      <- "data/edna_unbc_results_2025_fraser_map.html"
out_html_docs <- "docs/edna_unbc_results_2025_fraser_map.html"

# --- Load snapshotted by_site_target + filter to Fraser ----------------------
#
# Controls handling:
#   - Office blanks: distilled-water controls filtered at the end of a session
#     at accommodation. Their GPS is real, but it records a hotel rather than a
#     stream, and the site_id is borrowed from an unrelated site (or is a date
#     when none was handy) — DROP entirely from the map.
#   - Field blanks: real streamside coords, but they're QA samples testing
#     protocol cleanliness, not site eDNA. Surface in a separate "Controls"
#     layer hidden by default, with explicit popup disclaimer. Treated like the
#     sub-threshold layer — opt-in for QA review, not in the default
#     public read.
#   - Positive controls (control_species_present_field): real environmental
#     samples at electrofish-confirmed sites. Stay in default layers; popup
#     gets a note flagging them.

by_site_target_full <- readr::read_csv(
  "data/edna_unbc_results_2025_by_site_target.csv",
  show_col_types = FALSE
) |>
  dplyr::filter(grepl(FRASER_SOURCE_PATTERN, source))

# Coerce blank flags to logical with no NAs. readr types these as logical when
# the CSV holds TRUE/FALSE/NA, so an is.logical() early return is NOT enough —
# the NAs survive and poison any()/filter() downstream.
norm_lgl <- function(x) {
  if (is.logical(x)) {
    x[is.na(x)] <- FALSE
    return(x)
  }
  out <- toupper(as.character(x)) == "TRUE"
  out[is.na(out)] <- FALSE
  out
}
by_site_target_full <- by_site_target_full |>
  dplyr::mutate(
    control_blank_field           = norm_lgl(control_blank_field),
    control_blank_office          = norm_lgl(control_blank_office),
    control_species_present_field = norm_lgl(control_species_present_field)
  )

# Office blanks are not sites — drop entirely
by_site_target <- by_site_target_full |>
  dplyr::filter(!control_blank_office)

# Field blanks: split off for the Controls layer (off by default)
by_site_target_blanks <- by_site_target |>
  dplyr::filter(control_blank_field)

# Real environmental samples (incl. positive controls — those stay)
by_site_target_real <- by_site_target |>
  dplyr::filter(!control_blank_field)

cat(sprintf("Fraser summary:\n"))
cat(sprintf("  Total sites x targets (after office-blank filter): %d rows, %d sites\n",
            nrow(by_site_target),
            dplyr::n_distinct(by_site_target$site_id)))
cat(sprintf("  Real environmental samples:                        %d rows, %d sites\n",
            nrow(by_site_target_real),
            dplyr::n_distinct(by_site_target_real$site_id)))
cat(sprintf("  Field blanks (Controls layer):                     %d rows, %d sites\n",
            nrow(by_site_target_blanks),
            dplyr::n_distinct(by_site_target_blanks$site_id)))
cat(sprintf("  Office blanks dropped:                             %d sites\n",
            dplyr::n_distinct(by_site_target_full$site_id) -
              dplyr::n_distinct(by_site_target$site_id)))

# --- Per-site rollup for the map (mirrors template's `by_site`) -------------

fmt_species <- function(target, max_pos, retested) {
  if (length(target) == 0) return("-")
  parts <- paste0(
    target, "(", ifelse(is.na(max_pos), "?", max_pos),
    ifelse(retested, ",retest", ""), ")"
  )
  paste(parts, collapse = ", ")
}

build_by_site <- function(bst) {
  bst |>
    dplyr::group_by(site_id, stream_name, utm_zone, easting, northing) |>
    dplyr::summarise(
      lab_ids        = paste(sort(unique(unlist(strsplit(lab_ids, ", ")))),
                             collapse = ", "),
      control_species_present_field = dplyr::first(control_species_present_field),
      n_assays       = sum(n_runs),
      n_pos_crude    = sum(any_crude),
      n_pos_clean    = sum(any_clean),
      species_clean  = fmt_species(target[any_clean],
                                   max_pos[any_clean],
                                   retested[any_clean]),
      species_crude_only = fmt_species(target[any_crude & !any_clean],
                                       max_pos[any_crude & !any_clean],
                                       retested[any_crude & !any_clean]),
      species_none   = fmt_species(target[!any_crude],
                                   max_pos[!any_crude],
                                   retested[!any_crude]),
      species_tested = paste(sort(unique(target)), collapse = ", "),
      max_conc       = suppressWarnings(max(max_conc[any_clean], na.rm = TRUE)),
      .groups = "drop"
    ) |>
    dplyr::mutate(max_conc = ifelse(is.finite(max_conc), max_conc, NA_real_))
}

by_site        <- build_by_site(by_site_target_real)
by_site_blanks <- build_by_site(by_site_target_blanks)

# --- Project to WGS84 (per UTM zone) ----------------------------------------

zones <- sort(unique(by_site$utm_zone))
pts_list <- lapply(zones, function(z) {
  sub <- by_site |> dplyr::filter(utm_zone == z)
  sf::st_as_sf(sub, coords = c("easting", "northing"), crs = 26900L + z) |>
    sf::st_transform(4326)
})
pts <- do.call(rbind, pts_list)

pts <- pts |>
  dplyr::mutate(
    popup = paste0(
      "<b>", site_id, "</b><br>",
      ifelse(is.na(stream_name), "", paste0(stream_name, "<br>")),
      ifelse(control_species_present_field,
             "<i>Positive control — species presence verified by electrofishing</i><br>",
             ""),
      "UNBC ID(s): ", lab_ids, "<br>",
      "Assays run: ", n_assays, "<br>",
      "<b>Detected</b> (&ge;", POS_FLOOR, " droplets): ", species_clean, "<br>",
      "Not detected (0 droplets): ", species_none, "<br>",
      "<i>Sub-threshold signals (1-", POS_FLOOR - 1,
      " droplets, NOT detections):</i> ", species_crude_only, "<br>",
      "Max conc (copies/uL, detections): ",
      ifelse(is.na(max_conc), "-", round(max_conc, 2)), "<br>",
      "<i>Format: SPECIES(max_droplets[,retest])</i>"
    )
  )

# --- Per-species (jittered) points for toggleable layers --------------------

# Name each colour against its assay code rather than relying on positional
# order — Peace pairs a 7-colour vector with setNames() against its species
# list, so dropping a species (GRAY, absent from the Fraser batch) silently
# leaves an unnamed 7th colour and the categorical legend errors out on the
# length mismatch.
species_colors <- c(
  BULT = "#E41A1C",
  RAIN = "#377EB8",
  CHIN = "#4DAF4A",
  SOCK = "#984EA3",
  COHO = "#FF7F00",
  BURB = "#F781BF"
)
species_list <- names(species_colors)
stopifnot(length(species_list) == length(species_colors))

jitter_r  <- 0.00025
angles    <- seq(0, 2 * pi, length.out = length(species_list) + 1)[seq_along(species_list)]
jitter_dx <- stats::setNames(jitter_r * cos(angles), species_list)
jitter_dy <- stats::setNames(jitter_r * sin(angles), species_list)

pts_target <- by_site_target_real |>
  dplyr::filter(target %in% species_list) |>
  dplyr::mutate(
    status             = dplyr::if_else(any_clean, "clean", "none"),
    sub_threshold_only = any_crude & !any_clean
  )

species_radius_expr <- list(
  "interpolate", list("linear"), list("zoom"),
  6,  list("case",
           list("==", list("get", "status"), "clean"), 10,
           3),
  16, list("case",
           list("==", list("get", "status"), "clean"), 22,
           7)
)

pts_target_list <- lapply(sort(unique(pts_target$utm_zone)), function(z) {
  sub <- pts_target |> dplyr::filter(utm_zone == z)
  s <- sf::st_as_sf(sub, coords = c("easting", "northing"), crs = 26900L + z) |>
    sf::st_transform(4326)
  coords <- sf::st_coordinates(s)
  sf::st_drop_geometry(s) |>
    dplyr::mutate(
      lon = coords[, 1] + jitter_dx[target],
      lat = coords[, 2] + jitter_dy[target]
    ) |>
    sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
})
pts_target <- do.call(rbind, pts_target_list)

pts_target <- pts_target |>
  dplyr::mutate(
    popup = paste0(
      "<b>", site_id, " &mdash; ", target, "</b><br>",
      ifelse(is.na(stream_name), "", paste0(stream_name, "<br>")),
      ifelse(control_species_present_field,
             "<i>Positive control — species presence verified by electrofishing</i><br>",
             ""),
      "UNBC ID(s): ", lab_ids, "<br>",
      "<b>", ifelse(status == "clean", "DETECTED", "Not detected"), "</b><br>",
      "Max droplets: ", ifelse(is.na(max_pos), "-", max_pos),
      ifelse(status == "clean", "",
             paste0(" (below ", POS_FLOOR, "-droplet call threshold)")), "<br>",
      "Max conc (copies/uL): ", ifelse(is.na(max_conc), "-", round(max_conc, 2)), "<br>",
      "Runs: ", n_runs, ifelse(retested, " (UNBC retest)", "")
    )
  )

# --- Build map: All-sites aggregate + per-species layers --------------------

m <- mapgl::maplibre(
  style  = mapgl::carto_style("positron"),
  bounds = sf::st_bbox(pts)
) |>
  mapgl::add_circle_layer(
    id                  = "All sites",
    source              = pts,
    circle_color        = mapgl::interpolate(
      column = "n_pos_clean",
      values = c(0, max(pts$n_pos_clean, na.rm = TRUE)),
      stops  = c("#2b83ba", "#d7191c")
    ),
    circle_radius       = list(
      "interpolate", list("linear"), list("zoom"),
      6,  10,
      16, 22
    ),
    circle_stroke_color = "#222",
    circle_stroke_width = 0.5,
    circle_opacity      = 0.35,
    popup = "popup"
  )

for (sp in species_list) {
  sp_data <- pts_target |> dplyr::filter(target == sp)
  if (nrow(sp_data) == 0) next
  m <- m |>
    mapgl::add_circle_layer(
      id                  = sp,
      source              = sp_data,
      circle_color        = species_colors[[sp]],
      circle_radius       = species_radius_expr,
      circle_opacity      = 0.9,
      circle_stroke_color = "#222",
      circle_stroke_width = 0.5,
      popup = "popup"
    )
}

# --- Sub-threshold QA layer (NOT detections, hidden by default) -------------

pts_subthreshold <- pts_target |>
  dplyr::filter(sub_threshold_only) |>
  dplyr::mutate(
    popup = paste0(
      "<b>NOT A DETECTION &mdash; sub-threshold signal</b><br>",
      "<b>", site_id, "</b> &mdash; ", target, "<br>",
      ifelse(is.na(stream_name), "", paste0(stream_name, "<br>")),
      "UNBC ID(s): ", lab_ids, "<br>",
      "Droplets: ", ifelse(is.na(max_pos), "-", max_pos),
      " (below ", POS_FLOOR, "-droplet call threshold)<br>",
      "Runs: ", n_runs, ifelse(retested, " (UNBC retest)", ""), "<br>",
      "<small><i>Single droplets can occur as background artifacts and are ",
      "not interpretable as species presence. Shown for QA transparency only.</i></small>"
    )
  )

if (nrow(pts_subthreshold) > 0) {
  sp_color_match <- list("match", list("get", "target"))
  for (sp in species_list) {
    sp_color_match[[length(sp_color_match) + 1]] <- sp
    sp_color_match[[length(sp_color_match) + 1]] <- unname(species_colors[[sp]])
  }
  sp_color_match[[length(sp_color_match) + 1]] <- "#888"

  m <- m |>
    mapgl::add_circle_layer(
      id                    = "Sub-threshold signals (NOT detections)",
      source                = pts_subthreshold,
      circle_color          = sp_color_match,
      circle_radius         = list(
        "interpolate", list("linear"), list("zoom"),
        6, 5, 16, 12
      ),
      circle_opacity        = 0.2,
      circle_stroke_color   = "#444",
      circle_stroke_width   = 2,
      circle_stroke_opacity = 0.9,
      visibility            = "none",
      popup                 = "popup"
    )
}

# --- Controls layer (field blanks, NOT site eDNA — hidden by default) -------
# Field blanks are sampled at site coords but test protocol cleanliness, not
# eDNA presence at that site. Casual viewers might misread them as "site
# tested negative". Same opt-in pattern as sub-threshold: hidden by default,
# opt in via the layer toggle. Visual: solid gray + heavy black stroke,
# distinctly NOT a species color. Popup leads with bold "FIELD BLANK"
# disclaimer.

if (nrow(by_site_blanks) > 0) {
  blank_zones <- sort(unique(by_site_blanks$utm_zone))
  pts_blanks_list <- lapply(blank_zones, function(z) {
    sub <- by_site_blanks |> dplyr::filter(utm_zone == z)
    sf::st_as_sf(sub, coords = c("easting", "northing"), crs = 26900L + z) |>
      sf::st_transform(4326)
  })
  pts_blanks <- do.call(rbind, pts_blanks_list) |>
    dplyr::mutate(
      popup = paste0(
        "<b>FIELD BLANK &mdash; protocol QA, not site eDNA</b><br>",
        "<b>", site_id, "</b><br>",
        ifelse(is.na(stream_name), "", paste0(stream_name, "<br>")),
        "UNBC ID(s): ", lab_ids, "<br>",
        "Assays run: ", n_assays, "<br>",
        "<b>Detection in blank</b> (&ge;", POS_FLOOR, " droplets): ", species_clean, "<br>",
        "Clean (0 droplets): ", species_none, "<br>",
        "<i>Sub-threshold (1-", POS_FLOOR - 1, " droplets):</i> ", species_crude_only, "<br>",
        "<small><i>Field blanks filter distilled water at the field site to ",
        "test for protocol contamination. Detections in blanks indicate ",
        "potential cross-contamination, NOT species presence at this location.</i></small>"
      )
    )

  m <- m |>
    mapgl::add_circle_layer(
      id                    = "Controls (field blanks — NOT site eDNA)",
      source                = pts_blanks,
      circle_color          = "#888",
      circle_radius         = list(
        "interpolate", list("linear"), list("zoom"),
        6, 8, 16, 18
      ),
      circle_opacity        = 0.7,
      circle_stroke_color   = "#000",
      circle_stroke_width   = 2.5,
      circle_stroke_opacity = 1.0,
      visibility            = "none",
      popup                 = "popup"
    )
}

m <- m |>
  mapgl::add_layers_control(
    position    = "top-left",
    collapsible = TRUE
  ) |>
  mapgl::add_legend(
    legend_title = "Species",
    values       = species_list,
    colors       = unname(species_colors),
    type         = "categorical",
    position     = "bottom-right"
  )

htmlwidgets::saveWidget(
  m, out_html, selfcontained = TRUE,
  title = "eDNA UNBC 2025 Results — Fraser"
)

# Favicon: rely on browser fallback to apex `/favicon.ico` at the published
# host. No explicit injection here — the apex NGE favicon serves any page
# under newgraphenvironment.com automatically. If/when Fraser publishes to a
# different host, revisit. (See template's edna_unbc_results_explore.R for
# the htmlwidgets preload-scanner gotcha and inline injection workaround.)

cat(sprintf("Wrote map %s  (%d Fraser sites)\n", out_html, nrow(pts)))

# --- Copy to docs/ so the report's map links resolve ------------------------
# `params$report_url` points at the published site, so the map has to exist
# under docs/ as well as data/. Doing it here rather than by hand means a
# rebuilt map can't quietly go stale at the published URL.
if (!dir.exists(dirname(out_html_docs))) {
  dir.create(dirname(out_html_docs), recursive = TRUE)
}
ok_copy <- file.copy(out_html, out_html_docs, overwrite = TRUE)
if (!ok_copy) stop("Failed to copy map to ", out_html_docs)
cat(sprintf("Copied to %s\n", out_html_docs))
