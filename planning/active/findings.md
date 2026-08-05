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

## Skeena results — what the numbers actually are

Generated 2026-08-05. These are what the ported prose has to be rewritten against.

**Six ecoregions, not eight.** NRA Nass Ranges, SKM Skeena Mountains, EHM Eastern Hazelton Mountains,
COG Coastal Gap, FAP Fraser Plateau, FAB Fraser Basin. Fraser Basin and Fraser Plateau are genuine
Skeena-AOI ecoregions — they extend north — so the names survive even though the region changed.

**Cumulative warming since 1951 (trend slope × 75 years), °C:**

| | | tmean | tmax | tmin | prcp p |
|---|---|---|---|---|---|
| NRA | Nass Ranges | **2.70** | 2.42 | 2.91 | 0.83 |
| SKM | Skeena Mountains | 2.62 | 2.36 | 2.75 | 0.35 |
| EHM | Eastern Hazelton Mountains | 2.49 | 2.27 | 2.58 | 0.95 |
| COG | Coastal Gap | 2.48 | 2.26 | 2.67 | 0.88 |
| FAP | Fraser Plateau | 2.45 | 2.31 | 2.51 | 0.69 |
| FAB | Fraser Basin | **2.42** | 2.29 | 2.48 | 0.87 |

Regional: **+2.59 °C** cumulative, Mann-Kendall p < 0.0001. Every ecoregion significant at p ≈ 0.
`tmin > tmax` in all six, so the day-night asymmetry holds. No significant precipitation trend
anywhere (p 0.35–0.95).

**The elevation story inverts.** Fraser's appendix has the interior-plateau ecoregions (Fraser Basin,
Fraser Plateau) *leading* and high-elevation ranges *trailing*. In the Skeena those same two plateau
ecoregions **trail** at +2.42 and +2.45, and the Nass Ranges and Skeena Mountains lead at +2.70 and
+2.62. Porting the Fraser sentence would have stated the opposite of what this data shows.

**Recent decade vs pre-warming reference, regional annual:** tmean +2.07 °C, tmax +1.91, tmin +2.19
(all p < 0.0001). Summer tmean +2.75, winter +2.15.

**Spatial tmean departure raster:** +1.78 to +2.43 °C across the AOI, mean +2.07. Fraser's range was
+1.1 to +2.0.

**Snowpack, recent decade vs reference, percent change:**

| | change | p |
|---|---|---|
| summer SWE | **−60.3 %** | 0.0001 |
| summer snowmelt | **−40.9 %** | 0.0027 |
| spring snowmelt | **+51.5 %** | 0.0005 |
| winter snowmelt | +46.4 % | **0.55 — not significant** |
| annual SWE | −20.2 % | 0.0075 |

The winter figure matters for the port: Fraser's prose reads "counterbalancing winter (+45 %) and
spring (+18 %) snowmelt rises", with both treated as real. Here winter is a similar magnitude but
**not statistically significant**, while spring is nearly three times Fraser's and highly significant.
Carrying that sentence over would assert a counterbalancing pair the Skeena data does not support.

**WSG × ecoregion crosswalk:** Kalum is 100 % Nass Ranges; Kispiox 78 % Nass / 22 % Skeena Mountains;
Morice 68 % Eastern Hazelton / 23 % Coastal Gap; Zymoetz 73 % Nass / 23 % Eastern Hazelton; Bulkley is
the only genuinely mixed group, spread across five ecoregions with no majority (40 % Fraser Plateau).

## Route considered and rejected

`cd` carries a deliberate regional-vignette template (`peace-fwcp.Rmd`, `kootenay-lake.Rmd`) whose
project memory states a third regional vignette is expected, and `/vignette-to-appendix` is calibrated
on four transfers including `cd`→Fraser. That route puts heavy inputs in `inst/vignette-data/` inside
the package rather than this repo's `data/gis/`, which matters because `output_dir: "docs"` means report
data is committed twice.

Rejected for this issue only: the report-side generator is three literals from working, and the
appendix already exists in report register so there is no vignette→appendix tone transfer to perform.
Worth revisiting when a fourth region needs the same edits.
