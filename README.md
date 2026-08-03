# Restoring Fish Passage in the Fraser Region — 2025

> Reproducible, web-first fish-passage restoration-planning report for the Fraser Region, prepared on behalf of the Society for Ecosystem Restoration in Northern BC (SERN).

**Read the report:** <https://www.newgraphenvironment.com/fish_passage_fraser_2025_reporting/>
&middot; **Source:** [`NewGraphEnvironment/fish_passage_fraser_2025_reporting`](https://github.com/NewGraphEnvironment/fish_passage_fraser_2025_reporting)
&middot; **Version history:** [`NEWS.md`](NEWS.md)

## What this is

The 2025 iteration of the Fraser Region fish-passage restoration-planning report. Assembles crossing-by-crossing assessments, fish-presence and habitat-confirmation data, and prioritization analyses across the region. Each prioritized barrier has a dedicated appendix with photos, field measurements, and recommended remediation; the executive summary rolls them up for partners and decision-makers. A standalone executive-summary PDF is built alongside the gitbook so the headline findings can travel without the full report. Source data and methods are open — anyone can rebuild the report from the scripts in `scripts/` (see [Build](#build)).

## Build

Two self-contained scripts. Each sources `scripts/staticimports.R` (which inlines helper functions via the [staticimports](https://github.com/wch/staticimports) package) before rendering, so run them rather than calling `bookdown` directly or you'll hit "undefined function" errors:

```sh
Rscript scripts/run_gitbook.R    # web (gitbook) version -> docs/
Rscript scripts/run_pagedown.R   # print PDF -> docs/<repo>.pdf
```

`run_gitbook.R` builds the full report with the inline Phase 1 data+photos appendix. `run_pagedown.R` swaps that heavy appendix for a slim link-stub so the print PDF stays light, and restores the resting layout afterwards even if the render fails.

## Open-source packages used

| Package | Role |
|---|---|
| [`fresh`](https://github.com/NewGraphEnvironment/fresh) | FWA stream-network primitives + habitat classification driving accessible / spawning / rearing layers. |
| [`link`](https://github.com/NewGraphEnvironment/link) | Cross-system crossing matching + barrier-override resolution from observation evidence. |
| [`ngr`](https://github.com/NewGraphEnvironment/ngr) | Reporting utilities — table formatting, S3 helpers, STAC, GitHub-issue scraping. |
| [`fpr`](https://github.com/NewGraphEnvironment/fpr) | Fish-passage-specific reporting functions (PSCIS tables, crossing details). |
| [`gq`](https://github.com/NewGraphEnvironment/gq) | Cartographic style registry across the report's maps. |
| [`cd`](https://github.com/NewGraphEnvironment/cd) | Climate-departure analysis for the climate context appendix. |

External: [`bcfishpass`](https://github.com/smnorris/bcfishpass), [`fwapg`](https://github.com/smnorris/fwapg).

## License

MIT (see [`LICENSE`](LICENSE)).
