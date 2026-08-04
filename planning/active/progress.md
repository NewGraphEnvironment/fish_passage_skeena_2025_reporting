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
