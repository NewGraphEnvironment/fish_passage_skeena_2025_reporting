# Skeena 2025 spawn from Fraser (#1) — shipped as v0.1.0

Branched from `fish_passage_fraser_2025_reporting` at `7ef34cc` for its thematic appendix structure,
eDNA appendix and monitoring memo pattern, then retargeted throughout: watershed groups BULK, MORR,
ZYMO, KISP, KLUM, the `sern_skeena_2023` GIS project, steelhead as the modelled species, and a
background chapter ported from `fish_passage_skeena_2024_reporting`.

The season was reported as what it was — a monitoring and eDNA season, with two PSCIS reassessments,
two effectiveness monitoring sites and twenty eDNA samples, and no Phase 1 or Phase 2 work. Three
scripts assumed at least one Phase 2 site existed and failed on the empty case; all guarded.

**The durable finding** is the one recorded in `findings.md` and now in machine memory: a spawned
repository inherits every table its ancestor committed to `data/bcfishpass.sqlite`, and the tables
written by scripts `index.Rmd` never sources are the ones nobody re-runs. UAV imagery held Peace
records, photo metadata held the ancestor's URLs, site watersheds held the ancestor's sites. All three
regenerated or dropped, on the principle that an absent map layer is visibly missing where another
region's data looks like an answer. The same defect was found live in Fraser and fixed there
(fraser#19).

Merged as PR #10, tagged **v0.1.0**. Closed #6 along the way.

## Archived with work outstanding — where it went

The umbrella issue #1 stays open; the appendix port is not finished. Unchecked boxes in `task_plan.md`
are either stale (the work landed, the checkbox was never flipped — the BFG force-push, the
`project_uav` re-burn, the v0.1.0 release) or now tracked separately:

| Outstanding | Tracked as |
|---|---|
| Floodplain appendix, Bulkley only | #2 |
| Climate departure appendix | #3 |
| Harvest the Wedzin Kwa work | #4 |
| GPS tracks untagged, photos uncurated | #5 |
| Site maps for the monitoring appendices | #9 |

**One loose end had no issue and would have been lost here**, now filed as
NewGraphEnvironment/fish_passage_template_reporting#227: the dead `bcfishpass.sqlite` blobs this repo
was BFG'd to remove still sit in the peer repos. Measured 2026-08-05 — 37 blobs / 1052 MB in the
template, 37 / 1052 MB in `peace_2025`, 31 / 901 MB in `fraser_2025`, and **zero** here. Riskier there
than it was here, because those repos have other clones and a history rewrite changes every SHA.

**A second one turned out to be a stale checkbox, not a loose end.** `task_plan.md` carries
"PDF (`run_pagedown.R`) not attempted", and that is wrong — `docs/fish_passage_skeena_2025_reporting.pdf`
is committed at 6.2 MB and reads Version 0.1.0, last written in `6cfe322`. It trails `main` by the
NuSEDS commit, which the next release regenerates. Worth noting how many boxes in that file are stale in
the same direction: the BFG force-push, the `project_uav` re-burn (verified returning `skeena`, 170
rows), and the v0.1.0 release are all done and all still show unchecked. **Read the artifact, not the
checkbox.**

Also inherited: this repo's remote carries **Fraser's `v0.3.0` and `v0.3.1` tags** from the spawn. Unlike
the stray tags that a `git fetch template` drops into a report repo, these are genuine ancestors of
`main` here, so they are not deletable as foreign — they are simply Fraser's release names sitting in
Skeena's namespace. This repo's own releases start at `v0.1.0`.
