eDNA integration and structural alignment with Peace 2025 (#10, #11). Consumed the 2025 UNBC ddPCR batch — Fraser was the largest of the three regions in it and the only one that had not — and brought the report's structure into line with the readability decisions Peace accumulated while Fraser sat frozen at v0.2.1.

Three eDNA sites were mislabelled and corrected by coordinates: `196076_ds_ed1a/b` → 203581 (8 m vs 1.2 km away), `196209_us_ed1` → 196200 (29 m vs 6.5 km). The wrong labels are still live on the collaborative GIS map.

Non-detections are reported as **untested, not absences**. 33 of 38 Fraser samples have no passing amplification controls, as do 22 of the 25 sites that did produce detections; the controls appear only on the workbook's PRIORITY sheets and never on the dated run sheets. Filed as #15 with a question drafted to UNBC in `compost`.

Nine defects fixed in the already-published report, three of them silent: `stringr::str_like()` went case-sensitive in 1.5.0 and had been rendering Table 4.5 completely empty; `cat(params$project_year)` returns NULL so the year vanished from three sentences ("commissioned in due to uncertainty"); and the title page said version 0.0.1 through two releases.

A later pass found three more claims the data did not support — a priorities-by-watershed-group section that does not exist, 2025 fieldwork said to have revisited sites documented in earlier reporting (no site overlap, and that report was last edited seven weeks before the field season), and an eDNA count that included the blanks. All were inherited template prose, true for Peace and false for Fraser. Fixed in v0.3.1; the pattern is filed as #18 for a full verification sweep of the remaining chapters.

Closed via PR #16 (v0.3.0) and PR #17 (v0.3.1).
