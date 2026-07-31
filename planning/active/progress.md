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
- Next: Phase 2 — thematic appendix + interactive map
