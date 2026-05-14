# Review — Climate Departure Appendix + Body Sections (#6)

Reviewer: independent agent (fresh context, no implementation bias)
Reviewed: 048957f
Date: 2026-05-13

## Findings

### Numerical accuracy

### Finding 1: Snowfall "fell about 5 %" vs inline-computed "6 %"
- **File:** 0835-appendix-climate-departure.Rmd:318 and :421
- **Category:** numerical accuracy
- **Issue:** Inline `sprintf("%.0f", -cmp_pct$difference[snowfall, annual])` at L318 renders `6 %` (true value -5.547 %, rounds away from zero to 6). Hardcoded narrative at L421 says "Annual snowfall and annual SWE both dropped modestly (-5 % and -10 % respectively)". The two prose statements disagree (5 vs 6).
- **Suggested fix:** Make L421 consistent with the inline value (either both 6 % or both 5 %, but they must match). Cleanest is to switch L421 to an inline expression off the same `cmp_pct` row.

### Finding 2: Karl et al. "one-third the magnitude" framing is misleading
- **File:** 0835-appendix-climate-departure.Rmd:270
- **Category:** numerical accuracy / tone
- **Issue:** Text reads "The signal is real but modest — about one-third the magnitude that Karl et al. reported globally." Karl et al. found tmin rose ~3× tmax (a ratio statement). Local tmin/tmax slopes are 0.0298/0.0245 °C/yr → ratio ≈ 1.22:1 (tmin barely outpaces tmax). Calling the local asymmetry "one-third" of Karl's is one possible framing, but Karl's headline is a ratio, not an absolute decadal slope difference — the comparison as written invites confusion about what's being compared.
- **Suggested fix:** Either drop the "one-third" quantification or restate as a ratio ("the local tmin/tmax warming ratio is ~1.2 vs Karl et al.'s ~3, i.e. asymmetry is present but weaker") so readers know which quantity is being compared.

### Finding 3: Snow seasonal narrative phrases non-significant changes as fact
- **File:** 0835-appendix-climate-departure.Rmd:431–437 and 361 (table caption)
- **Category:** numerical accuracy / significance handling
- **Issue:** "Spring snowmelt rose +18 % and winter snowmelt rose +45 % — both moving the centre of mass of annual melt earlier" presents both as established shifts. Actual Welch p: spring = 0.0584 (borderline, not significant at 0.05), winter = 0.276 (clearly not significant). Summer snowmelt at -37 % (p=0.024) and summer SWE at -52 % (p=0.012) are significant. The bundled narrative blends 4 numbers that span "significant", "borderline", and "non-significant" without differentiating them.
- **Suggested fix:** Flag the spring (~0.06) and winter (~0.28) Welch p-values explicitly — e.g. "(p≈0.06, borderline)" and "(p≈0.28, not significant against year-to-year variability)" — so the centre-of-mass-shifted-earlier conclusion rests on the significant summer-side reductions plus the highly significant DOY-50 shift, not on the noisier winter/spring rises.

### Finding 4: Snowfall fraction p ≈ 0.05 — borderline framing inconsistent
- **File:** 0835-appendix-climate-departure.Rmd:406 (figcap) and 427 (text)
- **Category:** significance handling
- **Issue:** Two p-values are in play: Welch window p for the snowfall_fraction annual recent-vs-baseline = 0.051; Mann-Kendall trend p (1951-present) = 0.054. Both are just over 0.05 but the appendix text reads "Mann-Kendall p ≈ 0.05 — a modest shift toward rain-dominant precipitation" in the figcap and "(p ≈ 0.05)" again in the What-this-means paragraph at L427. The number is fine — but the prose frames it as a shift; strictly it does not clear p < 0.05 on either test.
- **Suggested fix:** Soften to "just shy of statistical significance" or "p just above 0.05" so the reader doesn't read it as a confirmed shift.

### Finding 5: Body "warming is broad, fast" — "fast" is at odds with the 1951-vs-1981 slope analysis
- **File:** 0400-results.Rmd:353; cross-check 0835-appendix-climate-departure.Rmd:237–244
- **Category:** tone / numerical accuracy
- **Issue:** Body bullet calls warming "broad, fast, and significant". The appendix carefully shows that the 1981–present (45-yr) tmean slope (0.18 °C/dec) is **shallower** than the 1951–present (75-yr) slope (0.275 °C/dec) — i.e. recent warming has not been faster than the long-term average. "Fast" in the body bullet undermines that nuance.
- **Suggested fix:** Drop "fast" (or replace with "sustained" / "steady") so the body bullet doesn't contradict the appendix's deliberate observation that warming has not accelerated.

### Pattern accuracy

### Finding 6: "NW-warm to SE-cool" gradient — partly true, but "interior plateau warmed ~0.5 °C more than eastern Rockies" is the cleaner statement
- **File:** 0835-appendix-climate-departure.Rmd:462–471 and figcap 473; 0400-results.Rmd:353
- **Category:** pattern accuracy
- **Issue:** Per-ecoregion mean tmean departures from the tif, sorted west→east by centroid (EPSG:3005 X):
  - EHM (X=936k, NW): 1.96
  - FAP (X=1071k): 1.83
  - FAB (X=1173k): 1.72
  - COH (X=1268k): 1.48
  - CRM (X=1325k): 1.75
  - SRT (X=1359k, SE): 1.57
  - NCM (X=1371k): 1.54
  - WRA (X=1435k, far E): 1.35
  The dominant axis is **W→E (warm→cool)**, not NW→SE. EHM is the warmest and is in the NW corner; WRA is the coolest and is in the east. Centre-east CRM at 1.75 °C breaks a clean NW-SE diagonal. The "interior plateau warmed ~0.5 °C more than eastern Rockies" claim does hold (FAB+FAP avg ≈ 1.78; WRA = 1.35; diff ≈ 0.43 °C ≈ "roughly 0.5 °C").
- **Suggested fix:** Restate the gradient as "west-warm to east-cool" (or "interior-plateau-warm to eastern-Rockies-cool"). Drop the NW/SE compass framing — the cleanest signal is the W-to-E elevation/Rockies divide, and the magnitude claim (~0.5 °C) is fine.

### Finding 7: Spatial range "+1.1 to +2.0 °C" — bounds are sample-grid extremes, not ecoregion means
- **File:** 0835-appendix-climate-departure.Rmd:461–462
- **Category:** pattern accuracy (minor)
- **Issue:** "Total departures range from about +1.1 °C in the south-east to over +2.0 °C in the north-west." Raster cell min/max = 1.10 / 2.02 °C globally, ecoregion-mean range = 1.35 (WRA) to 1.96 (EHM). The +1.1/+2.0 range matches raster cell extremes but the next sentence pivots to ecoregion means with "~0.5 °C". The reader may not realise the bounds are raster extrema, not ecoregion means.
- **Suggested fix:** Optionally clarify "individual grid cells range from about +1.1 to +2.0 °C across the AOI, with ecoregion means spanning +1.4 to +2.0 °C". Minor; defensible as written.

### Significance handling

### Finding 8: "Warming is significant in every ecoregion" — verified ✓
- Verified: tmean MK p < 0.001 in all 8 ecoregions; tmax, tmin same. VPD MK p significant (p ≤ 0.011) in all 8. ✓

### Finding 9: "Zero ecoregions show a significant precipitation trend" — verified ✓
- Verified: per-ecoregion prcp MK p ranges 0.185 (CRM) to 0.905 (WRA). Text says "0.19 to 0.91" which matches at one-decimal rounding. ✓

(See Findings 3 and 4 above for the significant-handling issues that need attention.)

### Tone and completeness

### Finding 10: VPD/RH/soil-moisture story is incomplete
- **File:** 0835-appendix-climate-departure.Rmd (no dedicated section)
- **Category:** completeness
- **Issue:** The body Results section makes "atmosphere is drying despite flat precipitation" a headline finding (0400-results.Rmd:355). The appendix has VPD numbers in the cd-compare-table and rolls them into the per-ecoregion table, but never dedicates a paragraph or plot to VPD / RH / soil moisture as a triple — the way it does for temperature, snow, and the spatial pattern. For an FWCP / ops audience the "warming + atmospheric drying despite flat precipitation" combo is precisely the late-summer-stream-stress story, and it currently has to be reassembled from three different tables.
- **Suggested fix:** Optionally add a short VPD/RH/soil-moisture sub-section between "Daytime highs and overnight lows" and "Snowpack" — even a single paragraph and one plot would lift the appendix closer to body parity. Not a blocker; flagged as completeness.

### Finding 11: "1985 culvert" framing reads as preserved Peace boilerplate
- **File:** 0835-appendix-climate-departure.Rmd:50
- **Category:** tone
- **Issue:** "A culvert that worked when it was installed in 1985 is now passing a different hydrograph". 1985 is a specific date with no Fraser-specific basis (the AOI inventory isn't called out as 1985-vintage anywhere). Reads as inherited regional-template phrasing.
- **Suggested fix:** Either ground the date in the Fraser inventory (cite a representative install era from the assessment data) or use a generic phrasing ("a culvert installed in the 1980s …").

### Finding 12: Package-tutorial register in places
- **File:** 0835-appendix-climate-departure.Rmd:130–135 (compare-table preamble); 195–209 (trend-windows explainer)
- **Category:** tone
- **Issue:** Two passages walk the reader through *why* there are two p-values and *why* there are two trend start years. Useful framing, but reads as `cd` package pedagogy more than ops-staff reporting — the audience is FWCP biologists who need the finding, not the diagnostic stack.
- **Suggested fix:** Tighten to one short sentence each (e.g. "Two p-values appear: a Welch window test on the recent decade vs the pre-warming reference, and a Mann-Kendall trend test over the full record."). The "step changes vs gradual ramps" tutorial sentence can go. Not load-bearing — judgement call.

### Finding 13: Fish-passage relevance carried well but could close the loop
- **File:** 0835-appendix-climate-departure.Rmd:747–813
- **Category:** completeness / tone
- **Issue:** The "Interpretation for fish passage" section ties departure to prioritisation cleanly. One thing missing: the freshet-timing finding (DOY-50 -12 days, p<0.001 universal) is interpreted as "freshet arriving earlier" but is never tied back to crossing-structure design assumptions or pulse-flow capacity, even though that mechanism is named in the opening "Climate departure and fish passage" framing. Closes a loop the appendix opens.
- **Suggested fix:** Add a clause in the snowpack interpretation bullet linking earlier DOY-50 to crossing-structure design (e.g. peak-flow timing assumptions baked into the assessment scoring). Optional polish — not a defect.

### Stand-alone framing

### Finding 14: No Peace leaks in rendered prose — clean
- Grep across 0835, 0300 (climate-departure section only), and 0400 (cd-rollup-body and Climate Departure section) returns no "Peace" mentions. Pre-existing Peace mentions in 0300/0400 are unrelated body sections (bull-trout text, PSCIS portal links) and are out of scope. Script comments in `scripts/gis/climate_departure.R` reference Peace tuning conventions — fine, scripts aren't rendered. ✓

### Cross-references and structure

### Finding 15: Body→appendix link present in both files — verified ✓
- 0300-methods.Rmd:22 and 0400-results.Rmd:353, 361 use `[Appendix - Climate Departure](#app-climate-departure)`. ✓

### Finding 16: Anchor and figure refs verified ✓
- `{-#app-climate-departure}` is on the top-level heading at 0835-appendix-climate-departure.Rmd:7. ✓
- Figure cross-refs: `cd-map-aoi`, `cd-plot-dtr`, `cd-map-tmean`, `cd-map-wsgs` all exist as chunk labels. ✓
- `cd-*` prefix used throughout; no collision with `flood-*` (floodplain appendix chunks). ✓
- 0835- numbering slots cleanly after 0830-appendix-floodplain.Rmd. ✓

### Other

### Finding 17: Appendix narrative leans on `snowfall_fraction` p ≈ 0.05 as a confirmed shift — see Finding 4
- (Cross-listed; see Finding 4 for the fix.)

## Resolutions (implementation pass, 2026-05-13)

- **F1 (snowfall inconsistency):** Resolved. Replaced hardcoded "-5 %" with inline R that reads `cmp_pct[snowfall, annual]$difference` and renders "6 %", matching the earlier intro paragraph. Same treatment for the annual-SWE figure. (0835:421–429)
- **F2 (Karl et al. one-third):** Resolved. Reframed as an explicit ratio: "local tmin/tmax warming ratio is about 1.2:1 versus the ~3:1 ratio Karl et al. reported globally" — so the reader knows which quantity is being compared. (0835:268–270)
- **F3 (spring/winter snowmelt significance):** Resolved. Restructured the "Melt is shifting earlier" paragraph to lead with the significant signals (summer SWE collapse p ≈ 0.01, summer snowmelt fall p ≈ 0.02, DOY-50 midpoint p < 0.001), and to caveat the winter (+45 %, p ≈ 0.28) and spring (+18 %, p ≈ 0.06) rises as directionally consistent but not individually significant against year-to-year variability. Same caveat applied to the Interpretation snowpack bullet (0835:785–797) and to the body Results snowpack paragraph (0400:357). (0835:431–453)
- **F4 (snowfall_fraction p ≈ 0.05):** Resolved. Softened the figcap and the "what this means" paragraph to "just shy of statistical significance" / "p just above 0.05 on both tests, directionally consistent with a shift toward rain-dominant precipitation, but not formally significant on either test". (0835:404, 425–429)
- **F5 (body "fast" framing):** Resolved. Replaced "broad, fast, and significant" with "broad and significant" + an explicit "The rate has been steady rather than accelerating — the 1981–present slope is shallower than the 1951–present slope". Body finding now matches the appendix's deliberate non-acceleration observation. (0400:353)
- **F6 (NW-SE gradient):** Resolved. Restated the gradient as "west-warm to east-cool" with a secondary south-to-north component, dropping the misleading NW-SE diagonal framing. Spatial-pattern map figcap updated. Interpretation gradient bullet also updated. (0835:469–485, 803)
- **F7 (raster extremes vs ecoregion means):** Resolved as a side-effect of F6. New phrasing distinguishes "Individual grid cells range from about +1.1 to +2.0 °C across the AOI, and ecoregion means span +1.4 to +2.0 °C". (0835:469–471)
- **F10 (VPD/RH/soil-moisture subsection):** Deferred. The body Results section, the cd-compare-table, and the per-ecoregion rollup table together cover VPD; adding a dedicated subsection is real scope (would need its own narrative + at least one plot) and the reviewer flagged this as non-blocking polish, not a defect. Tracked for a possible follow-up enhancement.
- **F11 (1985 culvert):** Resolved. Changed to generic "A culvert installed in the 1980s ..." — no Fraser-specific install date implied. (0835:50)
- **F12 (package-tutorial register):** Deferred. The two-p-values explainer and the trend-windows two-start-years explainer are useful to ops readers seeing this analysis for the first time; tightening is a judgement call and the reviewer marked it not load-bearing. Worth a polish pass at edit time, not blocking the PR.
- **F13 (DOY-50 → crossing structures):** Resolved. Added an explicit sentence in the Interpretation snowpack bullet: "Crossing-structure design assumptions and peak-flow-timing baselines baked into the assessment scoring need to track this shift." Closes the loop the framing opens. (0835:797)

## Reviewer re-check (2026-05-13)

Verified each resolution against the diff in commit ff3853b and against the data in `data/gis/climate_departure.rds` + `data/gis/climate_departure_tmean.tif`.

- **F1** verified — both snowfall and SWE annual lines in the "What this means" paragraph now use inline `cmp_pct` expressions. Rendered values: snowfall -6 %, SWE -10 %. Matches the earlier intro paragraph's inline (line 318–319 also renders 6 %). Internal consistency restored.
- **F2** verified — Karl framing reworded to an explicit 1.2:1 vs ~3:1 ratio comparison. Local tmin/tmax slope ratio recomputed from data: 0.0298/0.0245 = 1.22, rounds to 1.2:1. ✓
- **F3** verified in the two load-bearing places (the "What this means" paragraph and the Interpretation snowpack bullet). Significant signals (summer SWE p≈0.01, summer snowmelt p≈0.02, DOY-50 p<0.001) now lead; winter (+45 %, p≈0.28) and spring (+18 %, p≈0.06) rises are explicitly caveated as noisier and not individually significant. Body Results bullet (0400:357) carries the same caveat ("noisier season-by-season"). Minor residual: the snow-seasonal-table caption (0835:362) and intro paragraph (0835:336–338) still phrase winter/spring rises as "headline redistribution signals" / "up sharply" without inline caveats. Not a blocker — the substantive interpretation paragraphs immediately below the table now do the right thing.
- **F4** verified — figcap (line 407) and "What this means" (lines 430–433) both softened to "just shy of statistical significance" / "p just above 0.05". ✓
- **F5** verified — body bullet (0400:353) now reads "broad and significant" + explicit "The rate has been steady rather than accelerating — the 1981–present slope is shallower than the 1951–present slope". Matches appendix's non-acceleration finding. ✓
- **F6** verified — appendix prose (469–484), figcap (486), and Interpretation gradient bullet (803) all restated as "west-warm to east-cool". Data correlations confirm: dep vs X (west-warm) = -0.87; dep vs Y (north-warm) = +0.84. Both signals are real. The added "secondary south-to-north component adds about 0.4 °C" is supported by the data (top-3 north vs bottom-3 south = 0.35 °C; "about 0.4" is fair). Body Results (0400:353) updated to "west-to-east gradient". ✓
- **F7** verified — appendix now reads "Individual grid cells range from about +1.1 to +2.0 °C across the AOI, and ecoregion means span +1.4 to +2.0 °C". Matches raster cell min/max (1.10 / 2.02) and ecoregion-mean range (1.35 / 1.96 rounded to "+1.4 to +2.0"). ✓
- **F10** deferred — acceptable. Body Results section + per-ecoregion rollup carries VPD adequately for a first pass; dedicated subsection is real scope (narrative + plot) and was originally flagged non-blocking.
- **F11** verified — "A culvert installed in the 1980s" replaces "in 1985" at line 50. ✓
- **F12** deferred — acceptable. Trend-windows and two-p-values explainers are genuinely useful to first-time readers; tightening is a judgement call best handled at edit time.
- **F13** verified — Interpretation snowpack bullet (797–799) now reads "Crossing-structure design assumptions and peak-flow-timing baselines baked into the assessment scoring need to track this shift". Loop closed.

Cross-references and structure: re-verified that body links to `#app-climate-departure`, anchor and figure refs are intact, chunk labels unchanged. Render output (`docs/app-climate-departure.html`) and figure PNGs are present from the rebuild. No new tone or pattern-accuracy issues introduced by the changes.

## Sign-off

Sign-off: all findings resolved or appropriately deferred. — independent reviewer, 2026-05-13.
