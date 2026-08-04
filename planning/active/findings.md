# Findings — Skeena 2025 report (#1)

## The pipeline is parameterised, but the cache defeats it silently

`scripts/02_reporting/0100-load-bcfishpass-data.R` builds every SQL pull from `params$wsg_code`
(lines 70–78, 115–125) and guards on it (lines 8–10). Form paths come off `params$gis_project_name`
(`0130-tables.R:8,17,26,35`). The eDNA region filter is `grepl(params$gis_project_name, source)`
(`0400-results.Rmd:533`, `0837:26`) against a file holding all three regions — 146 Fraser, 128 Peace,
80 Skeena rows.

**But** lines 34–63 skip the rebuild entirely unless `update_bcfishpass: TRUE`, the version file is
missing, or `force_bcfishpass_rebuild` is set. **Changing `wsg_code` alone does nothing.**

## Spawned repos inherit stale sqlite tables and publish them

Confirmed, not theorised. Fraser 2025 v0.3.1's published `docs/app-uav.html` renders **Peace**
imagery:

```
region    watershed_group  year  item
mackenzie parsnip          2023  125231_table_trib_tablefsr_21k
mackenzie parsnip          2022  125000_parsnip_trib_arctic
mackenzie carp             2024  198692_kerry_lake_trib
```

18 rows, all Parsnip and Carp. `0740-appendix-uav-imagery.Rmd:71` hardcodes
`project_region <- "skeena"`, shadowing the param, in a chunk marked `eval = F`; the rendering chunk
reads `project_uav` from the committed sqlite, which Peace burned before Fraser was spawned and
Fraser never re-burned.

Five sqlite tables are written by scripts `index.Rmd` never sources — `rd_class_surface`,
`photo_metadata`, `project_uav`, `wshd_study_areas`, `wshds`. Each is a repeat of this waiting to
happen.

## Column drift between regions

| File | Skeena | Fraser / Peace |
|---|---|---|
| `form_pscis_2025.csv` | 100 cols | 101 (Skeena lacks `assessment_comments_og`) |
| `form_monitoring_2025.csv` | 122 cols | 127 |
| `form_fiss_site_2025.csv` | 162 | 162 |
| `form_edna_2025.csv` | 62 | 62 |

Anything that rbinds across regions, or names those columns unconditionally, breaks on Skeena only.

## Region hardcoding distribution

312 region-word occurrences across 26 root `.Rmd` files. **125 (40%) are in `0200-background.Rmd`
alone.** Seven files need zero edits (`0705`, `0740`, `0750`, `0835`, `2000`, `2100`, `2400`).
Six files (~1,700 lines) need full replacement: the four `0840-*`, `0860-*`, `0500-recommendations`.

`0050`, `0100` and `0300` already contain **written Skeena branches** in `params$project_region`
`case_when`/`if-else` blocks, including fish-collection permit numbers and species lists. Flipping
one param activates them.

## Skeena 2024 as the background source

Skeena 2024 (`fish_passage_skeena_2024_reporting`) has **no** eDNA appendix and **no** standalone
monitoring memo — monitoring was inline prose in `0400-results.Rmd` plus one site appendix
(`0800-appendix-197967-taman.Rmd`). It uses the older `0050/0600/0800-*` numbering.

But its `0200-background.Rmd` (534 lines) already carries Wet'suwet'en, Gitxsan, Tsimshian and the
Bulkley River. Its params: `gis_project_name: "sern_skeena_2023"`, `model_species: "st"`,
`project_region` absent from params (hardcoded at `0400-results.Rmd:367`).

Watershed groups, hardcoded in three places in 2024: `c('BULK', 'MORR', 'ZYMO', 'KISP', 'KLUM')`.

## Repo weight — the 76 MB warning was a historical blob

The content fix already landed: `crossings_vw` (33K rows) lives in
`data/bcfishpass_crossings_vw.parquet` (5.3 MB), and `fp_sites_tracking` in a committed parquet
snapshot (peace#10, closed). Worktree sqlite is **3.2 MB**, largest table `pscis_assessment_svw` at
1,314 rows.

History was never fixed. `git rev-list --objects --all`: 78.3 MB + 76.4 MB ×3 + 19.8 MB ×11 of dead
`data/bcfishpass.sqlite` blobs, inherited from Fraser.

| Repo | `.git` | worktree `data/` |
|---|---|---|
| skeena_2025 (created today) | 145 M | 63 M |
| fraser_2025 | 168 M | 63 M |
| peace_2025 | 298 M | 155 M |
| template | 402 M | 3.8 G |

Still open upstream: **template#156** (eliminate sqlite bloat — four architecture options, never
decided) and **peace#1** (every repo's `data/backup/2025/` carries all three regions).

BFG is installed at `/opt/homebrew/bin/bfg`; precedent is `restoration_wedzin_kwa_2024`, 2024-03-18.
`git-filter-repo` is not installed.

**Ordering is load-bearing.** BFG protects HEAD, so these must be deleted and committed *before* the
rewrite or they are frozen in permanently:

```
15.2 MB  data/gis/necr.gpkg
14.4 MB  docs/fish_passage_fraser_2025_reporting.pdf
13.8 MB  fig/fishpassage_2024_fraser.png  (and its docs/ copy)
```

## Inherited PWF archives collided with Skeena's issue numbering

The spawn carried Fraser's `planning/archive/` — issues #5, #6, #10. Skeena's numbering restarted at
#1, so those directory names would eventually point at the wrong repo's issues. Renamed with a
`fraser-` qualifier. The ~60 bare `#N` references *inside* those archived files were left alone —
rewriting archived records is worse than the ambiguity, and the parent directory name now
disambiguates.
