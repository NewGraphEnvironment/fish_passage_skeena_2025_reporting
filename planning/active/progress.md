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

### Phase 5 — deletion pass, rescoped ✔ (two items need the author)

The plan's premise did not survive inspection. What the audit called ~50 lines of "commented-out
Nations content" is researched, cited prose and the raw material for open issue #3. Two other
`eval=F` chunks are provenance, not dead code.

- **Kept, not deleted:** `wsh-areas` and `stock-assess-download` — live `fwapgr` / NuSEDS queries
  behind values and files the report uses.
- **Wired in:** the Nations block is now `## First Nations` in Background. Trimmed the Ancient
  Forest tangent (~150 → ~55 words) and Nazko's business history; corrected `Shuwap` → `Shuswap`;
  promoted Carrier Sekani out from under Dakelh since the Tribal Council spans Carrier *and* Sekani
  nations. Added a framing sentence marking the summaries as context, not a statement of rights or
  title.
- **Citations:** all 9 were missing from `references.bib` — a commented block is invisible to
  `rbbt` and `update_bib` is FALSE, so uncommenting would have produced 9 `[?]` markers. Appended
  from xciter's canonical bib. All are the Nations' own published sources.
- **Deleted:** `remediations-text` — Peace content (PSCIS 125231, Chuchinka-Table FSR).
- **Verified:** clean gitbook build, zero `[?]` markers book-wide, all 9 sources in the rendered
  reference list.

**Two items handed back rather than guessed at:**

1. Recommendations (`0500`) and the exec-summary bullets are unedited Peace content — FWCP Peace
   Region, McLeod Lake, Fern Creek, Arctic grayling. Deliberately not relabelled: making the heading
   say Fraser while the bullets stay Peace-specific would erase the only signal it is unfinished.
2. The First Nations section names no Nation for WILL, TABR or LSAL — exactly the three watershed
   groups added in 2025. Territory attribution needs the Nations' own statements or the BC
   Consultative Areas Database, not inference from a map.

- Next: Phase 6 — extraction pass

### Phase 6 — extraction pass ✔

Four appendices created. Results **897 → 635 lines**, Background **626 → 602**.

| New appendix | Source |
|---|---|
| `0700` Assessment Data Summary | `## Site Assessment Data` + its four tables |
| `0710` Fish Species | `fiss-species-table` from Background |
| `0740` UAV Imagery | `tab-uav-imagery` + the `rstac` block |
| `0750` Collaborative GIS Layers | `## Collaborative GIS Environment`, moved to end of Results |

Two Phase 8 correctness items landed here because the code moved anyway:

- **`ld-db` reads the parquet instead of postgres.** Checked live-vs-snapshot before swapping —
  757 rows, 26 in project watershed groups, identical per-group counts — so the swap is lossless.
  The report no longer needs a database. `arrow` added to `packages.R`; neither this repo nor Peace
  declared it despite depending on it.
- **Fish-species caption derives from the cached table's columns**, not `wsg_names` (Peace v0.13.0
  fix), so it cannot claim coverage the extract lacks. While there, found two Background prose
  sentences listing **7** watershed groups and omitting Morkill; both now derive from `wsg_names`.
  The rendered caption reads all 8.

Verified: clean gitbook build, zero `[?]` markers book-wide, and every new appendix has a real
body-text inbound link (checked with the sidebar nav stripped — the naive grep matches every page).

- Next: Phase 7 — ordering pass

### Phase 7 — ordering pass ✔

Renamed to first-reference order and verified against a clean build. Rendered order now matches
Peace's tiering: thematic appendices (fish-species, climate-departure, floodplain, assessment-data,
UAV, GIS) → Phase 1 → eDNA → per-site memos → References/Session Info → Attachments.

- Phase 1 appendix `0600` → `0835-appendix-phase1-data-photos`; site memos `0800-*` → `0840-*`.
  Build scripts needed one constant changed each — the Phase 4 switch from a numeric-prefix regex
  to explicit filenames is what made the rename safe.
- **De-orphaned the four site appendices.** They had no inbound link at all, only unlinked prose.
  Added named links to the auto-generated slugs, Peace's `0400:286` pattern.
- **Parked `2200-Attachment_maps.Rmd`** — zero inbound links and hardcoded Parsnip 2022-05-27 URLs.
  Deleted its stale rendered page.
- **Kept `2500-Attachment_water_temp_modelling.Rmd`.** The audit called it a near-orphan whose only
  reference sat in a stale paragraph — but those are two *adjacent* paragraphs. The stale sqlite URL
  and the `attach-bayes` link are separate; fixing the URL leaves the reference sound. Not parked.
- Stale cross-repo references fixed: the `0400` sqlite link and the `2300` stub now derive from
  `params` instead of hardcoding `fish_passage_peace_2024_reporting`. `_output.yml` still carried
  the *template* repo's TOC title, GitHub link and PDF download filename.
- **Mandatory pointer sweep** after Phase 6: three "Results and Discussion section" pointers now
  aim at the Assessment Data Summary appendix. `0050:67` also claimed coverage of "the Upper Fraser
  River Watershed" — one group where the project has eight; now derives from `wsg_names`.

- Next: Phase 8 — the remaining scope fix

### Phase 8 — correctness fixes ✔ (one verification outstanding)

**The plan's premise was wrong here too, in a useful direction.** Peace needed `wsg_code_field`
because its captions listed 16 watershed groups while the data covered 5. Fraser's mismatch is the
inverse and milder:

```
index.Rmd:43                       wsg_code    LCHL NECR FRAN MORK UFRA WILL TABR LSAL  (8)
scripts/gis/climate_departure.R:41 wsg_codes   LCHL NECR FRAN MORK UFRA TABR WILL       (7)
```

The climate-departure appendix already *said* "seven watershed groups" and listed them, so it was
honest about its own coverage — not a live misstatement. Adding `wsg_code_field` would have been
cargo-culting Peace's fix onto a different problem.

The actual defect: the seven were **hardcoded in prose** in eight places while the extent lives in a
script. Add LSAL to the climate run and the prose silently goes wrong. Fixed by deriving
`n_cd_wsg`, `n_cd_wsg_word`, `cd_wsg_codes` and `cd_wsg_list` from the `wsgs` layer in the cached
geopackage — the same derive-from-data fix applied to the fish-species caption in Phase 6.

Caught and fixed a bug I introduced doing it: wrapping a `fig.cap` in `paste0()` without closing the
paren, which swallowed `fig.height` into the call.

**Outstanding:** a genuine fresh-`git clone` build with no network or DB. The pieces are in place
(parquet snapshot, no live query) but it has not been executed in a clean checkout.

### Acknowledgement placeholders removed

`index.Rmd` was publishing literal `[Nations]`, `[Project-specific connection to territory,
governance, species, or watershed.]` and `[Funding and partner acknowledgements.]`. Confirmed
against `git show main:docs/index.html` — genuinely in the published report, not just source.

Removed. The acknowledgement now carries the interconnection framing, the colonialism paragraph, and
a general territorial sentence — complete on its own. `fish_passage_peace_2025_reporting` runs with
just the first paragraph; `restoration_wedzin_kwa_2024` is the model for the specific version.

Filed **#12** to research the `## First Nations` section from each Nation's own published material,
draft it high level, and send the draft to each Nation named for review before it goes out. #3 stays
open for the project-specific territorial acknowledgement, which the same research feeds.

**A mistake worth recording:** I twice claimed `fish_passage_skeena_2024_reporting` had the same
placeholders — once as "shipping", once as "in source". Both wrong. Skeena's `origin/main` has none;
what I read was an unpushed local commit on a checkout two commits behind origin. Retracted in #12
and #3. Do not assert another repo's state from local working files — `git fetch` and read
`origin/main` first.

### Bittner Creek monitoring appendix

Traced the effectiveness-monitoring history properly rather than filling in the `XXXX` placeholders
by guess.

**Sources.** Our own MoTI report was not citable — no Zotero entry, no `CITATION.cff`, absent from
xciter's canonical bib, despite the repo→Zotero sync convention. Created it via the Web API
(`9Q4EJ8US`) with `Citation Key: irvine2024EffectivenessMonitoring` pinned in Extra so it cannot
drift. Seven bib entries added in total: five from canonical, two hand-written.

**Tabor's remediation year remains unsourced.** Checked Zotero, the 300-report Fraser corpus, the
web, `pscis_remediation_svw` (no record for 196085, 196200 *or* 203582), and the `[PSCIS1180]`
EcoCat link, which resolves only to Hooft 2015 — the 2014 assessment. The Results text now describes
the work without asserting a year, and no longer says "replaced": PSCIS still ranks 196085 a barrier
and the 2019 work was backwatering, outlet-drop removal and baffles.

**A third site-id mislabel.** `196209_us_ed1` sits 29 m from PSCIS 196200 (Bittner) and 6.5 km from
196209 (Hudson Bay Slough, Oak Street). Added to `edna_site_id_fix()`; without it Bittner's only
eDNA result was attributed to an unrelated crossing and was wrong on the published map.

**What the appendix says.** Three lines of evidence from three years disagree, and that is the
finding: the 2022 assessment records a landowner reporting no salmon in thirty years and annual
dewatering, while noting parr in isolated pools; DWB salvaged eight juvenile chinook in June 2023;
the 2025 eDNA sample returned zero droplets across all four assays and two runs. Stated as a reason
a single grab is a weak instrument on an intermittent system, not as evidence of absence.

Carries the intermittent-stream argument with all three citations, and two constraints still open
upstream: CN crossing `19703286` remains unassessed four years after we recommended it, and PSCIS
196197 on Hwy 16 E is still a barrier — so the reach the bridge opened is bounded.

Did not inherit the source report's before-photo caption, which reads "Cross Creek" in the Bittner
section.
