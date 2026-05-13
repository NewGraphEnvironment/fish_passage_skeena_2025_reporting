# Task: Add floodplain delineation appendix for Nechako River watershed group (#5)

The Nechako River (NECR) watershed group in the Fraser report needs a floodplain delineation appendix replicating the Parsnip (PARS) implementation from Peace PR #15 / v0.2.0. Three pieces: build script, appendix Rmd, and body methods/results paragraphs. Key differences from Peace: NECR uses `streams_ch_vw` (chinook accessible stream network, not bull trout) and the detail map focal point is the confluence of Murray Creek and the Nechako River (Vanderhoof at bottom right).

## Phase 1 — Build script + generate data

- [x] Create `scripts/gis/` directory
- [x] Port `scripts/gis/floodplain.R` from Peace, changing `wsg <- "PARS"` to `wsg <- "NECR"` and `species_view <- "streams_bt_vw"` to `species_view <- "streams_ch_vw"`
- [x] Verify `flooded` is installed: `packageVersion("flooded")` — v0.3.0
- [x] Run build script to populate `data/gis/necr*` files (requires DB connection via SSH tunnel)
- [x] Verify: `ogrinfo data/gis/necr.gpkg` lists expected layers — 9 layers, 18.6 MB total

## Phase 2 — Port the appendix

- [x] Copy Peace `0830-appendix-floodplain.Rmd` → Fraser `0830-appendix-floodplain.Rmd`
- [x] Update data paths: `pars.gpkg` → `necr.gpkg`, `pars_dem.tif` → `necr_dem.tif`, `pars_valleys.tif` → `necr_valleys.tif`
- [x] Update narrative: "Parsnip River Watershed Group" → "Nechako River Watershed Group", "bull trout" → "chinook" throughout
- [x] Update detail map focus area: confluence of Murray Creek and Nechako River — bbox captures upstream section of Murray Creek with the confluence, and Vanderhoof at bottom right
- [x] Keep heading: `# Appendix - Floodplain Delineation {-#app-floodplain}` (no bold)
- [x] Ensure `{-}` on all sub-headings

## Phase 3 — Body methods + results

- [x] Add `### Floodplain Delineation` methods paragraph in `0300-methods.Rmd` under `## Planning` after Habitat Modelling
- [x] Add `flood-rollup-body` quiet chunk + `### Floodplain Delineation` results paragraph in `0400-results.Rmd`
- [x] Rename `## Planning` → `## Planning — Habitat, Connectivity and Floodplain Modelling` in both methods and results

## Phase 4 — Version bump + build

- [x] Bump DESCRIPTION version (0.0.2 → 0.1.0)
- [x] Add NEWS.md entry
- [ ] Full `bookdown::render_book()` build
- [ ] Verify appendix renders with summary table and maps
- [ ] Verify cross-refs from body link to appendix
- [ ] Verify inline R values render as formatted numbers

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
