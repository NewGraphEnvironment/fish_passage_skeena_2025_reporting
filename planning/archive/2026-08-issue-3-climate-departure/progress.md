# Progress — Climate departure appendix for the Skeena (#3)

## Session 2026-08-05

- Explored before planning, and the exploration changed the issue. Rewrote #3: the generator is
  complete rather than half-built, the change is three literals rather than two, and the original
  proposal to make `wsg_codes` read `params$wsg_code` is not possible in a standalone script that never
  sees `params`.
- Weighed building this as a `cd` regional vignette via `/vignette-to-appendix` — better in principle,
  not worth it here. Recorded in `findings.md` with the condition that would change the answer.
- Merged the long-lived spawn branch first. `main` had been 11 commits behind with no PR open,
  including the v0.1.0 release commit itself. Merged as PR #10, tagged **v0.1.0**, #6 auto-closed.
- Archived #1's PWF, carrying forward two loose ends that had no issue: the PDF has never been built
  for this report, and the peer-repo history sweep (dead sqlite blobs still in fraser_2025, peace_2025
  and the template) is unfiled.
- Created branch `3-climate-departure-appendix-swap-the-aoi` off main and scaffolded this baseline with
  the approved phases.
- **Phases 1-4 complete.** Generator retargeted (three literals), tuning constants checked and left
  alone on the evidence, cd pipeline run, appendix ported and every interpretive claim re-derived.
- The load-bearing phase earned its billing. Two conclusions in the Fraser appendix are not merely
  numerically stale on this data — they are wrong in direction. The elevation ordering inverts, and the
  claim that the spatial gradient supports ranking watershed groups does not survive an AOI where all
  five groups sit within 0.23 °C of one another. Both rewritten rather than renumbered.
- Every figure in the appendix prose is now an inline R expression, so the next region gets a
  recomputed number or a build error rather than an inherited one.
- Filed fraser#28: the Fraser report publishes a duplicated watershed-group fragment with an unmatched
  paren, which came across in the port.
- Next: Phase 5 — PDF, cartographic read, NEWS and version bump, PR, merge, tag.
