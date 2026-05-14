# Task: Climate departure body section + appendix — FWCP Fraser (#6)

Add a climate-departure analysis for the FWCP Fraser AOI (union of seven watershed groups: **LCHL, NECR, FRAN, MORK, UFRA, TABR, WILL**), wired into the report in the same three-piece pattern that floodplain uses: a Methods paragraph in `0300-methods.Rmd`, a Results paragraph with a hidden inline-R rollup chunk in `0400-results.Rmd`, and a deep appendix `0835-appendix-climate-departure.Rmd`.

The Peace climate-departure work in `fish_passage_peace_2025_reporting#16` is the prose-structure template, but the **interpretation must be written fresh from Fraser numbers** — no Peace narrative bleed-through, no Peace references in the Rmd prose. The Fraser AOI sits at different latitude, elevation, and snowpack baseline; findings will differ in magnitude, spatial pattern, and possibly direction.

Per-sub-region analytical unit is **ecoregion** (climate-physiography zone), not WSG — same as Peace. The seven WSGs define the AOI scope; ecoregions partition the climate gradient inside it. The final piece of the appendix is a WSG × ecoregion crosswalk that bridges the ecoregion-level signal to the per-WSG prioritisation unit the report uses downstream.

The Fraser repo just merged the NECR floodplain appendix (#5 / PR #7, merge `3ab63ba`) — that's the closest convention precedent and the plan mirrors its file structure, naming, db sourcing pattern, table wrapping, and body-paragraph placement.

## Adaptations from the issue body

The issue was drafted before plan-mode exploration. Four filename/path values adapt — the abstract-naming decision below makes every climate-departure script and data filename identical across regional reports, so the same template applies in Fraser, Peace, Skeena, anywhere. The repo path is the AOI label; the filename is the kind of artefact.

| Issue body | Adapted to | Reason |
|------------|------------|--------|
| Appendix `0880-appendix-climate-departure.Rmd` | `0835-appendix-climate-departure.Rmd` | Next slot after `0830-appendix-floodplain.Rmd` |
| Snapshot at `scripts/cd_inputs_snapshot.R` | `scripts/gis/climate_departure.R` | Mirrors `scripts/gis/floodplain.R` location |
| Anchor `{#app-climate-departure}` | `{-#app-climate-departure}` | Matches `{-#app-floodplain}` (dash suppresses numbering) |
| Data prefix `cd_fraser_*` | `climate_departure*` (no AOI prefix) | Repo path says "Fraser"; AOI-neutral filenames make the script + appendix portable across regional reports |

## Phase 1 — Snapshot script: AOI, context, ecoregions

- [x] Verify `cd` >= 0.3.0 installed (`packageVersion("cd")`)
- [x] Scaffold `scripts/gis/climate_departure.R` header with WSG codes, db connection helper (mirroring `scripts/gis/floodplain.R` lines 1–47)
- [x] Build AOI = dissolved union of the 7 WSG polygons via `fresh::frs_db_conn()` + `whse_basemapping.fwa_watershed_groups_poly` query — 34,019 km² total
- [x] Source ecoregions intersecting the AOI bbox via `bcdata::bcdc_query_geodata("d00389e0-66da-4895-bd56-39a0dd64aa78")` (ecoregions are NOT in fwapg; same pattern Peace uses). 8 ecoregions returned: FAB, FAP, WRA, NCM, SRT, COH, CRM, EHM
- [x] Source context layers (towns, lakes, rivers, streams, highways) cropped to AOI bbox via fwapg. 5 of 8 town candidates found; 56 lakes >1000 ha; 339 named river polygons; 2,098 stream segments (order ≥ 7); 2,390 highway segments
- [x] Write all to `data/gis/climate_departure.gpkg` (multi-layer, 1.4 MB)
- [x] Atomic commit: "Snapshot script — AOI + context + ecoregions for climate departure (#6)"

## Phase 2 — Snapshot script: cd pipeline run

- [x] Run `cd::cd_catalog()` + `cd::cd_extract()` on AOI to produce regional ts (4,484 rows across 15 variables × periods)
- [x] Run `cd::cd_baseline()` + `cd::cd_anomaly()` + `cd::cd_trend()` + `cd::cd_compare()` on AOI → regional outputs (cmp 59 rows mean_diff, cmp_pct 25 rows pct_change for pct_normal vars)
- [x] Loop per ecoregion (intersect each ecoregion polygon with AOI, then run the full pipeline) — 8 ecoregions ordered by area: FAB, FAP, WRA, NCM, SRT, COH, CRM, EHM
- [x] Build spatial tmean departure raster: `cd::cd_crop()` the tmean annual COG to AOI, `terra::app(..., fun = "mean")` for 2015–2025 minus 1951–1980, `terra::mask()` to AOI — range +1.10 to +2.02 °C across 627 non-NA cells. (Used `terra::app()` instead of `mean()` — `mean(SpatRaster)` doesn't S4-dispatch reliably across terra versions.)
- [x] Compute WSG × ecoregion percentage table — 7 WSGs, with MORK straddling 6 ecoregions (Rocky Mountain mixed), FRAN/NECR/TABR dominantly FAB+FAP, UFRA dominantly WRA+NCM (Rockies), WILL dominantly COH
- [x] Save: `data/gis/climate_departure.rds` (403 KB), `data/gis/climate_departure_tmean.tif` (4 KB compressed), `data/gis/climate_departure_wsg_ecoregion.csv` (487 B)
- [x] Write snapshot manifest entry (file sha + cd version + run date) → `data/climate_departure_inputs_snapshot_manifest.txt`
- [x] Atomic commit: "Snapshot script — cd pipeline outputs for Fraser climate departure (#6)"

## Phase 3 — Appendix draft (0835-appendix-climate-departure.Rmd)

Mirror the Peace appendix structure (`cd/hold/9999-appendix-climate-departure.Rmd`) section-by-section but with all interpretation written fresh from Fraser numbers. **Look at the data before writing each narrative paragraph** — see Fresh-interpretation section in findings.md.

- [x] YAML header + setup + `cd-load` chunk reading `data/gis/climate_departure.{gpkg,rds,tif,csv}` (all paths under `data/gis/`, no `system.file()`)
- [x] `# Appendix - Climate Departure {-#app-climate-departure}`
- [x] "Climate departure and fish passage" — framing paragraph (cold-water salmonid habitat both ways)
- [x] AOI section + AOI map (`fig:cd-map-aoi`) with ecoregion fill + 7 WSGs outlined + context layers
- [x] Recent decade vs pre-warming table (15 variables, Δ p windows + Trend p) — direct `kableExtra::kable_styling() |> kableExtra::scroll_box()` (Peace pattern, no gitbook_on conditional)
- [x] Trends section: `cd_summary` table + tmean annual anomaly plot + prcp annual anomaly plot. **Added note: 45-yr trend slopes are SHALLOWER than 75-yr (Fraser warming has not accelerated since 1981) — fresh finding from the data, not in Peace's narrative**
- [x] Day-night asymmetry: tmax + tmin + DTR plots; narrative reflects Fraser tmax (+1.46) vs tmin (+1.78) — asymmetry present, modest (~one-third Karl-et-al global scale)
- [x] Snowpack section: seasonal table + 4 derived snow plots; 3 paragraphs from Fraser numbers — "snow leaving earlier not falling less", "melt shifting earlier on both ends" (highlights winter snowmelt +45 % alongside spring +18 % — a Fraser-specific signal Peace didn't carry), "summer SWE collapse −52 %"
- [x] Spatial pattern map + gradient narrative: NW-warm to SE-cool (r = −0.90 longitude, +0.75 latitude) — interior plateau warmed ~0.5 °C MORE than eastern Rockies; the mountains acted as a thermal buffer
- [x] Per-ecoregion variation: tmean / prcp / swe_max / doy_50 facets (8 panels each, ncol = 3) + per-ecoregion rollup table. Narrative: ALL 8 ecoregions show tmean p < 0.001; **ZERO show significant prcp trend** (different from Peace where 2/5 did); VPD significant in every ecoregion; DOY-50 significant in every ecoregion
- [x] WSG × ecoregion rollup: 7-WSG map + percentage crosswalk table. MORK noted as spanning 6 ecoregions
- [x] Interpretation for fish passage: 4 findings synthesized from Fraser numbers, with both-ways framing on cold-limited vs near-upper-thermal reaches mapped onto the 7 WSGs via the ecoregion crosswalk (interior-plateau WSGs warmest + likely closer to upper thermal niche; mountain WSGs cooler + likely cold-limited)
- [x] Atomic commit: "Climate departure appendix — Fraser (#6)"

## Phase 4 — Body wiring

- [x] Add `## Climate Departure` section to `0300-methods.Rmd` at top level (peer to `## Collaborative GIS Environment` etc., mirroring Peace's placement at line 16). Three-paragraph structure: audience intro + 15-variable scope + technical pipeline. Closes with `[Appendix - Climate Departure](#app-climate-departure)` pointer.
- [x] Add hidden `cd-rollup-body` chunk + `## Climate Departure` section to `0400-results.Rmd` between `## Site Assessment Data` and `## Collaborative GIS Environment` (mirrors Peace's placement). Chunk loads `data/gis/climate_departure.rds` and computes 11 headline scalars; the prose has 4 bolded-lead findings + closing both-ways framing.
- [x] Verified inline-R values resolve cleanly: 1.6 / 1.5 / 1.8 °C; VPD +0.34 hPa; prcp +3 %, SWE -10 %, snowfall -6 %; summer SWE -52 %, winter snowmelt +45 %, spring snowmelt +18 %; midpoint 12 days earlier; DTR -0.3 °C
- [x] Atomic commit: "Wire climate departure Methods + Results into body (#6)"

## Phase 5 — Render verification

- [x] Render gitbook locally — all 21 appendix chunks executed without R errors; figures 5.16–5.31 numbered correctly; body→appendix cross-refs resolve in HTML; all 8 cite keys (Karl, Hansen, Mote ×2, Stewart, Cayan, Knowles, Kang) resolve in the bibliography (entries manually added to `references.bib` since rbbt regen pipeline is offline pending cleanup). Render command: `Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); bookdown::render_book("index.Rmd", "bookdown::gitbook")'` — needed the explicit CRAN mirror because `scripts/packages.R` calls `available.packages()` early
- [ ] ~~Render PDF locally~~ → **deferred to PR CI**. The Peace report's `0820-appendix-climate-departure.Rmd` ships the same direct `kableExtra::kable_styling() |> kableExtra::scroll_box()` pattern and its PDF build worked; same pattern is in the Fraser draft so PDF behaviour should match. If CI flags a regression, drop back into Phase 5 to fix.
- [x] Inline-R headline numbers resolve: "warmed about 1.6 °C since", "rose 0.34 hPa", "snowmelt midpoint shifted 12 days" all confirmed in `docs/results-and-discussion.html`
- [x] Chunk labels are all `cd-*` prefixed in the appendix and don't collide with floodplain's `flood-*` labels
- [x] Atomic commit: "Render verification — gitbook clean + 8 cite entries to references.bib (#6)"

## Phase 6 — Independent review (gating)

- [ ] Spawn a fresh Explore + Plan agent (no inherited context) with a self-contained prompt: review the draft Methods paragraph, Results paragraph + rollup chunk, and appendix Rmd against the cached `data/gis/climate_departure.{rds,tif,csv}` data
- [ ] Reviewer checks: numerical accuracy (recompute spot-check values from the rds), pattern accuracy (does the spatial-pattern narrative match the actual raster?), significance handling (no over-claiming), tone and completeness (plain language, fish-passage relevant, no package-tutorial bleed), stand-alone framing (no Peace references in prose), cross-references and structure
- [ ] Reviewer writes findings to `planning/active/review-climate-departure.md` with line-level callouts: file + line + what's wrong + suggested fix
- [ ] Implementation pass addresses each finding (separate commits for substantive prose/data fixes; trivial wording fixes can batch)
- [ ] Reviewer re-checks the addressed findings and signs off (appends "Sign-off" section to the review file)
- [ ] Atomic commit: "Address review findings (#6)" (or per-finding commits if substantial)

## Phase 7 — PR + merge

- [ ] `/gh-pr-push` to create the PR (PR body summarises the three pieces + lists the reviewer sign-off file path)
- [ ] Watch CI — gitbook + PDF render workflows
- [ ] `/gh-pr-merge`
- [ ] `/planning-archive`

## Validation

- [ ] `Rscript scripts/gis/climate_departure.R` runs end-to-end and produces the four files in `data/gis/` plus the manifest entry
- [ ] Tests / code-check clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] No `system.file()` calls in the new files; no `cd::cd_compare()` calls passing explicit windows; no references to the Peace report in the Rmd prose
- [ ] Reviewer sign-off present in `planning/active/review-climate-departure.md`
- [ ] `/planning-archive` on completion
