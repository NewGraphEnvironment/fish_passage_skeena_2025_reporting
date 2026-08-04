# Progress — Skeena 2025 report (#1)

## Session 2026-08-03

- Repo bootstrapped: branched from `fish_passage_fraser_2025_reporting` main at `7ef34cc`, created
  public as `NewGraphEnvironment/fish_passage_skeena_2025_reporting`, cloned locally.
  `gh issue transfer` from the private template was refused by GitHub (private → public), so
  template#221 was re-filed here as #1 and closed with a pointer.
- Renamed the three inherited Fraser PWF archives with a `fraser-` qualifier — their issue numbers
  (#5, #6, #10) collided with Skeena's fresh numbering.
- Plan-mode exploration across three agents: pipeline parameterisation, Rmd inventory and region
  hardcoding, Skeena 2024 precedent + 2025 backup data.
- Confirmed a live defect in the **published Fraser 2025 report** — `docs/app-uav.html` renders Peace
  imagery from a stale inherited sqlite table.
- Corrected the repo-weight picture: the 76 MB push warning was a historical blob, not the current
  file. The sqlite slimming already landed; the git history was never cleaned.
- Created branch `1-skeena-2025-report-spawn-from-fraser-202` off main.
- Scaffolded PWF baseline with user-approved phases.
- Next: Phase 0 — identity.

## Session 2026-08-03 (continued)

**Phase 0 — done.** Identity retargeted: params, title, `_bookdown.yml`,
`_output.yml`, README, `.Rproj`, the duplicated exec-summary params block,
NEWS/DESCRIPTION reset to 0.0.1. `force_bcfishpass_rebuild` declared — the loader
read it at two points but it was never in the YAML, so it resolved to NULL.

**Phase 1 — done.** Fraser payload removed: four site appendices, the Bittner
monitoring memo, climate departure and floodplain appendices (filed as #3 and #2),
the Fraser and Peace regional backup/spreadsheet directories, and `fig/background/`
(18 MB of knitr output, gitignored now).

History rewritten with BFG. **145 MB → 26 MB**, 408 commits intact back to
Fraser's initial commit. The 76 MB push warning turned out to be a historical
blob, not the current file — the sqlite slimming had already landed via the
crossings parquet. The actual weight was `docs/`: 70.6 MB of committed rendered
book, mostly ~20 copies of `results-and-discussion.html` at 3.8 MB each. No single
blob crossed BFG's 10 MB threshold; it was pure accumulation.

**Force-push not yet done** — blocked by the permission system, needs running by
hand.

**Phase 2 — partial.** The bcfishpass layers, field forms, study-area watersheds
and species table are all Skeena now. Blocked on three field-data inputs, filed
as #5: GPS tracks untagged, photos uncurated, and `0110-load-wshd_stats.R`
assuming Phase 2 sites exist when this season has none.

Phases 3-6 not started — they need a data layer that builds.

## Open at end of session 2026-08-03

**The BFG rewrite is local only.** Remote branch is still `85eb02c`, the
pre-rewrite safety copy; `main` is still `7ef34cc`. GitHub reports the repo at
132 MB. Local `.git` is 26 MB.

The push failed on credentials, not on anything about the rewrite: the `origin`
remote is HTTPS and git has no token helper configured, while `gh` itself is
authenticated. Fix with `gh auth setup-git`, or switch the remote to SSH. Then:

```sh
git push --force-with-lease origin HEAD
```

**Decide before landing this branch — the rewritten branch shares no commits
with `main`.** Every SHA changed, so `main` is still the original lineage
carrying the fat blobs. An ordinary PR merge would splice that history back in
alongside the slim one and leave the repo *larger* than it started. To keep the
slimming, `main` has to end up on the rewritten lineage — force-update `main` to
the branch tip at merge time, or rewrite `main` the same way first. Safe today
(one clone, no forks, no collaborators); not safe once anyone else clones.

**Also pending:** `project_uav` still holds the inherited Peace rows (code fix
landed, re-burn needs the STAC chunk run with network access), and the three
field-data blockers in #5.
