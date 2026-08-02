# scripts/bib_repair.R
# ---------------------------------------------------------------------------
# Normalise citation keys in the .Rmd prose to the canonical NGE bibliography.
#
# WHY THIS DIRECTION (it is the opposite of the obvious fix):
#   Faced with a "Citeproc: citation X not found" warning, the tempting move is to
#   pull that entry into references.bib so the existing key resolves. That is
#   backwards — it drifts each repo's key set further from every other repo's,
#   which is how the same work ends up cited three different ways across the
#   fish_passage family. xciter ships the canonical bibliography
#   (extdata/NewGraphEnvironment.bib, ~1600 entries). This script rewrites the
#   PROSE to use those keys so repos converge; references.bib is then regenerated
#   from Zotero and simply resolves.
#
#   Same pattern as restoration_wedzin_kwa_2024, fish_passage_peace_2025_reporting
#   and fish_passage_skeena_2024_reporting (see their scripts/bib_repair.R).
#
# ORDER MATTERS — curated before guessed:
#   1. Apply xciter's CURATED xref table (xct_xref_citations_match.csv). It exists
#      precisely because fuzzy matching is confidently wrong on some pairs: e.g.
#      `wilsonFishPassageAssessment2007` fuzzy-guesses `moe2021PSCISAssessments`
#      when the correct answer is `wilson_rabnett2007FishPassage`. Note the table's
#      three columns — key_missing, key_missing_guess_match (what fuzzy WOULD say),
#      key_match (what is actually right).
#   2. Only then look at fuzzy guesses for the remainder, and REVIEW them. This
#      script deliberately does not auto-replace guesses: a wrong key silently
#      cites the wrong paper, which is worse than a missing one — a missing key
#      renders as [?] and gets noticed.
#
# RUN:  Rscript scripts/bib_repair.R          (DRY_RUN=1 previews, changes nothing)
# THEN: regenerate references.bib and rebuild. Verify on a CLEAN build
#       (rm _main.Rmd first) — an incremental bookdown build under-reports missing
#       citations because pandoc only sees the chapters it re-rendered.
# ---------------------------------------------------------------------------
suppressMessages({library(rbbt); library(xciter); library(ngr); library(dplyr); library(readr); library(purrr)})

dry       <- nzchar(Sys.getenv("DRY_RUN"))
path_bib  <- system.file("extdata", "NewGraphEnvironment.bib", package = "xciter")
path_xref <- system.file("extdata", "xct_xref_citations_match.csv", package = "xciter")
stopifnot("xciter canonical bib not found — install NewGraphEnvironment/xciter" = nzchar(path_bib))

file_list <- fs::dir_ls(glob = "*.Rmd")
keys_bib  <- xciter::xct_bib_keys_extract(path_bib)
detect    <- function() rbbt::bbt_detect_citations(list.files(pattern = "*.Rmd"))
missing_now <- function() suppressWarnings(
  xciter::xct_bib_keys_missing(path_bib = path_bib, citations = detect()))

m0 <- missing_now()
message(sprintf("canonical bib: %d entries | citations in prose: %d | not in canonical bib: %d",
                length(keys_bib), length(detect()), length(m0)))

# ---- 1. curated xref — authoritative ---------------------------------------
xref <- suppressWarnings(readr::read_csv(path_xref, show_col_types = FALSE)) %>%
  filter(!is.na(key_match), key_missing %in% m0) %>%
  mutate(key_match = sub(",$", "", key_match))   # a couple of rows carry a trailing comma

message("\ncurated xref pairs that apply here: ", nrow(xref))
if (nrow(xref)) print(as.data.frame(xref[, c("key_missing", "key_match")]), row.names = FALSE)

if (nrow(xref) && !dry) {
  purrr::walk2(xref$key_missing, xref$key_match,
               ~ ngr::ngr_str_replace_in_files(text_current = .x, text_replace = .y,
                                               files = file_list, ask = FALSE))
  message("\napplied ", nrow(xref), " curated replacement(s)")
}

# ---- 2. whatever is left: report, do not auto-replace ----------------------
m1 <- if (dry) m0 else missing_now()
message("\nstill not in the canonical bib: ", length(m1))
if (length(m1)) {
  guesses <- xciter::xct_keys_guess_match(m1, keys_bib = keys_bib,
                                          stringdist_threshold = 25,
                                          no_match_rows_include = TRUE) %>%
    dplyr::arrange(key_missing)
  print(as.data.frame(guesses), row.names = FALSE)
  message(
    "\nNOT replaced automatically. For each: if a guess is verified correct, add the pair to\n",
    "xciter's xct_xref_citations_match.csv so every repo inherits it; if the work is genuinely\n",
    "absent, add it to the Zotero group library. Do not invent bib metadata to silence a warning.")
}
if (dry) message("\nDRY_RUN — nothing modified")
