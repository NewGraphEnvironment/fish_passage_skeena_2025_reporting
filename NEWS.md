# fish_passage_fraser_2025_reporting 0.3.0 (2026-08-02)

* Integrate the 2025 UNBC environmental DNA results — 33 real environmental samples, 2 field blanks and 3 office blanks across the region, with 36 of 146 site-by-target combinations returning confirmed detections. Adds a per-species summary to Results, a thematic appendix, per-site detection tables in every site appendix, and an interactive map scoped to the region. Corrects three samples recorded against the wrong crossing.
* Rewrite the Recommendations chapter for the Fraser region. It carried the Peace region's recommendations unedited, referencing the FWCP Peace Region, McLeod Lake, Fern Creek and Arctic grayling. Restructured into named thematic subsections led by effectiveness monitoring, and replaces the "rankings are inherently subjective" framing with the reasoning behind it. The executive summary's looking-ahead bullets are aligned to match.
* Add a Bittner Creek monitoring appendix documenting three years of evidence that disagree — a landowner reporting no salmon in thirty years, eight juvenile chinook salvaged in 2023, and no eDNA detections in 2025 — and the two upstream constraints still unaddressed.
* Move amalgamated data tables out of the body into thematic appendices: Assessment Data Summary, Fish Species, UAV Imagery and Collaborative GIS Layers. Results drops from 799 to 634 lines and Background from 626 to 601.
* Order the appendices by first body reference, matching the Peace report's tiering, and add named links to the four per-site appendices, which previously had no inbound reference at all.
* Wire the First Nations background into the report as its own section, restoring nine citations that were invisible while the block was commented out.
* Split the build into `run_gitbook.R` and `run_pagedown.R`, fixing a bug where the gitbook shipped the Phase 1 appendix twice, and setting a CRAN mirror so non-interactive builds work at all.
* Read `fp_sites_tracking` from a committed parquet snapshot rather than querying postgres, so the report builds from a fresh clone with no database access.
* Derive scope statements from the data rather than restating them in prose — the fish-species caption from the cached table's own columns, and the climate-departure extent from the analysis geopackage.
* Fix six inline expressions using `cat()`, which returned NULL and dropped the project year from the rendered text entirely.
* Remove placeholder text from the acknowledgement, which was publishing `[Nations]` and two further bracketed placeholders.
* Migrate citation keys to xciter's canonical bibliography — the last repo in the family still carrying the per-profile "title-words" keys.
* Correct the report version on the title page, which read 0.0.1 through two releases.
* Fix Table 4.5, Summary of Phase 2 habitat confirmation details, which has been rendering with no data rows. `stringr::str_like()` became case sensitive in stringr 1.5.0, so a filter looking for lowercase 'upstream' stopped matching the "Upstream" values the table is built from. Adds a total for the surveyed length and states in the caption that the lengths are upstream reaches only, since the table totals 3,140 m while the text total of 4.3 km includes downstream reaches.
* Correct the stated extent of the habitat confirmation work. The text claimed assessments were completed across all eight project watershed groups; they were completed in Tabor River and Willow River. The site count, watershed groups and surveyed length are now derived in `0130-tables.R` so the executive summary and results chapter cannot disagree. The surveyed total previously used `round(-3)/1000`, reporting 4,280 m as "approximately 4 km" and anything under 500 m as 0 km.
* Move the Fisheries and Oceans Canada stock assessment data to its own appendix. At 1,486 rows and 51 columns it is a wide reference table rather than background prose, and being gated on `gitbook_on` it left print readers with a reference to a table that was not there. The print version now points at the appendix online.
* Note in the environmental DNA sections that non-detections from samples without reported amplification controls are not evidence of absence. Detections are unaffected. Adds recommendations at Bittner Creek for resampling with rainbow trout on the assay panel, triplicate sampling as a method test, and confirming with the laboratory whether the control results exist.
* Regenerate `references.bib` from Zotero rather than hand-editing it, and set `update_bib` back to TRUE.
* Update the model named in the assistance note to Claude Opus 5.
* Credit the Habitat Conservation Trust Foundation. The title block now names HCTF with the project number CAT26-0-636 alongside the Ministry of Transportation and Infrastructure, and the header carries the combined SERNbc and HCTF logo used in the Skeena reporting.
* Set out the funding history in the introduction and executive summary: the 2023 work was supported internally by SERNbc and through the Ministry of Transportation and Infrastructure and produced the region's 2023 report, while the project is now also supported by HCTF alongside Skeena fish passage restoration planning as the Northern British Columbia Fish Passage Restoration project (CAT26-0-636). Corrects "Morkhill" to Morkill.
* Derive the print version's PDF filename rather than hardcoding it. The introduction pointed print readers at `fish_passage_peace_2024_reporting.pdf`, a file from a different region's repository.

# fish_passage_fraser_2025_reporting 0.2.1 (2026-05-14)

* Add `update_bcfishpass` YAML switch for build portability and post-release freezing — three refresh triggers (YAML flip, missing version file, or `force_bcfishpass_rebuild`); otherwise builds read cached files with no DB connection. Migrate `bcfishpass_crossings_vw` from sqlite to parquet (zstd-9; sqlite shrunk substantially). Source `0100-load-bcfishpass-data.R` from `index.Rmd` so the switch affects builds. Ports the pattern from Peace v0.5.1 and template v0.2.0 ([Issue #186 in template](https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/186))

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



