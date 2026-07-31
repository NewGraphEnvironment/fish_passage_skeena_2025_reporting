# Progress — eDNA (#10) + structural alignment (#11)

## Session 2026-07-31

- Confirmed no prior eDNA issue existed in this repo; filed **#10** (eDNA integration) and
  **#11** (structural alignment with Peace)
- Plan-mode exploration: two audits — Fraser appendix cross-references / first-reference order /
  orphans, and the full inventory of Peace structural decisions from NEWS + peace#12/#18/#33/#36
  + planning archive
- Verified the Fraser eDNA data end to end (33 real / 2 field / 3 office; 36 clean site×target
  detections; all real samples inside `params$wsg_code`)
- Corrected Peace's stated rationale for dropping office blanks — coordinates are real GPS at
  accommodation, the borrowed field is `site_id`. Recorded in findings.md so the wrong sentence
  isn't copied forward.
- Scope approved: **phases 1-8**. Phase 9 (narrative pass) deferred to a follow-up issue.
  Habitat/connectivity appendix left out pending a `link`/`fresh` vignette.
- Created branch `10-edna-and-structural-alignment` off main @ `d22bf2d`
- Scaffolded PWF baseline

### Phase 1 — eDNA data snapshot + Results subsection ✔

- `scripts/edna_inputs_snapshot.R` ported and run — snapshotted both analytic CSVs from template
  repo @ `189fdb1` (clean tree). md5s match the Peace snapshot exactly, so all three regional
  reports are working from identical source data.
- Replaced the `INCLUDE LAB RESULTS` stub with the `tab-edna-summary-prep` chunk + two narrative
  paragraphs + `tab-edna-summary`.
- **Divergence from the Peace source:** filter derives from `params$gis_project_name` rather than a
  hardcoded region string. Peace hardcodes `sern_peace_fwcp_2023` in three separate places; deriving
  it means the Fraser copy has one less thing to get wrong on the next port.
- `SOCK = "Sockeye Salmon"` (Peace uses Kokanee — landlocked above the Peace Canyon Dam).
- Office-blank comment rewritten to state the real reason rather than Peace's "fake coords".
- Verified the prep logic standalone: 33 real / 2 field / 3 office; RAIN 20 sites detected, CHIN 9,
  BULT 5, SOCK 1, BURB 1; `fmt_targets()` handles the empty case. Render itself is verified at the
  first clean build (Phase 3).

### Phase 2 — thematic appendix + interactive map ✔ (one visual check outstanding)

- `0837-appendix-edna.Rmd` created with `{-#app-edna}` and the three tables. Fraser has 8 retests,
  so the retest table renders rather than falling through to the "no retests" branch.
- `scripts/edna_map_fraser.R` — 33 sites mapped, 3 office blanks dropped, 2 field blanks routed to
  the hidden Controls layer. Copies itself to `docs/` so `params$report_url` resolves; Peace does
  that copy by hand.

**Two defects found in the Peace source and fixed rather than ported:**

1. **`norm_lgl()` short-circuits on logical input.** `readr` types the control-flag columns as
   logical when the CSV holds TRUE/FALSE/NA, so `if (is.logical(x)) return(x)` returns the NAs
   untouched. `any()` over a vector containing NA is NA, so `Pos. control` rendered as NA rather
   than blank for every site without a positive control. Affects 262 of 354 rows across all three
   regions, so Peace has it too. Fixed here, and `norm_lgl()` is now defined once in `0400` instead
   of separately in the appendix — Peace keeps two copies, which is how a fix to one misses the other.
2. **`species_colors` paired positionally.** Peace `setNames()`es a 7-colour vector against its
   species list; dropping GRAY (absent from the Fraser batch) left an unnamed 7th colour and the
   categorical legend errored on the length mismatch. Rewrote as an explicitly named vector with
   `species_list <- names(species_colors)` so the two cannot diverge.

- Verified structurally: office-blank site ids absent from the HTML, both field-blank ids present,
  all six species layers plus All sites and Sub-threshold, zero external `src` refs (genuinely
  self-contained), 35 distinct site ids = 33 real + 2 field blanks.
- **Outstanding:** visual confirmation that the map opens and layers toggle. The browser extension
  isn't connected this session.

### Phase 3 — per-site results tables ✔

- `tab-edna-results-{site}` added to all four site appendices. 14 of the 33 real samples fall here.
- Found and fixed a **site mislabel**: `196076_ds_ed1a`/`_ed1b` sit 8 m from PSCIS 203581
  (E526469 N5985767) and 1.2 km from 196076 (E527382 N5985006) — they are upstream of 203581. The
  trib-to-fraser appendix already carried an inline display remap; lifted it to
  `edna_site_id_fix()` in `scripts/functions.R` and applied it to the lab results in `0400`, the
  thematic appendix and the map so all four surfaces agree.

### Phase 4 — build-script split ✔

Ported `run_gitbook.R` / `run_pagedown.R` from Peace, removed `run.R` and its dead `hold/` helpers,
updated the README build section.

**Three problems fixed, all of which Peace also has or had:**

1. **No CRAN mirror under `Rscript`.** `scripts/packages.R:1-9` calls `available.packages()`
   *unconditionally* — not gated by `params$update_packages` — so any non-interactive build dies
   with "trying to use CRAN without setting a mirror". This killed my first build attempt. Peace
   solves it with an `options(repos=)` line at the top of each run script.
2. **Duplicate Phase 1 appendix in gitbook.** The old `run.R` selected files with
   `str_subset('0600|2300')` and parked `0600` for the PDF, but never parked `2300` for gitbook —
   so the web report shipped the full appendix *and* its link-stub as separate chapters.
   `docs/attach-pdf-phase1-dat.html` was a stale May 14 artifact and is removed.
3. **Regex file selection.** Replaced with explicit filenames so the Phase 7 renumbering can't
   silently change which files get swapped.

**Both builds verified:**

- gitbook — 385 chunks, `Output created: docs/index.html`, **zero missing citations**, no errors.
  `docs/app-edna.html` renders; Results reads "Sockeye Salmon"; all four per-site tables present.
- pagedown — 12.7 MB / 159 pages. Swap ran (`0600 -> hold/`, `2300 -> root`) and the resting state
  plus `gitbook_on <- TRUE` were restored on exit. eDNA sections all present.
  (`pdftotext` can't extract the `fi` ligature, so "field"/"office" read as "eld"/"of ce" in
  extracted text only — the rendered PDF is correct.)

Incidental rebuild churn in `data/bcfishpass.sqlite` and three `fig/background/*.png` was reverted —
same byte counts, nothing in this change should alter them.

- Next: Phase 5 — deletion pass
