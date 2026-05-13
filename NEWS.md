# fish_passage_fraser_2025_reporting 0.2.0 (2026-05-13)

* Add climate-departure appendix for the FWCP Fraser AOI (union of 7 watershed groups: LCHL, NECR, FRAN, MORK, UFRA, TABR, WILL). Snapshot script `scripts/gis/climate_departure.R` builds AOI + 8 ecoregions and runs the `cd` pipeline; appendix `0835-appendix-climate-departure.Rmd` with recent-vs-pre-warming, trend, day-night, snowpack, spatial-pattern, per-ecoregion, and WSG×ecoregion sections; body methods/results paragraphs with inline metrics. Filenames are AOI-neutral for portability across regional reports.

# fish_passage_fraser_2025_reporting 0.1.0 (2026-05-13)

* Add floodplain delineation appendix for Nechako River Watershed Group (NECR) using chinook accessible stream network. Build script, appendix with summary table and maps, body methods/results paragraphs with inline metrics. Rename Planning section header.

# fish_passage_fraser_2025_reporting 0.0.2 (2026-05-11)

* Add standalone PDF executive summary: `_executive_summary_pdf.Rmd` wrapper, `scripts/build_exec_pdf.R`, PDF download link in gitbook chapter. Strip `[@citekey]` refs from previous-work lists; fix hardcoded PDF name to derive from `_bookdown.yml`.

# fish_passage_reporting_template 0.0.1

- *2025-02-13*  
  - Added 2025 data process scripts (01_prep_inputs).
  - Added of 2025 reporting scripts (02_reporting).
  - Added 2024 Peace data so report builds
  - Updated script readmes



