# Climate departure appendix for the Skeena (#3) — shipped as v0.2.0

The Fraser report's climate departure appendix was removed when this repo was spawned, because every
input had been generated for the Fraser AOI. This regenerates it for the Skeena and ports the appendix
back.

**The code was the easy part, and the issue had to be corrected before starting.** Exploration found
`scripts/gis/climate_departure.R` already complete — sections 11-15 run the full `cd` pipeline, despite
a header note still claiming that was pending. The change was three region-specific literals, not the
two its header documents. The original issue also asked for `wsg_codes` to read `params$wsg_code`, which
is impossible: the script is standalone, has no caller anywhere in the repo, and never sees `params`.

**The load-bearing work was the prose, and it earned that billing.** Sixteen figures in the appendix
were hardcoded Fraser results. All are now inline R expressions reading the regenerated outputs. Two
claims were wrong in *direction*, not merely stale:

- **The elevation ordering inverts.** Fraser has the interior-plateau ecoregions leading and
  high-elevation ranges trailing. Here the mountains lead (Nass Ranges +2.70 °C, Skeena Mountains
  +2.62) and the plateau ecoregions trail (+2.45, +2.42). Ported verbatim it would have stated the
  opposite of the data beside it.
- **The prioritisation conclusion does not survive.** Fraser argues the spatial gradient is strong
  enough to rank watershed groups for barrier prioritisation. Here every group falls within 0.23 °C of
  every other. The section now reports that null result plainly rather than ranking anything.

A third, smaller: Fraser presents winter and spring snowmelt as counterbalancing rises that both miss
significance. Here spring is +52 % and highly significant while winter misses.

## What the Skeena data shows

Six ecoregions, not eight — and Fraser Basin and Fraser Plateau survive the move, because they extend
north into this AOI. Cumulative warming since 1951 spans +2.42 to +2.70 °C with every ecoregion
significant at p ≈ 0; the recent decade runs +2.07 °C above the 1951-1980 reference with `tmin` rising
faster than `tmax`. The snowmelt midpoint has moved 15 days earlier and summer SWE is down 60 %, both
p < 0.001. Precipitation shows no significant trend anywhere.

The practical finding is a null one: climate departure offers no basis for ranking watershed groups in
this study area. What it does support is a timing argument that applies to every crossing equally.

## Also landed on this branch

Regenerated the NuSEDS stock assessment extract (#6), which needed two fixes first — a download URL
that had gone stale at source (DFO republishes under a new date-stamped name and retires the old), and
a stream-name filter pulling 224 rows of Haida Gwaii escapement into a Skeena table because Waterfall
Creek, one of this season's sites, shares its name with a stream in DFO area 2E. Now constrained to
Area 4 before the name match.

Also corrected two data attachment links, one of them a live 404 pointing at a habitat confirmations
workbook this season never produced.

## Filed upstream

- **fraser#28** — the Fraser report publishes a duplicated watershed-group fragment with an unmatched
  paren, from a hardcoded list half-converted to an inline expression. It came across in the port.
- **template#227** (from the #1 archive) — ~1 GB of dead sqlite blobs in each peer repo's history.

## Considered and rejected

Building this as a `cd` regional vignette via `/vignette-to-appendix`. Better in principle — heavy
inputs precompute into the package rather than this repo, which matters because `output_dir: "docs"`
means report data is committed twice. Not worth it when the report-side generator was three literals
from working and the appendix already existed in report register. Revisit when a fourth region needs
the same edits.

Merged as PR #11, tagged **v0.2.0**.
