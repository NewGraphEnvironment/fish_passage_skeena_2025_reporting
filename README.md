# Restoring Fish Passage in the Skeena Region — 2025

> Reproducible, web-first fish-passage restoration-planning report for the Skeena Region, prepared on behalf of the Society for Ecosystem Restoration in Northern BC (SERN).

**Read the report:** <https://www.newgraphenvironment.com/fish_passage_skeena_2025_reporting/>
&middot; **Source:** [`NewGraphEnvironment/fish_passage_skeena_2025_reporting`](https://github.com/NewGraphEnvironment/fish_passage_skeena_2025_reporting)
&middot; **Version history:** [`NEWS.md`](NEWS.md)

## What this is

The 2025 iteration of the Skeena Region fish-passage restoration-planning report, covering the Bulkley, Morice, Zymoetz, Kispiox and Kalum watershed groups.

The 2025 field season was a **monitoring and environmental DNA season** rather than an assessment season: two post-remediation effectiveness-monitoring sites, two PSCIS reassessments, and a 20-sample eDNA program across 11 streams. The report is shaped accordingly — the eDNA program and the two monitoring memos carry the substance, alongside the amalgamated assessment record from earlier years.

Source data and methods are open — anyone can rebuild the report from the scripts in `scripts/` (see [Build](#build)).

Spawned from [`fish_passage_fraser_2025_reporting`](https://github.com/NewGraphEnvironment/fish_passage_fraser_2025_reporting) at `7ef34cc`; the shared structure and appendix conventions come from there. Prior Skeena reporting lives in [`fish_passage_skeena_2024_reporting`](https://github.com/NewGraphEnvironment/fish_passage_skeena_2024_reporting).

## Build

Two self-contained scripts. Each sources `scripts/staticimports.R` (which inlines helper functions via the [staticimports](https://github.com/wch/staticimports) package) before rendering, so run them rather than calling `bookdown` directly or you'll hit "undefined function" errors:

```sh
Rscript scripts/run_gitbook.R    # web (gitbook) version -> docs/
Rscript scripts/run_pagedown.R   # print PDF -> docs/<repo>.pdf
```

`run_gitbook.R` builds the full report with the inline Phase 1 data+photos appendix. `run_pagedown.R` swaps that heavy appendix for a slim link-stub so the print PDF stays light, and restores the resting layout afterwards even if the render fails.

The book builds offline from committed caches. Regenerating those caches is deliberate and gated behind params in `index.Rmd` (`update_bcfishpass`, `update_gis`, the `update_form_*` flags) — they need the bcfishpass database tunnel and network access, and are not part of a normal build.

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
