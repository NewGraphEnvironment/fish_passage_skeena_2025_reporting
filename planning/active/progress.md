# Progress — Floodplain appendix, Bulkley (#2)

## Session 2026-08-05

- Plan-mode exploration — phases approved by user
- Created branch `2-floodplain-appendix-bulkley-only-pulled` off main (at v0.4.0)
- Established that the issue's central premise is stale: `stac-floodplains-bc` is live with 17 items
  and Bulkley is published as `bulk_co_ff04`, so the delineation does not need to be run
- Verified the `/vsicurl/` read path works (9.3 s, area recomputes to 490.47 km²) before planning
  around it
- Decisions recorded in `task_plan.md`: cache rather than render-time pull; keep STAC layer naming;
  coho network; ff04 only; zoom north of Smithers
- Phases 1-4 complete in three commits: `96b5351` (generator), `87871fd` (appendix + body),
  `86713b4` (build)
- Both formats build clean, zero Citeproc failures on a clean build; the two new bibliography
  entries resolve through rbbt without hand-editing `references.bib`
- PDF verified from the artifact — 133 pages, page 1 reads "Version 0.5.0 DRAFT 2026-08-05"
- Cache 21.3 MB (gpkg 11.64, DEM 9.62). Floodplain reads back at 490.47 km², matching the published
  STAC property exactly
- Next: PR, merge, tag v0.5.0, then `/planning-archive`
