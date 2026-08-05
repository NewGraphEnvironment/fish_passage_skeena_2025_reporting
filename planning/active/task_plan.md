# Task: Climate departure appendix — swap the AOI in scripts/gis/climate_departure.R and port the appendix (#3)

## Problem

The report has no climate departure appendix. Fraser 2025 carried one
(`0710-appendix-climate-departure.Rmd`, 846 lines) reading `data/gis/climate_departure.{rds,gpkg}`,
`climate_departure_tmean.tif` and `climate_departure_wsg_ecoregion.csv`. It was removed on spawn,
because every product was generated for the Fraser AOI — the right call at the time, but it leaves this
report without the appendix.

## The generator is already built for this

`scripts/gis/climate_departure.R` is complete — 16 sections. Sections 1-10 build the AOI and context
layers from fwapg and BCDC; **sections 11-15 run the full `cd` pipeline** (`cd_catalog`, `cd_extract`,
`cd_baseline`, `cd_anomaly`, `cd_trend`, `cd_compare`, the per-ecoregion loop, the tmean departure
raster, the WSG × ecoregion crosswalk); section 16 writes a snapshot manifest. Its header still claims
"Phase 2 (separate commit)" is pending — that note is stale, Phase 2 landed. Output filenames are
AOI-neutral, so the appendix and body rollup chunks port unchanged.

**Prerequisites confirmed present:** fwapg reachable on 5432 (a *different* database from the
bcfishpass tunnel on 63333), `cd` 0.3.0, `fresh` 0.32.0, `bcdata` 0.5.2.

## What exploration changed about the approach

**The code change is genuinely three literals.** Grepped the whole generator for region-specific values
beyond the two documented vectors; found exactly one more.

| Location | Current | Change to |
|---|---|---|
| `:41` `wsg_codes` | `LCHL, NECR, FRAN, MORK, UFRA, TABR, WILL` | `BULK, MORR, ZYMO, KISP, KLUM` |
| `:46-49` `town_names` | Fraser corridor | Smithers, Houston, Telkwa, Hazelton, Terrace, Kitimat |
| `:123` AOI label | `"FWCP Fraser climate-departure"` | Skeena equivalent |

**The prose is where this can go wrong, and that is the load-bearing phase.** The appendix derives its
extent from the data — 31 inline R expressions — but **16 prose lines carry hardcoded Fraser findings
with units**: "+1.1 to +2.0 °C across the AOI", "ecoregion means span +1.4 to +2.0 °C", "Summer SWE
collapse (-52 %, p ≈ 0.01)". Rebuild on Skeena data and every one becomes wrong but entirely plausible,
with nothing in the build complaining. Same failure mode as the Peace imagery in Fraser's UAV appendix
and the Haida Gwaii escapement in the NuSEDS table — a number that looks like an answer.

Only ~7 lines carry place names, several of them ecoregion names (`Fraser Basin`, `Fraser Plateau`,
`Eastern Hazelton Mountains`) that must be re-derived from the Skeena AOI's actual ecoregion set rather
than swapped by hand.

**Three tuning constants need a judgement call, not a copy.** `min_lake_area_ha = 1000`,
`min_stream_order = 7`, `simplify_tol_m = 200` are commented as tuned for a regional AOI "of this scale
— same tuning Peace used for its ~73,000 km² AOI". Five Skeena groups is a smaller AOI. `cd` hit this
going from peace-fwcp to kootenay-lake and used finer simplify tolerances for the smaller area.

**Considered and rejected: building this as a `cd` regional vignette.** `cd` carries a deliberate
regional-vignette template and `/vignette-to-appendix` is calibrated on four transfers including
`cd`→Fraser. Better in principle — heavy inputs precompute into the package rather than this repo,
which matters because `output_dir: "docs"` means report data is effectively committed twice. Not worth
it when the report-side generator is three literals from working and the appendix already exists in
report register. Revisit if a fourth region needs the same edits.

## Phase 0 — Branch

- [x] Branch off `main`, now current at the v0.1.0 merge
- [x] Archive #1's PWF, carrying forward the two loose ends that had no issue

## Phase 1 — Retarget the generator

- [x] The three literals above, plus the stale "Phase 2 (separate commit)" note in the header
- [x] Tuning constants checked rather than inherited, and **left unchanged on the evidence**: the
      Skeena five are 25,334 km² against the Fraser seven at 34,019 km² — 0.74×, not the
      order-of-magnitude drop that would force a retune — and at order ≥ 7 the two AOIs carry
      comparable stream density (1,865 segments here, 2,100 there). The comment citing Peace's
      ~73,000 km² was itself stale; Fraser had already run these values at half that
- [x] **Verify:** all eight gpkg layers written; six towns all resolved (Smithers, Houston, Telkwa,
      Hazelton, Terrace, Kitimat); 37 lakes; AOI 25,334 km² across the five `params$wsg_code` groups

## Phase 2 — Run the cd pipeline

- [x] Sections 11-15 → `climate_departure.rds` (325 KB), `climate_departure_tmean.tif` (3.4 KB),
      `climate_departure_wsg_ecoregion.csv`, plus the section 16 snapshot manifest
- [x] **Verify:** **six** ecoregions, not Fraser's eight — NRA Nass Ranges, SKM Skeena Mountains,
      EHM Eastern Hazelton Mountains, COG Coastal Gap, FAP Fraser Plateau, FAB Fraser Basin. Note
      Fraser Basin and Fraser Plateau are genuine Skeena-AOI ecoregions, so those names in the prose
      are not automatically wrong — the interpretation around them is. Crosswalk sums to 100 % per
      group; raster masked to the new AOI, 435 cells

**Benign warnings:** `Error exit, tauk2. IFAULT = 12` appeared several times during the per-ecoregion
loop. That is the Kendall tau routine refusing a series it cannot rank cleanly; the pipeline completed,
every ecoregion returned a trend, and Mann-Kendall p-values are populated throughout.

## Phase 3 — Port the appendix

- [x] Copy `0710-appendix-climate-departure.Rmd` from Fraser
- [x] Re-derive the ecoregion names in prose from the actual Skeena ecoregion set
- [x] **Verify:** no duplicate chunk labels — all 24 are `cd-` prefixed and none collide with the
      existing Skeena appendices; figures resolve; build 231/231 chunks

## Phase 4 — Re-verify every interpretive claim  ← the load-bearing phase

- [x] Walked every hardcoded number. All converted to inline R rather than corrected in place, except
      one generic explanation of what "+1.5 °C" means, which is not a finding
- [x] **A directional claim did flip, exactly as anticipated.** Fraser has the interior-plateau
      ecoregions leading and the high-elevation ranges trailing. Here the mountains lead (Nass Ranges
      +2.70, Skeena Mountains +2.62) and the plateau ecoregions trail (Fraser Plateau +2.45, Fraser
      Basin +2.42). Carried over verbatim it would have stated the opposite of the data
- [x] **A second conclusion had to be withdrawn, not just renumbered.** Fraser's appendix concludes the
      spatial gradient supports ranking watershed groups for prioritisation. On this AOI it does not —
      all five groups fall within 0.23 °C of each other and the ecoregion spread is 0.20 °C. That
      section now says prioritisation gains nothing from climate-departure geography here
- [x] Also fixed: the winter/spring snowmelt sentence. Fraser presents both as counterbalancing rises
      that miss significance; here spring is +52 % and highly significant while winter misses
- [x] **Verify:** rendered page carries only Skeena values, and no Fraser watershed-group code survives

**Found while sweeping — a live defect in the Fraser report.** Its published appendix reads "The seven
watershed groups (FRAN, LCHL, MORK, NECR, TABR, UFRA, WILL) **MORK, UFRA, TABR, WILL)** span the eight
ecoregions" — a duplicated fragment with an unmatched paren, from a hardcoded list half-converted to an
inline expression. It came across in the port. Fixed here, filed there as fraser#28.

## Phase 5 — Build, review, release

- [ ] gitbook, then PDF; confirm no broken cross-references and every figure renders
- [ ] Cartographic read of the AOI and tmean maps
- [ ] NEWS + version bump, PR, merge, tag
- [ ] Record the added weight on the repo-bloat issue, as was done for Fraser's map caches

## Out of scope

- **#2 floodplain** — separate appendix, separate route (`stac_floodplains_bc`), genuinely R&D
- **#9 site maps** — needs the bcfishpass tunnel on 63333, a different database from this work
- Making `wsg_codes` read `params$wsg_code`. The generator is standalone, sourced from nothing, so
  there is no `params` in scope; it would have to parse `index.Rmd`'s YAML. Template-level concern.
- **#7 is already complete** (UNBC report linked, sub-threshold tier gone from source and rendered
  output) and is sitting open for no reason. Worth closing, but not part of this.

## Validation

The honest check is the rendered appendix, not the source:

- [ ] Every number in the prose either derives from an inline R expression or has been checked against
      the Skeena outputs by hand
- [ ] No place name or ecoregion name in the appendix belongs to the Fraser
- [ ] `grep -i fraser` across the rendered appendix page returns nothing but genuine ecoregion names,
      if any survive
- [ ] Both formats build clean
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
