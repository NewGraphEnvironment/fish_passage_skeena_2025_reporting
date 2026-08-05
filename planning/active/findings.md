# Findings — Climate departure appendix for the Skeena (#3)

## The generator is complete; its own header says otherwise

`scripts/gis/climate_departure.R` carries a header note reading "Phase 2 (separate commit): extends
this script with the cd pipeline to produce the rds + tif + csv". That note is **stale**. The script has
16 sections and Phase 2 landed:

| Sections | What they do |
|---|---|
| 1-10 | fwapg + BCDC → AOI, WSGs, towns, lakes, rivers, streams, highways, ecoregions → `climate_departure.gpkg` |
| 11-15 | `cd_catalog` → `cd_extract` → `cd_baseline` → `cd_anomaly` → `cd_trend` → `cd_compare`, per-ecoregion loop, tmean raster, WSG × ecoregion crosswalk |
| 16 | snapshot manifest |

Confirmed by grep: `cd::cd_catalog()` at `:296`, `cd::cd_extract()` at `:299`, and the per-ecoregion
loop from `:310`.

## Region-specific literals: three, not two

The header documents two vectors needing edits for a new AOI. Grepping for Fraser place names and WSG
codes across the whole script turns up **one more** the header does not mention:

```r
:123  aoi_3005 <- sf::st_sf(region = "FWCP Fraser climate-departure", geom = aoi_3005)
```

Cosmetic — it labels the AOI feature — but it would travel into the gpkg and out the other side.

## The generator cannot read `params`, and the issue was wrong to ask

The original issue proposed making `:41` read `params$wsg_code`. Not possible as written: the script is
standalone, run by hand via `Rscript`, and `grep -rn 'climate_departure.R'` across every `.R` and `.Rmd`
returns **no caller**. There is no `params` object in scope. Driving it from the report's own parameter
would mean parsing `index.Rmd`'s YAML — worth doing at template level if a fourth region appears, not a
two-character fix, and not a blocker.

## Where this can go wrong: hardcoded findings in prose

The Fraser appendix is 846 lines with **31 inline R expressions**, so extent, watershed-group lists and
counts re-derive themselves. But **16 prose lines carry numbers with units baked in**:

```
:485  about +1.1 to +2.0 °C across the AOI, and ecoregion means span
:486  +1.4 to +2.0 °C (Figure \@ref(fig:cd-map-tmean)). The dominant
:377  Summer SWE collapse (-52 %, p ≈ 0.01) and summer snowmelt fall (-37 %, p ≈ 0.02)
```

Port the appendix, rebuild on Skeena data, and each of these becomes wrong but entirely plausible. The
build does not complain — nothing here is a broken reference or a missing file. This is the same shape
as the Peace imagery in Fraser's UAV appendix and the Haida Gwaii escapement in the NuSEDS table.

Where the value is derivable, converting to an inline R expression is better than correcting it, since
that stops the next region inheriting the same problem.

## Place names: fewer than expected

Only 7 lines match Fraser place names, and several are **ecoregion** names rather than prose choices —
`Fraser Basin`, `Fraser Plateau`, and `Eastern Hazelton Mountains` (already a Skeena-area ecoregion
appearing in the Fraser AOI). These must be re-derived from the Skeena AOI's actual ecoregion set, not
swapped by hand.

## Prerequisites, all present

| | |
|---|---|
| fwapg PostgreSQL | reachable on **5432** — not the bcfishpass tunnel on 63333 |
| `cd` | 0.3.0 (preflight `stopifnot()` requires >= 0.3.0) |
| `fresh` | 0.32.0 — supplies `frs_db_conn()` |
| `bcdata` | 0.5.2 — ecoregions come from BCDC, not fwapg |

## Route considered and rejected

`cd` carries a deliberate regional-vignette template (`peace-fwcp.Rmd`, `kootenay-lake.Rmd`) whose
project memory states a third regional vignette is expected, and `/vignette-to-appendix` is calibrated
on four transfers including `cd`→Fraser. That route puts heavy inputs in `inst/vignette-data/` inside
the package rather than this repo's `data/gis/`, which matters because `output_dir: "docs"` means report
data is committed twice.

Rejected for this issue only: the report-side generator is three literals from working, and the
appendix already exists in report register so there is no vignette→appendix tone transfer to perform.
Worth revisiting when a fourth region needs the same edits.
