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
