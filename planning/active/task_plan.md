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

- [x] `0700-appendix-site-assessment-data.Rmd` ← `## Site Assessment Data`; renamed to
      **Assessment Data Summary**; `ld-db` converted to the parquet snapshot (verified lossless
      against the live query first — 757 rows, 26 in project groups, identical)
- [x] Port `scripts/fp_inputs_snapshot.R` and pull `fp_sites_tracking.parquet`; declare `arrow`
      in `packages.R` (neither this repo nor Peace declared it despite depending on it)
- [x] `0710-appendix-fish-species.Rmd` ← `fiss-species-table` from Background; PDF branch pivots
      the wide table to `Present in WSGs`; **caption now derives from the cached table's own
      columns**, not `wsg_names`
- [x] `0740-appendix-uav-imagery.Rmd` ← `tab-uav-imagery` + `rstac` block
- [x] `0750-appendix-collaborative-gis.Rmd` ← `## Collaborative GIS Environment`, moved to the end
      of Results (no `dff-2022` references existed in this repo)
- [x] Fix two Background prose sentences that listed 7 watershed groups, omitting Morkill — both
      now derive from `wsg_names`
- [x] Verify: clean gitbook build, zero `[?]` markers, every new appendix has a real body-text
      inbound link (not just sidebar), fish-species caption renders all 8 groups

## Phase 7 — Ordering pass

- [x] `git mv` to target layout; build scripts updated for the Phase 1 rename
- [x] Confirm 07xx numbering against actual first-reference order — fish-species (0200) <
      climate-departure (0300:22) < floodplain (0300:246) < site-assessment (0400:118) <
      uav (0400:122) < gis (0400:634). eDNA stays at 0837 with Phase 1 at 0835, matching Peace.
- [x] Add explicit named per-site appendix links in the Phase 2 prose
- [x] Park `2200-Attachment_maps.Rmd` in `hold/` (true orphan, Parsnip 2022 URLs) and delete its
      stale rendered page
- [x] **Keep** `2500-Attachment_water_temp_modelling.Rmd` — the audit conflated two adjacent
      paragraphs; its `attach-bayes` link is live and sensible once the neighbouring stale sqlite
      URL is fixed
- [x] Fix stale cross-repo refs — `0400` sqlite link and the `2300` stub now derive from `params`;
      `_output.yml` still carried the template repo's title, GitHub link and PDF download name
- [x] Sweep `Table \@ref()` pointers naming moved tables — three retargeted from "Results and
      Discussion section" to the Assessment Data Summary appendix
- [x] Verify: clean build, zero `[?]`, all four site appendices linked from the Results body,
      rendered chapter order matches the target tiering

## Phase 8 — Correctness fixes

- [x] **`wsg_code_field` NOT needed** — Fraser's mismatch is the inverse of Peace's. `wsg_code` (8)
      is not used to claim coverage it lacks; the climate-departure run covers 7 (no LSAL) and the
      appendix already *said* seven. The defect was that the seven were hardcoded in prose while the
      extent lives in `scripts/gis/climate_departure.R`.
- [x] Derive the climate-departure extent from the `wsgs` layer in the cached geopackage —
      `n_cd_wsg`, `n_cd_wsg_word`, `cd_wsg_codes`, `cd_wsg_list`. Eight hardcoded mentions of
      "seven" and the explicit name/code list now follow the data.
- [x] Build captions from the data — fish-species caption done in Phase 6; climate-departure done
      here
- [x] Audit scope sentences — `0050:67` claimed one watershed group where the project has eight
      (fixed Phase 7); two Background sentences listed 7 and omitted Morkill (fixed Phase 6)
- [x] Confirm parquet conversion — `ld-db` reads the snapshot; verified lossless against the live
      query before swapping
- [ ] Verify: fresh `git clone` + build with no network/DB — **not done**; needs a clean checkout
      in a separate directory

## Phase 10 — Verify and release

- [x] Clean gitbook build — zero unresolved citations book-wide
- [x] Clean pagedown PDF build — 14.4 MB, 175 pages, resting state and `gitbook_on` restored
- [x] Verified in rendered output: no `XXXX`, `NEEDS TO BE UPDATED`, `MIGHT NEED TO UPDATE`,
      `[Nations]`, `FWCP Peace Region`, `McLeod Lake` or `Fern Creek`
- [x] `scripts/bib_repair.R` — replaced the 39-line draft with the template version; 11 keys
      migrated to canonical, canonical entries appended and superseded ones removed
- [x] NEWS.md entry + version bump; also corrected the title page, which read 0.0.1 through two
      releases while DESCRIPTION and the tag said 0.2.1
- [x] Filed the narrative-pass follow-up as #14
- [ ] `/planning-archive`, PR closing #10 and #11 — **not done**, branch is still local

## Handed back to the author

- [ ] Tabor remediation year — no source in Zotero, the corpus, the web, `pscis_remediation_svw`
      or the `[PSCIS1180]` EcoCat link. Text describes the work without a year.
- [ ] Engineering Design reason (harvest uncertainty, unfunded 50% share) — the factual claim
      checks against PSCIS, the reason does not
- [ ] Partner roster in Recommendations — inferred from the repo
- [ ] Tabor intermittent-stream passage cites coho work applied to chinook; flagged in-text as an
      extension

## Validation

- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] Builds from a fresh `git clone` — no cross-repo runtime path, no DB
- [ ] Both output formats render every new appendix
- [ ] No caption claims coverage the underlying data doesn't have
