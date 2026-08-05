# Task: Skeena 2025 report — spawn from Fraser 2025, port the thematic appendix set (#1)

## Problem

There is no Skeena 2025 report and no repo for one. `fish_passage_skeena_2025_permit` exists, so the
field season happened; reporting has not started.

The repo is now bootstrapped — branched from `fish_passage_fraser_2025_reporting` main at `7ef34cc`,
public. Every file in it is still Fraser's.

**The season is a monitoring and eDNA season, not an assessment season.** Verified in
`data/backup/2025/sern_skeena_2023/`:

| Form | Records | Detail |
|---|---|---|
| `form_pscis_2025.csv` | **2** | reassessments — 197962 Peacock Ck (Morice FSR), 124421 Waterfall Ck (11th Ave) |
| `form_monitoring_2025.csv` | **2** | the same two crossings |
| `form_fiss_site_2025.csv` | **1** | 197912 Robert Hatch, BULK |
| `form_edna_2025.csv` | **20** | 11 sites, 2025-09-28 → 10-02 |

Outcome: a Skeena 2025 report whose substance is the eDNA program and two effectiveness-monitoring
memos, built from the same pipeline, with no Fraser content surviving.

## Decisions locked

- **Background:** port `0200-background.Rmd` from `fish_passage_skeena_2024_reporting`, reconcile to
  Fraser's conventions. Not a rewrite.
- **NuSEDS:** keep `0700-appendix-stock-assessment.Rmd`, retarget to Skeena waterbodies.
- **`model_species: "st"`**, **`wsg_code: [BULK, MORR, ZYMO, KISP, KLUM]`**.
- **Keep Fraser's commit graph, strip its dead blobs** — BFG at the end of Phase 1, once the purge
  has landed.
- **Archive dirs renamed** with a `fraser-` qualifier.

## Phase 0 — Identity

- [x] `index.Rmd` params: `repo_url`, `report_url`, `repo_name`, `gis_project_name` → `sern_skeena_2023`,
      `project_region` → `skeena`, `model_species` → `st`, `wsg_code` → the five, `project_start_year`
      → `2020`, `pscis_funding_project_number`. Leave `job_name` (already `sern-skeena-fraser`).
- [x] Title block; declare `force_bcfishpass_rebuild` explicitly rather than leaving it implicit
      (`0100-load-bcfishpass-data.R:36,59` reads a param absent from the YAML)
- [x] `_bookdown.yml:1`, `_output.yml:7,9,11`, `README.md`, rename `fish_passage_template_reporting.Rproj`
- [x] `_executive_summary_pdf.Rmd:11-16` — the duplicated params block
- [x] Reset `NEWS.md` (7 Fraser headings, currently 0.3.1) to `0.0.1`; `DESCRIPTION` to match
- [x] Commit the staged `planning/archive/` renames alongside
- [x] **Verify:** `grep -ril fraser *.Rmd _*.yml` — remaining hits are the known prose set only

## Phase 1 — Purge the Fraser payload

- [x] Delete the four `0840-*` site appendices and `0860-appendix-196200-bittner.Rmd` — bookdown has
      no `rmd_files:` list and globs every root `.Rmd`, so leaving them ships Fraser sites
- [x] Delete `data/photos/` (17 Fraser crossing folders), `data/spreadsheets/2025/sern_fraser_2024/`,
      `data/gis/necr_*`, `data/gis/climate_departure_*`, `data/edna_unbc_results_2025_fraser_map.html`,
      `fig/fishpassage_2024_fraser.png`, stale `docs/`
- [x] Delete `data/backup/2025/sern_peace_fwcp_2023/` and `sern_fraser_2024/` — peace#1's finding, that
      every spawned repo carries all three regions. Keep the top-level combined files: `0400-results.Rmd`
      and `0837` filter them by `params$gis_project_name`, so they are live inputs, not bloat.
- [x] Remove `0710-appendix-climate-departure.Rmd` and `0720-appendix-floodplain.Rmd` from the build;
      file follow-up issues (floodplain scoped to **Bulkley only**)
- [x] **Gate:** the build fails loudly on missing Skeena inputs, not silently on Fraser ones

**Then, and only then, strip the history.** Ordering is load-bearing: BFG protects whatever is in
HEAD, so `necr.gpkg` (15.2 MB), `docs/fish_passage_fraser_2025_reporting.pdf` (14.4 MB) and
`fig/fishpassage_2024_fraser.png` (13.8 MB, and its `docs/` copy) must be deleted and committed
*before* the rewrite or they are frozen into history permanently.

- [ ] `bfg --strip-blobs-bigger-than 10M` (installed at `/opt/homebrew/bin/bfg`; precedent —
      `restoration_wedzin_kwa_2024`, 2024-03-18), then `git reflog expire --expire=now --all &&
      git gc --prune=now --aggressive`
- [ ] Confirm HEAD survives intact: `bcfishpass.sqlite` 3.2 MB, `bcfishpass_crossings_vw.parquet`
      5.3 MB, and `data/fishpass_mapping/restoration_wedzin_kwa_mapping.qgs` 9.7 MB all under the
      threshold and protected regardless
- [ ] Force-push. Safe today — one clone, no forks, no collaborators. Re-clone to verify.
- [ ] **Gate:** `.git` under ~20 MB, `git log` still reaches Fraser's history, report still builds

## Phase 2 — Rebuild the data layer  ← PARTIAL, blocked by #5

Tunnel confirmed up on :63333 (host is now 104.248.107.222; it moved since the
notes said 159.203.51.66). Remote model version 133, cached was 122.

- [x] Flip `update_bcfishpass`, rebuild parquet + sqlite against Skeena WSGs —
      2,452 PSCIS crossings, 14,299 modelled crossings
- [x] Re-burn the four field forms — 2 PSCIS, 2 monitoring, 1 fiss_site, 20 eDNA
- [x] `wshd_study_areas` rebuilt to the five Skeena groups
- [x] Species table regenerated with Skeena watershed group columns
- [x] Param-drive `0740-appendix-uav-imagery.Rmd:71` — the hardcode that shipped
      Peace imagery in Fraser (fraser#19)
- [x] Param-drive `0160-photos-import.Rmd` repo path (was hardcoded to the template)
- [x] Column drift characterised: Skeena `form_pscis`/`form_monitoring` carry
      `easting`/`northing` where Fraser carries `utm_easting`/`utm_northing`.
      `fpr_sp_gpkg_backup(update_utm = TRUE)` creates them, so it warns rather
      than fails — forms burned correctly.
- [ ] **BLOCKED** `habitat_confirmation_tracks` = 0 rows — the 2025 GPS tracks are
      untagged and uncleaned for Skeena (#5)
- [ ] **BLOCKED** `wshds` still Fraser's 6 — `0110-load-wshd_stats.R` part 2 assumes
      Phase 2 sites exist and Skeena has none (#5)
- [ ] **BLOCKED** `data/photos/` empty — Skeena photos are untagged eDNA site photos,
      and the amalgamation step aborts on empty folders (#5)
- [ ] **NOT DONE** `project_uav` still holds the inherited Peace rows; the code fix
      is in but re-burning needs the STAC chunk run with network access
- [ ] Not reached: `0140-extract-inputs.R`, `0180-photos-extract-metadata.R`,
      `edna_site_id_fix()` Fraser remaps, `0140:103-106` Fraser 196085 override
- [ ] **Gate NOT met** — `SELECT DISTINCT region FROM project_uav` still returns
      mackenzie

## Phase 3 — Core narrative  ← DONE

- [x] Port `0200-background.Rmd` from Skeena 2024; graft Fraser's region-neutral Approach
      section; derive the study-area sentence from `params$wsg_code`
- [x] Reconcile two citation keys (`data_fish_obs` → `moe2024KnownBC`,
      `officeofthewetsuweten2013Wetsuwet` → `...WetsuwetenTitle`)
- [x] Resolve duplicate chunk labels by pointing the ported stock-assessment and
      fish-species sections at the appendices that now own them
- [x] Skeena branches confirmed firing in `0050`, `0100`, `0300`
- [x] Rewrite `0400-results.Rmd` for a monitoring/eDNA season; drop the climate and
      floodplain rollups (#3, #2); promote eDNA to its own section
- [x] Rewrite `0500-recommendations.Rmd`, grounded in the 2025 data

## Phase 4 — The 2025 content  ← PARTIAL

- [x] `0837-appendix-edna.Rmd` retargeted; `edna_map_fraser.R` renamed and driven off
      `params$gis_project_name`; Fraser-suffixed objects renamed
- [x] `0730-appendix-site-assessment-data.Rmd` derives its watershed groups from params
- [x] `0860-appendix-197962-peacock.Rmd` and `0860-appendix-124421-waterfall.Rmd` — both written.
      The photos were never missing: they were in OneDrive `extra/` (crossing series) and `renamed/`
      (monitoring metrics), untagged, so the `_k_|crossing_all` importer filter skipped them. 2021
      pre-remediation photos came from `fish_passage_skeena_2021_reporting`.
- [x] Monitoring form table in both memos, and UAV orthomosaic viewers via `ngr_str_viewer_cog()`
- [ ] **IN PROGRESS** Site maps — scripts and sidecar CSVs ported from the template, `0110` extended
      to derive watersheds for monitoring sites. Peacock has its watershed (36.3 km2); Waterfall is
      on a first-order stream so fwapgr returns nothing. Prep pull and map chunks outstanding — #9

## Phase 5 — Thematic appendices  ← DONE

- [x] `0700` NuSEDS retargeted in code; stale Fraser extract removed rather than published;
      render gated on region-correct data; regeneration filed as #6
- [x] `0750` hardcoded Peace GIS path — still present, harmless (a commented exploration path)
- [x] `0705`, `0835`, `2000`, `2100`, `2400` — region-neutral, no edits needed

## Phase 6 — Build  ← gitbook DONE, PDF not attempted

- [x] `bookdown::render_book()` gitbook builds clean — 19 chapters
- [x] Rendered prose carries no Fraser-region words (echoed source and the bibliography
      legitimately still do)
- [ ] PDF (`run_pagedown.R`) not attempted
- [ ] NEWS + version bump for a review release

## Cross-repo follow-ups (file, don't fix here)

- [ ] **Fraser 2025** — the published UAV appendix renders Peace imagery. Real defect in a released report.
- [ ] **Skeena 2025** — Bulkley floodplain appendix (prove the `stac_floodplains_bc` route)
- [ ] **Skeena 2025** — climate departure appendix
- [ ] **Peer-repo history sweep** — the same dead sqlite blobs sit in fraser_2025 (168 MB), peace_2025
      (298 MB) and the template (402 MB). File against the template, referencing **template#156** and
      **peace#1**. Riskier there than here: those repos have other clones, so a force-push needs
      coordination. Record what worked on Skeena as the recipe.
- [ ] **Skeena 2025 — harvest the Wedzin Kwa work.** File once the port is done and the report is
      legible. Wedzin Kwa / Neexdzii Kwah **is** the Bulkley, so this is in-study-area:
      `restoration_wedzin_kwa_2024` (public), `restoration_wedzin_kwa_2024_recomendations` (public),
      `wedzin_kwa_chinook` (private), `stewardship_upper_wedzin_kwa` (private). Look for Wet'suwet'en
      background written *with* the Treaty Office, chinook and habitat context for BULK, citations
      already in the NGE bibliography, restoration-priority framing. **Not a rewrite of those
      reports** — a harvest. Two of the four are private and this report is public, so anything drawn
      from them needs a deliberate publishability decision.

## Validation

- [ ] Phase 2's gate: every sqlite table re-burned for Skeena, verified by query not assumption
- [ ] Both output formats render before Phase 6 closes
- [ ] Final grep for every region word across `docs/`
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
