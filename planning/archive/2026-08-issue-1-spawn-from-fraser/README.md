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

**Two loose ends had no issue and would have been lost here:**

1. **The PDF has never been built for this report.** Only gitbook has been rendered. `run_pagedown.R`
   exists but has not been run, so the paged output is unverified — and the template's PDF path has a
   known trap (`render_book(envir = globalenv())`).
2. **Peer-repo history sweep.** The same dead sqlite blobs this repo was BFG'd to remove still sit in
   `fish_passage_fraser_2025_reporting` (~168 MB), `fish_passage_peace_2025_reporting` (~298 MB) and
   `fish_passage_template_reporting` (~402 MB). Riskier there than here, because those repos have other
   clones and a force-push needs coordination. This repo's rewrite is the working recipe.

Related and still true: this repo's remote carries **Fraser's `v0.3.0` and `v0.3.1` tags**, inherited on
the spawn. They pin old objects and are part of why GitHub still reports ~198 MB.
