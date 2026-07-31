# Task: eDNA lab results (#10) + structural alignment with Peace (#11)

Two issues, one branch, one PR closing both.

**#10** — `0400-results.Rmd:744` carries an `INCLUDE LAB RESULTS` placeholder. UNBC returned the
2025 ddPCR batch 2026-04-10; Fraser is the largest of the three regions in it (38 sites / 146
site×target rows) and the only one that hasn't consumed it.

**#11** — Fraser is frozen at v0.2.1 (2026-05-14) while Peace ran to v0.14.0. Nearly every
readability decision Peace accumulated post-dates Fraser's last substantive commit.

Phases 1-8 are in scope. **Phase 9 (narrative pass) is deferred to a follow-up issue.**

## Phase 1 — eDNA data snapshot + Results subsection

- [x] Add `scripts/edna_inputs_snapshot.R` (port from Peace); run it to pull the two analytic CSVs
      from the template repo + write `data/edna_inputs_snapshot_manifest.txt`
- [x] Replace the `INCLUDE LAB RESULTS` stub with the `tab-edna-summary-prep` chunk — defines
      `norm_lgl()`, `fmt_targets()`, `edna_species_names`, `edna_bystargets_fraser`,
      `edna_real_fraser`, `edna_summary_fraser` and the three count objects
- [x] `SOCK = "Sockeye Salmon"` with a comment on the divergence from Peace's Kokanee
- [x] Two narrative paragraphs + `tab-edna-summary` table
- [x] Verify: counts render 33 real / 2 field / 3 office; 36 clean site×target

## Phase 2 — eDNA thematic appendix + interactive map

- [x] `0837-appendix-edna.Rmd` — `{-#app-edna}`, prep chunk (no local redefinition of
      `fmt_targets`/`edna_species_names`), three `fpr::fpr_kable` tables: per-site, field blanks,
      retests (guarded on `nrow() > 0`; Fraser has 8 retests so it renders)
- [x] Reword the office-blank rationale — do NOT copy Peace's "inherited coords"/"fake coords"
      wording; office blanks are protocol controls filtered at accommodation
- [x] `scripts/edna_map_fraser.R` — port of `edna_map_peace.R`; drop `GRAY`, script the `docs/` copy
- [x] Fix `norm_lgl()` logical-NA short-circuit (ported bug — see findings.md)
- [x] `.gitignore` the htmlwidgets `data/*_files/` sidecar (rule missing in this repo)
- [x] Verify structurally: office blanks absent from map, field blanks present in Controls layer,
      all six species layers + All sites + Sub-threshold, zero external `src` refs, 35 site ids
- [ ] Verify visually: map opens and layers toggle — **outstanding**, browser extension not
      connected this session

## Phase 3 — eDNA per-site results tables

- [x] Add `tab-edna-results-{site}-prep` + render chunk to each of the four site appendices
      (126158, 196085, 196332, 203581), alongside the existing `tab-edna-{site}`
- [x] `edna_site_id_fix()` in `scripts/functions.R` — two samples were recorded against the wrong
      crossing; applied in `0400`, `0837` and the map so all surfaces agree
- [x] Verify table contents standalone: 14 sites across the four appendices, retest asterisks
      correct, corrected ids sort in
- [x] Verify: clean gitbook build — 385 chunks, `Output created: docs/index.html`, zero missing
      citations. All four per-site tables render; Results shows "Sockeye Salmon".

*eDNA complete and shippable here — #10 closable.*

## Phase 4 — Build-script split (unblocks the renames)

- [x] Port `scripts/run_gitbook.R` / `run_pagedown.R` from Peace/template, replacing `run.R`
- [x] Add the `options(repos=)` CRAN-mirror line — `packages.R` calls `available.packages()`
      unconditionally, which halts any bare-Rscript build
- [x] Fix the duplicated Phase 1 appendix — resting state = inline appendix at root, `2300` in `hold/`
- [x] Replace the `str_subset('0600|2300')` regex with explicit filenames
- [x] Remove `scripts/run.R` and its now-dead `hold/` helpers; update README build section
- [x] Verify: gitbook renders exactly one Phase 1 page (stale `docs/attach-pdf-phase1-dat.html`
      from May 14 removed); PDF build swaps the stub in and restores resting state + `gitbook_on`

## Phase 5 — Deletion pass *(rescoped — the premise was wrong)*

The audit called ~50 lines in `0200-background.Rmd` "commented-out Nations content" contributing to
bloat. On inspection it is researched, cited prose and the raw material for open issue #3. Two other
"dead" chunks turned out to be provenance for numbers quoted in the report. Actual deletable content
was one Peace-specific block.

- [x] **Not deleted** — `wsh-areas` (`0200:134-150`) and `stock-assess-download` (`0200:389-448`)
      are live `fwapgr` / NuSEDS queries that produced values and files the report uses
- [x] **Wired in instead** — the Nations block is now `## First Nations`, trimmed for brevity,
      `Shuwap` → `Shuswap`, Carrier Sekani promoted out from under Dakelh (the Tribal Council spans
      Carrier *and* Sekani nations)
- [x] Append the 9 citations to `references.bib` from xciter's canonical bib — all were missing,
      since a commented block is invisible to `rbbt` and `update_bib` is FALSE
- [x] Delete `remediations-text` (`0400`) — Peace content (PSCIS 125231, Chuchinka-Table FSR)
- [x] Verify: clean gitbook build, **zero `[?]` markers book-wide**, all 9 new sources in the
      rendered reference list
- [ ] **Blocked, needs author** — Recommendations + exec-summary bullets are unedited Peace content
      (FWCP Peace Region, McLeod Lake, Fern Creek, Arctic grayling). Not relabelled on purpose;
      see findings.md. Goes to the Phase 9 follow-up issue.
- [ ] **Needs author** — First Nations section names no Nation for WILL, TABR or LSAL, the three
      groups added in 2025. Not inferred from maps.

## Phase 6 — Extraction pass

- [ ] `0700-appendix-site-assessment-data.Rmd` ← `## Site Assessment Data` (`0400:116-310`);
      rename section to **Assessment Data Summary**; convert `ld-db` to the parquet snapshot
- [ ] `0710-appendix-fish-species.Rmd` ← `fiss-species-table` (`0200-background.Rmd:490-520`);
      PDF branch pivots wide table to `Present in WSGs`
- [ ] `0740-appendix-uav-imagery.Rmd` ← `tab-uav-imagery` + `rstac` block (`0400:242-347`)
- [ ] `0750-appendix-collaborative-gis.Rmd` ← `## Collaborative GIS Environment`; move to end of
      Results and Methods; drop `dff-2022` references
- [ ] Every new appendix: `{-#app-*}` anchor, `{-}` on every subheading, no bold headings,
      `gitbook_on` online-redirect
- [ ] Verify: each new appendix has an inbound body link; clean build both formats

## Phase 7 — Ordering pass

- [ ] `git mv` to target layout — renames only, no content edits in the same commit
- [ ] Confirm 07xx numbering against actual first-reference order
- [ ] Add explicit named per-site appendix links at `0400-results.Rmd:518`
- [ ] Park `2200-Attachment_maps.Rmd` and `2500-Attachment_water_temp_modelling.Rmd` in `hold/`
- [ ] Fix stale cross-repo refs at `2300:3-4` and `0400-results.Rmd:433`
- [ ] Sweep every `Table \@ref()` pointer naming a moved table (`0050-executive-summary.Rmd:67`)
- [ ] Verify: every anchor resolves; no page reachable only from the sidebar

## Phase 8 — Correctness fixes

- [ ] Add `wsg_code_field` to `index.Rmd` params — do NOT narrow `wsg_code`
- [ ] Build captions from watershed-group columns actually present in the cached table
- [ ] Audit every caption and scope sentence against the data behind it
- [ ] Confirm parquet conversion — report builds with no DB access
- [ ] Verify: fresh `git clone` + build, no network/DB

## Phase 10 — Verify and release

- [ ] Clean gitbook build (`rm _main.Rmd` first)
- [ ] Clean pagedown PDF build
- [ ] Grep output for `Citeproc.*not found` and unresolved `\@ref`
- [ ] `scripts/bib_repair.R` — Fraser is the last repo not on canonical citation keys
- [ ] NEWS.md entry + version bump in `index.Rmd`
- [ ] File the Phase 9 narrative-pass follow-up issue
- [ ] `/planning-archive`, PR closing #10 and #11

## Validation

- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] Builds from a fresh `git clone` — no cross-repo runtime path, no DB
- [ ] Both output formats render every new appendix
- [ ] No caption claims coverage the underlying data doesn't have
