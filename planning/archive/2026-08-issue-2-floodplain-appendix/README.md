# Floodplain appendix — Bulkley, read from stac-floodplains-bc (#2)

**Closed by** `87871fd` / `96b5351`, released as **v0.5.0**, then extended through v0.6.1.

## Outcome

Added a floodplain delineation appendix for the Bulkley River watershed group, matching how the Peace and Fraser reports present the same analysis. Modelled functional floodplain covers 483 km² — 6.2 % of the 7,762 km² group — attached to 1,587 km of the 2,206 km coho accessible order-3+ network.

**The issue's central premise was already overtaken when work began.** It stated that `stac_floodplains_bc` was scaffolding with nothing registered, so the delivery route could not be demonstrated. The collection was in fact live with 17 items across 16 watershed groups, and Bulkley was published as `bulk_co_ff04` — so the valley confinement model never needed running. The report caches the published product instead, and the cached layer keeps the catalogue's own layer name so it stays traceable to its item.

Verified by reading it back: **490.47 km²**, matching the published STAC property exactly.

## What this surfaced

- **The network attribution was wrong, and was corrected in v0.6.0.** Methods and appendix credited the delineation's stream network to `bcfishpass`. It was built by `link` orchestrating `fresh` over fwapg — a different pipeline, aligned with bcfishpass by intent rather than construction. The reported stream lengths are measured on the bcfishpass network rather than the delineation's own, which cannot be fixed from the catalogue because the network is not published. Raised as NewGraphEnvironment/stac_floodplains_bc#17, tied to NewGraphEnvironment/link#127.
- **Three cartographic defects, all invisible in source review and obvious in the rendered PNG.** Parks and floodplain were both green, and Babine Mountains Park is larger than any single floodplain unit here, so the map appeared to show two classes of floodplain — **this defect is still latent in Peace and Fraser**. White bands from a device aspect that did not match the data. An unreadable label pile from full legal municipality names plus 17 reserve labels.
- **The proximity trim does not work in a settled valley.** 21,667 of 21,781 roads already fall within 5 km of the floodplain. Vertex simplification on cartography-only layers was the lever that worked: 28.6 MB → 21.3 MB.
- **The waterbody counts are near-tautological** — waterbodies were an input to the valley confinement model, so "lakes within floodplain" restates "lakes on the accessible network". Inherited from Peace and Fraser; disclosed in the prose but worth reconsidering across all three.

## Still open

- Record the added weight (21.3 MB: gpkg 11.64, DEM 9.62) on the repo-bloat issue
- `/code-check` was never run on these commits; verification was clean builds, Citeproc counts and artifact checks

See `findings.md` for the full research log and `task_plan.md` for the phase-by-phase record.
