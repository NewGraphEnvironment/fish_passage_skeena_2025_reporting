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
- Next: Phase 1 — eDNA data snapshot + Results subsection
