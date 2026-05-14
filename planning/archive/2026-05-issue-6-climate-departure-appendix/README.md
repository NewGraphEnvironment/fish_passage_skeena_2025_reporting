## Outcome

Added a standalone climate-departure analysis for the FWCP Fraser
AOI (union of seven watershed groups: LCHL, NECR, FRAN, MORK,
UFRA, TABR, WILL). Three pieces landed: snapshot script
`scripts/gis/climate_departure.R` that builds the AOI, sources
context layers (fwapg) and ecoregions (bcdata), and runs the `cd`
pipeline on the AOI plus each of the eight intersecting
ecoregions; deep appendix `0835-appendix-climate-departure.Rmd`
with 16 figures and 5 tables (recent-vs-pre-warming, trend
summary, snow seasonal, per-ecoregion rollup, WSG × ecoregion
crosswalk); and short `## Climate Departure` sections in
`0300-methods.Rmd` and `0400-results.Rmd` carrying audience-
language framing + 4-finding inline-R Results paragraph. Data
filenames are AOI-neutral (`data/gis/climate_departure.{gpkg,
rds,tif,csv}`) so the same script and appendix template apply
verbatim in future regional reports — repo path is the AOI label,
filename is the artefact kind.

Interpretation written fresh from Fraser numbers, not copied from
the Peace appendix that bootstrapped the structure. Headline
findings: regional warming +1.6 °C since 1951 (lower than Peace's
+1.8 °C, southerly latitude); rate is **steady, not accelerating**
(45-yr slope shallower than 75-yr — a Fraser-specific structural
finding); zero of eight ecoregions show a significant
precipitation trend (Peace had 2 of 5); VPD significant in every
ecoregion (universal atmospheric drying); snowmelt midpoint
shifted 11.8 days earlier (p < 0.001) with summer SWE collapse
(-52 %) and summer snowmelt fall (-37 %) carrying the
statistically significant snowpack signals (winter +45 % and
spring +18 % rises directionally consistent but not individually
significant). Spatial gradient runs west-warm (interior plateau
ecoregions) to east-cool (Rocky Mountain ecoregions) with a
secondary south-to-north amplification.

Workflow notes for future reference: (1) `mean(SpatRaster)` does
not S4-dispatch reliably to terra — use `terra::app(x, fun = "mean")`
explicitly. (2) The `whse_basemapping.gns_geographical_names_sp`
table stores canonical-name records as `feature_type = "Village (1)"`,
not `"Village"`; the suffix is required to match. (3) Independent-
review-as-gating-phase worked well: fresh agent (no implementation
bias) wrote 17 findings to `review-climate-departure.md`, the
implementer addressed 9, deferred 2 with reasoning, and the
reviewer re-checked and signed off — surfaced 3 load-bearing
significance/accuracy issues that would have shipped otherwise.

Closed by: PR #8 (squash `8a0348c`) → release commit `28f35e8`
Release v0.2.0 → tag `v0.2.0`.
