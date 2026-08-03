# Findings — eDNA (#10) + structural alignment (#11)

## eDNA data — established before starting

38 records: **33 real environmental samples**, 2 field blanks, 3 office blanks. Collected
2025-09-12 → 2025-10-10. 36 of 146 site×target combinations are clean detections (≥4 droplets):
RAIN at 20 sites, CHIN 9, BULT 5, SOCK 1, BURB 1.

Real samples by watershed group — all already in `params$wsg_code`, so no scoping change:

```
TABR 11 │ WILL 6 │ MORK 6 │ NECR 5 │ UFRA 3 │ FRAN 2   = 33
```

Region is not stored as a watershed-group column anywhere in the eDNA data. It comes from the
`source` column (path to the originating Mergin gpkg) — filter on `sern_fraser_2024`, the same
mechanism Peace uses with `sern_peace_fwcp_2023`.

## Blanks: the coordinates are real; the site_id is what's borrowed

Peace's code says in three places that office blanks are dropped because their "UTM coords are
inherited from related sites" / "fake coords" — `0400-results.Rmd` prep comment,
`0837-appendix-edna.Rmd` prep comment, and the `edna_map_peace.R` header block.

**That rationale is wrong.** Verified against the raw field form:

- Office blanks sit at genuine GPS positions — Quesnel ×2 (52.9196, -122.4610) and Prince George ×1
  (53.9570, -122.8265), i.e. the accommodation where filtering happened.
- The PG blank (`196076_ds_ed3`, easting 511387/5978753) shares coordinates with Peace's
  `125179_ds_ed1b` and `125179_us_ed1b` (511387/5978751, 511389/5978753) to within 2 m. Same
  building, recorded across two different projects.
- What is borrowed is the **`site_id`** — `196076_ds_ed3` reuses site 196076. The two `20251005`
  records fall back to a **date** as the site number precisely because no related site was handy.
- Field blanks are streamside: `199267_us_ed1a` is 90 m from its sibling at Driscoll, and
  `23919_ds_ed1b` is 4 m from its sibling at Swift.

The exclusion of office blanks from site tables and the map is still correct — a protocol control
filtered at a hotel is not a stream site. **Reword when porting; do not copy the sentence.**

### Related trap

`utm_easting` / `utm_northing` are empty for **all 93 records across all three regions** — they are
manual-entry form fields nobody fills. The populated pair is `easting` / `northing`, derived from
the form geometry. Already documented at `edna_unbc_results_explore.R:67` and `moti_edna_xref.R:8`
in the template repo, and handled at `0130-tables.R:888` which renames `easting` → `utm_easting`
for display. Reading the manual pair and concluding a record is unlocated is a real failure mode —
it happened during this investigation and produced a fake scoping question about Narcosli Creek.

## Structural constraints

- **`_bookdown.yml` has no `rmd_files:` list** in either repo — merge order is filename sort, so
  reordering means renaming files.
- **Anchors survive renames.** No `\@ref()` targets an appendix; every appendix link is
  markdown-link form against an explicit `{-#anchor}`, and the four site appendices use
  `fpr::fpr_appendix_title()` auto-slugs derived from stream name + PSCIS id. The one oddity is the
  gitbook branch at `0400-results.Rmd:489`, a pandoc *implicit header reference* (bare `[Text]`) —
  binds to heading text, also rename-safe.
- **`scripts/run.R` selects by regex** `stringr::str_subset('0600|2300')`. Renaming
  `0600-appendix.Rmd` breaks it, which is why the build-script split has to precede the renames.
- **Bookdown merge order is load-bearing for the eDNA globals.** `0400-results.Rmd` defines
  `fmt_targets()` and `edna_species_names`; the appendix and every site appendix consume them by
  name. Peace's `0837` carries a comment recording a real bug — a local redefinition drifted from
  Results' Kokanee labelling and produced inconsistent species names in one report, caught by
  `/code-check` 2026-05-05. Do not redefine locally.

## Peace's convention, distilled

1. Thematic `Appendix - …` chapters (`07xx`) first, ordered by first body reference, each with an
   explicit `{-#app-*}` anchor.
2. Phase 1 data+photos (`0835`), then eDNA (`0837`).
3. Per-site Phase 2 habitat-confirmation memos (`0840-*`), ordered by PSCIS id.
4. Per-site effectiveness-monitoring memos (`0860-*`).
5. `Attachment - …` after References/Session Info — **only referenced attachments stay in the
   build**; unreferenced ones go to `hold/`.
6. Every appendix must have an inbound link. peace#33 explicitly added a Methods→UAV link and three
   Results→site-memo links to close orphans.
7. Sub-headings inside unnumbered appendix chapters MUST use `{-}`, or bookdown numbers them.

## Phase 8 — the scope mismatch, located precisely

Fraser's version of the FWCP scope-overclaiming problem is **inverted** relative to Peace's, and
narrower than the plan assumed:

```
index.Rmd:43                     wsg_code <- LCHL NECR FRAN MORK UFRA WILL TABR LSAL   (8)
scripts/gis/climate_departure.R:41  wsg_codes <- LCHL NECR FRAN MORK UFRA TABR WILL    (7, no LSAL)
data/gis/climate_departure_wsg_ecoregion.csv                                           (7 rows)
```

The climate-departure appendix says "seven watershed groups" and lists them explicitly, so it is
**currently honest about its own coverage** — this is not a live misstatement the way the Peace
captions were. The defect is that the seven are **hardcoded in prose** (at least `:78`, `:91`,
`:113`, `:712`) while the analysis extent lives in a script. Add LSAL to the climate run, or drop a
group, and the prose silently goes wrong.

So Fraser does **not** need Peace's `wsg_code_field` split — `wsg_code` is not being used to claim
coverage it lacks. What it needs is the same fix applied to the fish-species caption: derive the
count and the list from `data/gis/climate_departure_wsg_ecoregion.csv`, which already carries
exactly the seven, so prose cannot drift from data.

Separately fixed while sweeping: `0050-executive-summary.Rmd:67` claimed the amalgamated procedures
covered "the Upper Fraser River Watershed" — one group, where the project covers eight. Now derives
from `wsg_names`.

## First Nations section — how to complete it (framing corrected)

Wired the previously commented-out block into Background as `## First Nations` and appended the
nine citations to `references.bib` from xciter's canonical bib (all were missing — a commented
block is invisible to `rbbt` and `update_bib` is FALSE, so uncommenting alone would have produced
nine `[?]` markers).

**My first completeness check was framed wrongly.** I tabulated Nations against watershed groups and
reported "WILL/TABR/LSAL: none named". Watershed groups are a Freshwater Atlas hydrological unit;
presenting Nations as a lookup against them implies territories are non-overlapping cells in a
provincial grid. They are not. The section is correctly a single standalone section and should
stay that way.

**A defensible way to find who to research** — First Nation Statement of Intent boundaries, which
Nations file themselves with the BC Treaty Commission, are queryable via `bcdata`
(record `69ea1b64-e7ce-481c-b0b5-e6450111697d`). Intersected against the eight project watershed
groups, Lheidli T'enneh appears in **all eight** at 78-99% of area in most, and four Nations are
described nowhere in the current section:

    McLeod Lake Indian Band          Lower Salmon, Tabor
    Northern Shuswap Tribal Council  Upper Fraser, Morkill, Willow
    Yekooche First Nation            Nechako, Francois Lake
    Lake Babine Nation               Francois Lake

**Do not generate the section from that layer.** SOI polygons are a treaty-negotiation artifact:
Simpcw is described in the section and has **no SOI polygon at all**, because not every Nation is in
the process — a layer-derived list would have silently dropped them. They overlap by design (shares
sum well past 100% per group) and are not a determination of territory or title. Useful only for
working out who to go read.

The BC PIP Consultation Areas dataset is `Access Only` — a map application at
`maps.gov.bc.ca/ess/hm/cadb/` with no downloadable resource — so it cannot be queried at all.

Filed as **#12**: research from each Nation's own material, draft high level, then send the draft to
each Nation named asking whether they are comfortable with it.

**Structure precedent:** `fish_passage_skeena_2024_reporting` puts Nations as their own sibling
Background sections (`2.2 Wet'suwet'en`, `2.3 Gitxsan`, `2.4 Tsimshian`) rather than nested under a
`First Nations` parent. Worth considering in #12.

## Acknowledgement placeholders — Fraser was shipping them, Skeena was not

`index.Rmd` carried literal `[Nations]`, `[Project-specific connection to territory, governance,
species, or watershed.]` and `[Funding and partner acknowledgements.]`. Verified against
`git show main:docs/index.html` — these **were** in the published Fraser report. Removed; the
acknowledgement now stands on the interconnection framing plus a general territorial sentence,
which is how `fish_passage_peace_2025_reporting` handles it.

I twice claimed `fish_passage_skeena_2024_reporting` had the same placeholders. **Both wrong.**
Skeena's `origin/main` has none — its acknowledgement is the colonialism paragraph only. The
placeholders existed solely in an **unpushed local commit** on this machine (`9ffd0de`), on a
checkout also two commits behind origin.

**Lesson:** do not assert another repo's state from local working files. `git fetch` and read
`origin/main` before making a claim about a repo you are not working in.

`restoration_wedzin_kwa_2024` is the model for the specific version — Yintah, hereditary house
system, balhats, clan-based laws, cited.

## BLOCKER for Phase 9 — Recommendations and exec-summary bullets are Peace content

`0500-recommendations.Rmd:18-27` and `0050-executive-summary.Rmd:113-122` carry the **same
Peace bullet list**, unedited, in a Fraser report:

- "To enhance fish passage restoration in the **FWCP Peace Region**:" — FWCP has no Fraser region;
  `_executive_summary_pdf.Rmd:56` confirms the funder is the **Habitat Conservation Trust
  Foundation** and MoTI
- "especially near **McLeod Lake**" — Peace
- "Secure financial commitments for **Fern Creek** remediation" — Peace
- "bull trout and **Arctic grayling**" — no grayling in the Fraser
- "Collaborate with WLRS, UNC, local fisheries experts, **FWCP**, ..." — wrong funder

The exec summary has an explicit `NEEDS TO BE UPDATED` marker above the list, so the author knew.
`0500-recommendations.Rmd` has the same bullets with **no** marker.

**Deliberately not fixed here.** Relabelling "FWCP Peace Region" to Fraser would make the section
*look* correct while McLeod Lake, Fern Creek and Arctic grayling remain — removing the only signal
that it is unfinished. Writing real Fraser recommendations needs the author's knowledge of Fraser
priorities, not invention. This is Phase 9 work and should block that issue.

Same class: `0400-results.Rmd` Engineering Design carries a rendered `MIGHT NEED TO UPDATE` marker
above prose asserting no new designs were commissioned — unverified for Fraser.

## Additional stale-content items found while working

- **`_output.yml` still points at the template repo.** The gitbook `download:` list names
  `fish_passage_template_reporting.pdf` / `.html`, and the TOC `before:` link is
  `<li><a href="./">Fish Passage Reporting Template</a></li>` with `after:` linking to
  `github.com/NewGraphEnvironment/fish_passage_template_reporting`. Commit `742ab05` fixed
  `book_filename` in `_bookdown.yml` but `_output.yml` was missed. Fold into the Phase 7 staleness
  sweep.
- **Two eDNA samples were recorded against the wrong crossing.** `196076_ds_ed1a` / `_ed1b` sit 8 m
  from PSCIS 203581 (E526469 N5985767) and 1.2 km from 196076 (E527382 N5985006) — they are
  upstream of 203581, not downstream of 196076. The trib-to-fraser appendix already carried an
  inline display remap with a comment explaining the field form was deliberately left alone. That
  transformation is now `edna_site_id_fix()` in `scripts/functions.R` and is applied to the lab
  results in `0400`, the appendix, and the map, so all four surfaces agree.

## Two items that are correctness, not tidiness

- **Scope overclaiming.** No `wsg_code_field` param. Fraser states 7 watershed groups for climate
  departure and 5 in the exec-summary partner text. FWCP flagged Peace for exactly this; Peace fixed
  it by adding a second param (v0.11.0 / v0.13.0) rather than narrowing the shared one, because
  `wsg_code` is correct at seven other call sites.
- **Live DB query.** `0400-results.Rmd:127` runs
  `fpr::fpr_db_query("SELECT * FROM working.fp_sites_tracking")`, so the report does not build from
  a fresh clone. Peace consumes `data/snapshots/fp_sites_tracking.parquet` (v0.1.2).

## Deferred

- **Habitat/connectivity modelling appendix** (Peace's `0760`) — written around Arctic grayling and
  built on `link`; the framing doesn't transfer to Fraser. Wait for a vignette demonstrating
  `link` + `fresh` for experimenting with intrinsic-habitat-potential parameters, then use
  `/vignette-to-appendix`. `0760` stays free so numbering still matches Peace.
- **Narrative pass** (Phase 9) — exec-summary purpose-first reorder, intro bullet collapse,
  `Scales of work` table, `Engage Partners` section, Recommendations expansion. Follow-up issue.
