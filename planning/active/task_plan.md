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

- [x] `scripts/gis/floodplain.R:45` `wsg <- "NECR"` → `"BULK"`
- [x] `:46` `species_view <- "streams_ch_vw"` → `"streams_co_vw"`
- [x] Replace section 6 (`fl_valley_confine` / `fl_valley_poly`) with a fetch of
      `bulk_co_ff04/floodplain.gpkg`, cached under the STAC's own name, layer `co_ff04` preserved.
      Record source URL + checksum so the copy verifies against the catalogue.
- [x] Drop the now-dead `<stub>_valleys.tif` output and its size accounting
- [x] Fix three stale header claims: `municipalities` missing from the layer manifest, "three files
      per WSG" now four, and `:38` "fwapg" which is actually bcfishpass on 63333
- [x] Verify: sections 1-5 run; `bulk.gpkg` written with all context layers; AOI matches BULK
      (7,762 km²); floodplain reads back at **490.47 km²**, matching the published property exactly
- [x] Measure and report committed footprint against Fraser's 18.6 MB; trim `roads` if it dominates,
      but not blind — the detail map needs Highway 16 and CN Rail

**Trim outcome.** Roads were 20.90 MB of geometry across 21,781 features — 73% of the gpkg. A
proximity trim was measured and rejected: **21,667 of 21,781 roads are already within 5 km of the
floodplain**, because the Bulkley valley is settled and the road network hugs it. Vertex
simplification at 10 m (well under the ~22 m/pixel of the detail map) was applied to the
cartography-only layers, leaving the metric-bearing layers untouched. Cache went **28.6 MB → 21.3 MB**
(gpkg 18.99 → 11.64 MB, DEM 9.62 MB unchanged). Still above Fraser's 18.6 MB, for a watershed group
roughly 1.5× the area.

## Phase 2: Port the appendix

- [x] Copy Fraser's `0720-appendix-floodplain.Rmd` → same filename (0720 free; `{-#app-floodplain}`
      unused here)
- [x] Read layer `co_ff04`, not `floodplain`
- [x] Switch both map chunks from `terra::plot(valleys, ...)` to plotting the polygon — no VCA run
      means no `_valleys.tif`
- [x] 15 text swaps: Nechako → Bulkley (9 sites), chinook → coho (6 sites)
- [x] Retarget the zoom to just north of Smithers from the `municipalities` layer, **erroring** if
      Smithers is absent rather than falling back silently as Fraser's does
- [x] Port the companion rollup chunk at Fraser's `0400-results.Rmd:179-201`
- [x] Verify: no duplicate chunk labels; figures resolve; zoom is where it should be

**Three cartographic defects found by reading the rendered PNGs, not the source.**

1. *Parks and floodplain were both green.* Peace and Fraser fill parks `#639b5f55`; Babine Mountains
   Park sits north-east of Smithers and is larger than any single floodplain unit, so the map showed
   what looked like two classes of floodplain. Parks are now outline-only in purple longdash. This
   defect is latent in Peace and Fraser — it simply had no large park to expose it. **Worth filing
   upstream.**
2. *White bands.* The Bulkley group is markedly taller than wide (h/w 1.26) against a wide default
   device, so the map filled roughly 40 % of the canvas. Figure dimensions are now derived from each
   map's own bbox aspect, so the appendix travels to another watershed group unchanged.
3. *Unreadable label pile.* Full legal municipality names ("The Corporation of the Village of
   Telkwa") plus 17 reserve labels collided into illegibility around Hazelton. Municipality labels
   are shortened to the place name; reserve labels are dropped from the watershed-wide map (diamonds
   retained) and kept on the detail map where they are legible.

I mis-diagnosed 1 twice before reading closely enough — first as an artifact of my own added
polygon border, then as alpha over varying hillshade. Both were wrong; it was a second layer.

## Phase 3: Reconnect the body text

- [x] Restore section headers renamed on spawn: `## Planning — Habitat and Connectivity Modelling` →
      `... Habitat, Connectivity and Floodplain Modelling` in `0300-methods.Rmd:74` and
      `0400-results.Rmd:196`
- [x] Port Fraser's `### Floodplain Delineation` methods and results subsections
- [x] Add `@nagel_etal2014LandscapeScale` and `@hall_etal2007Predictingriver` — both absent from
      Skeena's `references.bib`. **Not** hand-added: `references.bib` is rbbt-generated and
      `update_bib: TRUE`, so a manual entry would be overwritten on the next build. The keys appear
      as ordinary markdown in the prose, which is what rbbt scans, and both resolved on a clean
      build with zero Citeproc failures.
- [x] Reframe the two forward-looking statements this work completes:
      `0500-recommendations.Rmd:42` and `0050-executive-summary.Rmd:159`

## Phase 4: Build, review, release

- [x] Clean gitbook build (`rm _main.Rmd` first — incremental builds under-report missing citations)
- [x] `grep -c 'Citeproc: citation .* not found'` on the build log
- [x] PDF via `bookdown::render_book(envir = globalenv())`; verify by polling the artifact checksum,
      not by waiting on a process
- [x] Cartographic read of both maps against the self-review checklist
- [x] NEWS entry + version bump to 0.5.0 in `DESCRIPTION` and `index.Rmd`
- [ ] PR, merge, tag v0.5.0
- [ ] Record added weight on the repo-bloat issue (21.3 MB: gpkg 11.64, DEM 9.62)

## Validation

- [x] Cached floodplain verifies against the live catalogue by checksum; area recomputes to 490.47 km²
- [x] `grep -iE 'nechako|murray|vanderhoof'` across the rendered appendix returns nothing
- [x] Every prose number is an inline R expression (true of Fraser's; confirm the port kept it so)
- [x] Both formats build clean, zero Citeproc failures
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
