# Findings — Floodplain appendix, Bulkley (#2)

## Issue context (as filed)

> The report has no floodplain appendix. Fraser 2025 carried one scoped to the Nechako River
> watershed group (`0720-appendix-floodplain.Rmd`, reading `data/gis/necr.gpkg`, `necr_dem.tif`,
> `necr_valleys.tif`); it was removed on spawn because none of it applies here.
>
> Scope to the **Bulkley watershed group only** rather than all of BULK, MORR, ZYMO and KISP. One
> watershed group is enough to prove the delivery route, and it is where the 2025 eDNA sampling is
> concentrated.
>
> Doing Bulkley alone also keeps the STAC question tractable. `stac_floodplains_bc` is currently
> scaffolding — `CLAUDE.md`, `README.md`, `planning/`, `scripts/`, `pyproject.toml`, no registered
> floodplains — so the STAC route cannot be demonstrated until something is published to it. The
> sequence:
>
> 1. Delineate with `flooded::fl_valley_confine()` from the DEM and stream network
> 2. Register the result to `stac_floodplains_bc`
> 3. Have the report **pull** from STAC rather than carry the rasters
>
> That last step is the point. Fraser's appendix committed `necr.gpkg` at 15.2 MB plus two rasters;
> repeating that per watershed group is how these repos got heavy in the first place.
>
> Morice, Zymoetz and Kispiox follow once the route works.
>
> Reference: `scripts/gis/floodplain.R` carries the Fraser recipe (hardcoded `wsg <- "NECR"` at :45).

## The premise has already been overtaken

Steps 1 and 2 are done. `stac-floodplains-bc` is live at `images.a11s.one` — 17 items, 16 watershed
groups. Bulkley is `bulk_co_ff04`. Only step 3 remains.

Skeena groups published: `bulk_co_ff04`, `morr_co_ff04`, `morr_ch_ff06`, `kisp_ch_ff04`. Absent:
ZYMO, KLUM.

Item `bulk_co_ff04` properties: `wsg: BULK`, `species: co`, `region: skeena`, `proj:epsg: 32609`,
10 m grid, `floodplain_ff02_km2: 428.29`, `floodplain_ff04_km2: 490.47`, `floodplain_ff06_km2: 540.03`,
`gross_loss_ha: 2073.3`, `gross_gain_ha: 1073.6`, `net_ha: -999.7`.

Six assets: `floodplain` and `floodplain_landcover` (GeoPackage), `classified_2017` /
`classified_2020` / `classified_2023` / `transition_2017_2023` (COG). This appendix uses **only**
`floodplain`.

Verified by direct read: the `floodplain` asset is 5.1 MB with layers `co_ff02`, `co_ff04`,
`co_ff06`; each is a **single dissolved MultiPolygon** in EPSG:3005. Areas recomputed from geometry
match the published properties exactly (490.47 km² for `co_ff04`). A `/vsicurl/` read succeeds in
9.3 s.

## The delineation step disappears

`scripts/gis/floodplain.R` is byte-identical to Fraser's — it survived the "Remove the Fraser
payload" commit (`53f9602`), which dropped only the `.Rmd` and the `data/gis/necr*` files. Its
section 6 runs `flooded::fl_valley_confine()`, the expensive VCA pass. Since `bulk_co_ff04` is
already published, that section is replaced by a download.

Knock-on: no VCA means no `<stub>_valleys.tif`. Peace and Fraser both draw the floodplain by
plotting that binary raster (`terra::plot(valleys, col = c(NA, "#2c7a2c"), ...)`), so both map chunks
must switch to plotting the polygon. This is the one non-cosmetic code change in the appendix.

## The script is genuinely generic

`wsg <- "NECR"` at `:45` is the only watershed-code literal in 297 lines — everything else is
`sprintf`'d from it or derived via `stub <- tolower(wsg)`. No town names, no bbox coordinates, no AOI
label strings. `species_view <- "streams_ch_vw"` at `:46` is the second literal to change.

Header comment block is stale in three places: the layer manifest omits `municipalities` (written at
`:223-227`, consumed by the Rmd); it claims "three files per WSG" when `_meta.rds` makes four; and
`:38` says the prerequisite is an "fwapg" tunnel when `fresh::frs_db_conn()` reads `PG_*_SHARE`,
which is **bcfishpass on 63333**. Also `<stub>_meta.rds` is written but read by nothing.

## The prose port is low-risk

Fraser's `0720-appendix-floodplain.Rmd` (321 lines, 6 chunks) has **no hardcoded numeric results in
prose**. Every area, length, percentage and count is an inline `r` expression. The edits are 9
place-name sites (Nechako / Murray Creek / Vanderhoof) and 6 species/order sites (chinook, order 3+),
all one-line text swaps. This is the opposite of the climate-departure port, where 16 prose numbers
carried Fraser findings with units.

A 7th chunk lives outside the appendix: `0400-results.Rmd:179-201` re-reads the gpkg and recomputes
the rollups for the body-text results paragraph. The port needs it too.

## Fraser's zoom fails silently — do not inherit it

The detail extent greps `named_streams$gnis_name` for `"Murray"` (`:198`), takes the bbox, and pads
with fractional multipliers. On no match there is a fallback at `:207-217` that centres on the AOI
centroid at ±0.3 of the span — so a missing name renders a plausible generic view instead of an
error. Given this repo's history of output that renders cleanly while being wrong, the Smithers
lookup should error.

## The byte saving is smaller than the issue implies

Fraser's committed payload: `necr.gpkg` 15.2 MB + `necr_dem.tif` 3.4 MB + `necr_valleys.tif` 102 KB
= 18.6 MB. Because the decision was to cache rather than pull at render, the STAC route removes only
`_valleys.tif` — about 100 KB.

The weight is elsewhere: `roads` at 22,023 features in Nechako's gpkg, and the DEM. So the STAC pull
buys **provenance and non-duplication of the modelled product**, not primarily bytes. Any real byte
reduction is a separate trim of the context layers, to be sized by measurement rather than promised
in advance.

## Body text already anticipates the appendix

- `0200-background.Rmd:28` — lists "floodplain extent" among the layers this report compiles. The
  appendix makes a standing claim true.
- `0200-background.Rmd:88` — Bulkley valley bottom, Hazelton / Smithers / Telkwa / Houston, Highway
  16 and CN Rail "within and adjacent to the floodplain", plus riparian conversion to hayfield and
  pasture. This is the setup for the north-of-Smithers zoom.
- `0500-recommendations.Rmd:42` — currently proposes mapping Bulkley as *future* work, including the
  exact delivery route. Needs reframing once this lands; Morice and Kispiox are already published.
- `0050-executive-summary.Rmd:159` — same, in summary form.

Section headers were renamed on spawn: `0300-methods.Rmd:74` and `0400-results.Rmd:196` read
`## Planning — Habitat and Connectivity Modelling` where Fraser has `... Habitat, Connectivity and
Floodplain Modelling`. Fraser's `### Floodplain Delineation` subsections have no Skeena counterpart.

`references.bib` lacks both `nagel_etal2014LandscapeScale` and `hall_etal2007Predictingriver`.

## flood_factor is not an ecological threshold

`flooded` documents `flood_factor` (`R/fl_scenarios.R:9-27`) as a **DEM compensation parameter**, not
an ecological threshold. Presenting ff02 / ff04 / ff06 as alternative scenarios would misrepresent
them. Hence ff04 only.

Upstream `stac_floodplains_bc#9`: `scenario` is not in item `properties` — only a GDAL tag and the
title. It must be parsed from the item id. Latent today because nearly everything is ff04, but
`morr_ch_ff06` already breaks the assumption.

## Measured outcomes (Phase 1)

BULK generated clean against the tunnel: 7,762 km² AOI, 6,851 coho-accessible order-3+ stream
segments, 525 waterbodies, 21,781 roads, 5 municipalities (including "Town of Smithers", so the
detail-map lookup resolves). Published floodplain read back at **490.47 km²**, matching the
catalogue property exactly. md5 `c87d7db9d21aae14ac24ea406da3dcae`.

### The proximity trim does not work here

Roads were 20.90 MB of geometry across 21,781 features — 73% of an 18.99 MB gpkg. The obvious trim
is to keep fine road detail only near the floodplain, since that is what the appendix is about. It
buys nothing: **21,667 of 21,781 roads are already within 5 km of the floodplain**. The Bulkley
valley is settled and the road network follows it, so proximity to the floodplain is not a
discriminating filter in this watershed group. It may still be worth measuring in a less-settled
group before assuming it never helps.

Vertex simplification is the lever that does work, and it floors quickly: 10 m tolerance gives
13.83 MB, 25 m gives 13.37 MB, 50 m gives 13.17 MB. The cost is feature *count*, not vertices. 10 m
was chosen — the detail map renders at ~22 m/pixel and the watershed-wide map at ~91 m/pixel, so it
is invisible either way.

Applied only to the layers routed through `fetch_layer()` (railways, roads, reserves, parks,
named_streams, municipalities), which are drawn but never measured. `aoi`, `streams`, `waterbodies`
and the floodplain are left alone because they feed the reported areas and lengths — thinning them
would move published numbers silently.

Cache: **28.6 MB → 21.3 MB** (gpkg 18.99 → 11.64, DEM 9.62 unchanged). Fraser's was 18.6 MB for a
watershed group roughly two-thirds the area, so per-km² this is comparable, not worse.

The DEM is now the floor. It cannot be downsampled: at 30 m the detail window is ~1,000 cells
rendered across ~1,350 px, so any aggregation would make the hillshade blocky in the one map where
terrain detail carries the message.

### The waterbody counts are close to tautological

`lakes_n` and `wetlands_n` come out at 180 and 345 — exactly the totals on the network. Every
waterbody falls inside the floodplain, because waterbodies were an **input** to the valley
confinement model (`fl_valley_confine(waterbodies =)`) precisely so it would not carve holes around
them. So "lakes within floodplain" is close to a restatement of "lakes on the accessible network".

Inherited from Peace and Fraser, and the appendix prose does disclose the mechanism ("Waterbodies
were included so the valley confinement model fills cells that gradient and cost-distance masks
would otherwise exclude"). Left as-is for consistency with the sibling reports, but the rows carry
less information than their labels imply, and are worth reconsidering across all three.

## Related worked example, deliberately not used

`restoration_wedzin_kwa_2024/2043-Appendix-lulc.Rmd` (466 lines) is a complete floodplain +
land-cover-change appendix for the Upper Bulkley — same watershed, same species, same `co_ff04`
scenario. It carries the methods prose with both citations and the `drift::dft_map_interactive()`
COG map. Not used here: this appendix is the floodplain only, matching Peace and Fraser. Worth
harvesting prose from, and the obvious basis for a future land-cover-change appendix.
