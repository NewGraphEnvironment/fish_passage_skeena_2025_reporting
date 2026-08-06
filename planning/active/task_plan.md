# Task: Floodplain appendix — Bulkley only, pulled from stac_floodplains_bc (#2)

## Problem

The report has no floodplain appendix. Fraser 2025 carried one scoped to the Nechako River watershed
group; it was removed on spawn because none of it applies here. Meanwhile the report body already
promises the layer — `0200-background.Rmd:28` lists "floodplain extent" among the layers this report
compiles.

## Correction to the issue body

The issue states that `stac_floodplains_bc` is scaffolding with nothing registered, so the STAC route
cannot be demonstrated. **That is no longer true.** `stac-floodplains-bc` is live at
`images.a11s.one` with 17 items across 16 watershed groups, and Bulkley is published as
`bulk_co_ff04`. The delineation does not need to be run — it already exists.

Verified against the live catalogue during planning:

| Fact | Value |
|---|---|
| Item | `bulk_co_ff04` — `wsg: BULK`, `species: co`, `region: skeena` |
| `floodplain` asset | `.../bulk_co_ff04/floodplain.gpkg`, 5.1 MB, layers `co_ff02` / `co_ff04` / `co_ff06` |
| Published areas | 428.29 / **490.47** / 540.03 km² |
| Geometry | single dissolved MultiPolygon per layer, EPSG:3005 |
| `/vsicurl/` read | works — 9.3 s, area recomputes to 490.47 km², matching the property exactly |

Morice (`morr_co_ff04`, `morr_ch_ff06`) and Kispiox (`kisp_ch_ff04`) are also published. No ZYMO, no
KLUM.

## Decisions taken

1. **Cache the STAC asset; do not pull at render.** Keeps the build offline-capable like every other
   chapter — the repo's only other STAC query (`0740-appendix-uav-imagery.Rmd`) is `eval = F` with
   results cached, so render-time network would be a new pattern here, not a continuation.
2. **Keep the STAC's own naming.** The cached file keeps the item id and the layer keeps the name
   `co_ff04`. Fraser renamed its layer to `floodplain`; we do not.
3. **Coho** (`streams_co_vw`), matching the network the floodplain was delineated on, rather than the
   report's `model_species: "st"`. No explanatory sentence in the prose.
4. **ff04 only.** No sensitivity range — `flooded` documents `flood_factor` as a DEM-compensation
   parameter, not an ecological threshold.
5. **Zoom extent: just north of Smithers**, replacing Fraser's Murray Creek / Vanderhoof detail.

## Phase 1: Retarget the generator

- [ ] `scripts/gis/floodplain.R:45` `wsg <- "NECR"` → `"BULK"`
- [ ] `:46` `species_view <- "streams_ch_vw"` → `"streams_co_vw"`
- [ ] Replace section 6 (`fl_valley_confine` / `fl_valley_poly`) with a fetch of
      `bulk_co_ff04/floodplain.gpkg`, cached under the STAC's own name, layer `co_ff04` preserved.
      Record source URL + checksum so the copy verifies against the catalogue.
- [ ] Drop the now-dead `<stub>_valleys.tif` output and its size accounting
- [ ] Fix three stale header claims: `municipalities` missing from the layer manifest, "three files
      per WSG" now four, and `:38` "fwapg" which is actually bcfishpass on 63333
- [ ] Verify: sections 1-5 run; `bulk.gpkg` written with all context layers; AOI matches BULK
- [ ] Measure and report committed footprint against Fraser's 18.6 MB; trim `roads` if it dominates,
      but not blind — the detail map needs Highway 16 and CN Rail

## Phase 2: Port the appendix

- [ ] Copy Fraser's `0720-appendix-floodplain.Rmd` → same filename (0720 free; `{-#app-floodplain}`
      unused here)
- [ ] Read layer `co_ff04`, not `floodplain`
- [ ] Switch both map chunks from `terra::plot(valleys, ...)` to plotting the polygon — no VCA run
      means no `_valleys.tif`
- [ ] 15 text swaps: Nechako → Bulkley (9 sites), chinook → coho (6 sites)
- [ ] Retarget the zoom to just north of Smithers from the `municipalities` layer, **erroring** if
      Smithers is absent rather than falling back silently as Fraser's does
- [ ] Port the companion rollup chunk at Fraser's `0400-results.Rmd:179-201`
- [ ] Verify: no duplicate chunk labels; figures resolve; zoom is where it should be

## Phase 3: Reconnect the body text

- [ ] Restore section headers renamed on spawn: `## Planning — Habitat and Connectivity Modelling` →
      `... Habitat, Connectivity and Floodplain Modelling` in `0300-methods.Rmd:74` and
      `0400-results.Rmd:196`
- [ ] Port Fraser's `### Floodplain Delineation` methods and results subsections
- [ ] Add `@nagel_etal2014LandscapeScale` and `@hall_etal2007Predictingriver` — both absent from
      Skeena's `references.bib`
- [ ] Reframe the two forward-looking statements this work completes:
      `0500-recommendations.Rmd:42` and `0050-executive-summary.Rmd:159`

## Phase 4: Build, review, release

- [ ] Clean gitbook build (`rm _main.Rmd` first — incremental builds under-report missing citations)
- [ ] `grep -c 'Citeproc: citation .* not found'` on the build log
- [ ] PDF via `bookdown::render_book(envir = globalenv())`; verify by polling the artifact checksum,
      not by waiting on a process
- [ ] Cartographic read of both maps against the self-review checklist
- [ ] NEWS + version bump (next free is v0.5.0), PR, merge, tag
- [ ] Record added weight on the repo-bloat issue

## Validation

- [ ] Cached floodplain verifies against the live catalogue by checksum; area recomputes to 490.47 km²
- [ ] `grep -iE 'nechako|murray|vanderhoof'` across the rendered appendix returns nothing
- [ ] Every prose number is an inline R expression (true of Fraser's; confirm the port kept it so)
- [ ] Both formats build clean, zero Citeproc failures
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
