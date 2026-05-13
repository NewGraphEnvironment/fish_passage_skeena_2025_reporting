# Findings — Climate departure body section + appendix — FWCP Fraser (#6)

## Issue context

Apply the climate-departure template to the FWCP Fraser AOI. Three pieces — Methods paragraph in `0300-methods.Rmd`, Results paragraph (with hidden inline-R rollup chunk) in `0400-results.Rmd`, deep appendix `0835-appendix-climate-departure.Rmd`. The Peace work is the structure template; the Fraser interpretation is written fresh.

**Primary tone reference — the Peace REPORT (PR #17 merged 2026-05-12), not the `cd/hold/` drafts:**
- `fish_passage_peace_2025_reporting/0820-appendix-climate-departure.Rmd` (742 lines) — the landed appendix; mirror section structure, chunk-label convention (`cd-*`), prose tone, plot recipes
- `fish_passage_peace_2025_reporting/0300-methods.Rmd` lines 16–22 — Methods uses a **two-paragraph** structure: first paragraph is a plain-language audience-translation intro ("Climate departure measures how far recent climate has shifted from a historical baseline…"), second paragraph is the technical pipeline summary
- `fish_passage_peace_2025_reporting/0400-results.Rmd` lines 121–153 — hidden `cd-rollup-body` chunk + 4-finding Results paragraph with bolded leads + closing both-ways fish-passage framing

Secondary reference (structural draft, lower-priority tone source — written for `cd` package learners, not the FWCP audience):
- `cd/hold/main-body-climate-departure.Rmd`
- `cd/hold/9999-appendix-climate-departure.Rmd`
- `cd/hold/render_preview.Rmd`

## Conventions discovered (Fraser repo)

### Appendix file pattern (mirror NECR floodplain #5 / PR #7)

- Path: `0835-appendix-climate-departure.Rmd` (next slot after `0830-appendix-floodplain.Rmd`)
- YAML: `output: html_document` plus `editor_options: chunk_output_type: console`
- Heading + anchor: `# Appendix - Climate Departure {-#app-climate-departure}` (the leading dash on `{-#…}` suppresses section numbering)
- Setup chunk hidden via `include = FALSE` carries `library()` calls
- Data-load chunk visible (no `include = FALSE`), uses paths under `data/gis/...` — no `system.file()`

### Body Methods placement

Mirror the **Peace report's** two-paragraph Methods pattern at `fish_passage_peace_2025_reporting/0300-methods.Rmd` lines 16–22:

1. **First paragraph** — audience-translation intro. Plain language; no `cd` package name, no `ERA5-Land`, no Mann-Kendall. Explain *what* climate departure is (how far recent climate has shifted from baseline) and *why it matters for fish passage* (warming water, snowpack timing, atmospheric drying changing the context that crossings sit inside). One paragraph.
2. **Second paragraph** — technical pipeline summary. `cd` package, ERA5-Land hourly reanalysis, 1951–1980 reference, Mann-Kendall + Theil-Sen + Welch t. End with the cross-reference link `[Appendix - Climate Departure](#app-climate-departure)`.

In the Fraser repo, place this as a `## Climate Departure` section at the top level (peer to other Methods sections like `## Fish Passage Assessments`), **not nested** under `## Planning — Habitat, Connectivity and Floodplain Modelling`. The Peace report put it at `##` level (line 16); follow that placement.

### Body Results placement

Mirror **Peace's** Results pattern at `fish_passage_peace_2025_reporting/0400-results.Rmd` lines 121–153:

- Hidden chunk `cd-rollup-body` (`include = FALSE`) loads `data/gis/climate_departure.rds`, extracts `cmp`, `cmp_pct`, `trn` from `regional`, defines a small `pick()` helper, and computes headline scalars: `tmean_d`, `tmax_d`, `tmin_d`, `vpd_d`, `prcp_p`, `swe_p`, `snowfall_p`, `summer_swe_p`, `spring_melt_p`, `doy50_d`
- `## Climate Departure` section heading
- One-line intro: "Four findings from the regional climate-departure analysis carry to fish-passage prioritisation."
- Four bolded-lead findings: `**Warming is broad...** … **The atmosphere is drying...** … **The snowpack signal is about timing...** … **Day-night asymmetry is present.** …` — each finding 1 lead sentence + 1–2 substantiation sentences, all headline numbers via inline R from the scalars above
- Closing paragraph: the both-ways fish-passage framing (cold-limited reaches gain growing-degree-days vs near-upper-thermal reaches lose habitat), with `[Appendix - Climate Departure](#app-climate-departure)` cross-reference

The wording of each finding gets rewritten from the actual Fraser numbers — Peace's findings (1.8 °C warming, north-only precip increase, summer SWE collapse, day-night asymmetry) are not the Fraser findings. See Fresh-interpretation discipline below.

### Snapshot script pattern

`scripts/gis/floodplain.R` is the precedent. Same location for climate departure: `scripts/gis/climate_departure.R`. WSG polygons sourced via `fresh::frs_db_conn()` + `whse_basemapping.fwa_watershed_groups_poly` query. Multi-layer geopackage output to `data/gis/`. Manifest entry written to (TBD — confirm during Phase 1 — likely `data/cd_inputs_snapshot_manifest.txt` or equivalent; mirror what floodplain did).

### Table wrapping

The earlier plan-mode Explore note about `fpr::fpr_kable(scroll = gitbook_on)` being the appendix convention was wrong — that pattern appears in body files (`0200-background.Rmd`, `0300-methods.Rmd`) but **not** in appendices. The Peace appendix `0820-appendix-climate-departure.Rmd` uses direct `kableExtra::kable_styling() |> kableExtra::scroll_box()` with no conditional, and the Fraser floodplain appendix `0830-appendix-floodplain.Rmd` uses plain `knitr::kable()` (its tables are short).

Decision: mirror **Peace's** pattern in the climate-departure appendix —

```r
kableExtra::kable_styling(
  knitr::kable(df, label = NA, row.names = FALSE,
    caption = "..."),
  bootstrap_options = c("striped", "hover", "condensed")
) |>
  kableExtra::scroll_box(height = "420px")
```

Both Fraser and Peace ship `bookdown::pdf_book` in `_output.yml`; Peace's PDF build clearly survived this raw pattern (PR #17 merged). If PDF rendering surfaces an issue in Phase 5, fall back to conditional wrapping then — don't pre-engineer for it.

### Bibliography

rbbt-driven via `params$update_bib` in `index.Rmd` line 64. When the parameter is TRUE the build regenerates `references.bib` from `rbbt::bbt_write_bib()`. No manual bib management in this PR — cite keys land in the prose, rbbt does the rest as long as Zotero is running with Better BibTeX enabled.

### Filename abstraction — deliberate divergence from Peace

Peace report shipped with `cd_peace_*` prefixed data filenames (`data/gis/cd_peace.gpkg`, `cd_peace.rds`, `cd_peace_departure_tmean.tif`). The user asked for abstract names after Peace landed, on the principle that the repo path already identifies the AOI and AOI-neutral filenames make the script + appendix portable across regional reports.

Fraser is the first report using the abstract convention:

- `scripts/gis/climate_departure.R`
- `data/gis/climate_departure.gpkg` (multi-layer: aoi, wsgs, ecoregions, towns, lakes, rivers, streams, highways)
- `data/gis/climate_departure.rds` (named list: `regional` + `ecoregion` keyed list)
- `data/gis/climate_departure_tmean.tif`
- `data/gis/climate_departure_wsg_ecoregion.csv`

Peace can be retrofitted to match later if desired; that's out of scope for this PR.

## Fresh-interpretation discipline

Load-bearing: before writing **any** narrative paragraph, look at the data.

- **Trends table:** every slope, every MK p-value, every Welch p-value, every recent-vs-baseline percent change. Note which signals are significant and which are not, where the significance threshold cuts.
- **Spatial map:** the actual gradient pattern. Where is warming largest? Smallest? East-west? South-north? Elevation-stratified? Don't assume it mirrors Peace.
- **Per-ecoregion facets:** which ecoregions sit at extremes for tmean, prcp, swe_max, doy_50. Which cluster, which diverge.
- **WSG × ecoregion crosswalk:** which of the 7 WSGs sit cleanly in one ecoregion vs straddle multiple. Map the ecoregion climate signal onto each WSG.
- **Snowpack seasonal table:** the summer-SWE / spring-snowmelt redistribution may not be the dominant signal here. Read what is.
- **Day-night asymmetry:** same direction as Peace? Same magnitude? Different?

If a Peace finding doesn't hold in Fraser, drop it. If a finding shows up in Fraser that wasn't visible in Peace, write it in. No Peace references in the Rmd prose.

## Risks and mitigations

1. **Ecoregion source table unknown.** Try PostgreSQL `whse_terrestrial_ecology.erc_ecoregions_sp` first; fall back to `bcdata::bcdc_get_data("ecoregions-ecoregion-boundaries")` (or equivalent slug) if the db query fails. Document the working source in `scripts/gis/climate_departure.R` header.
2. **cd pipeline runtime.** Running `cd_extract` per-ecoregion (4–6 ecoregions likely) means multiple full STAC fetches. Run once during Phase 2, cache to `data/gis/climate_departure.rds`. Same pattern Peace uses.
3. **Reviewer surfaces a load-bearing accuracy issue late.** Phase 6 review is gating — do not merge until findings are addressed. Substantial issues may bounce back into Phase 3 or Phase 2.
4. **PDF table rendering regressions.** Phase 5 renders PDF locally before opening the PR. Every table chunk uses `fpr::fpr_kable(scroll = gitbook_on)`.
