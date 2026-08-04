# Findings — Add floodplain delineation appendix for Nechako River watershed group (#5)

## Issue context

The Parsnip River Watershed Group in the Peace report has a floodplain delineation appendix (ported from the `flooded` package) showing modelled functional floodplain extent, lateral connectivity metrics, and per-watershed mapping. The Nechako River (NECR) watershed group in the Fraser report needs the same treatment.

Following the Peace `#14` pattern:
1. Create `scripts/gis/floodplain.R` build script using `flooded` to delineate floodplain for the NECR watershed group (chinook accessible stream network, order >= 3, `ff04` functional floodplain scenario)
2. Cache outputs to `data/gis/` (floodplain raster, summary stats)
3. Port `0830-appendix-floodplain.Rmd` from Peace, adapting data paths and narrative for NECR
4. Add methods and results paragraphs in main body under Planning — Habitat, Connectivity and Floodplain Modelling
5. `flooded` is build-script only — NOT needed at render time

Reference implementation: `fish_passage_peace_2025_reporting` PR #15 / v0.2.0, archived at `planning/archive/2026-05-issue-14-floodplain-appendix/`

## Key differences from Peace

- Watershed group code: `PARS` → `NECR`
- Species view: `streams_bt_vw` → `streams_ch_vw` (chinook, not bull trout)
- Detail map focal point: confluence of Murray Creek and Nechako River (Vanderhoof at bottom right), replacing Peace's south-east detail near Arctic Lake
