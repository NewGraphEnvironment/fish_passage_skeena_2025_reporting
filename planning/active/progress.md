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
- Next: Phase 3 — per-site results tables
