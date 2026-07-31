# Build the pagedown (print PDF) version of the report.
#
# Swaps the heavy inline Phase 1 appendix (0600-appendix.Rmd) out for the slim
# link-stub (2300-Attachment_pdf_phase_1_dat.Rmd) so the PDF stays light, then
# renders. Explicit CRAN mirror, defensive cleanup, auto-open of the rendered
# PDF. Auto-toggles `gitbook_on` FALSE in index.Rmd at start and restores TRUE
# via `on.exit` so a crash doesn't leave the repo in PDF mode.
#
# Resting state: 0600 at root, 2300 in hold/.
#
# Usage:
#   Rscript scripts/run_pagedown.R

options(repos = c(CRAN = "https://cloud.r-project.org"))

# --- Auto-toggle gitbook_on FALSE in index.Rmd, restore TRUE at end -----
# Wrapped in a function so on.exit attaches to a frame — a top-level on.exit in
# Rscript silently no-ops, which would leave gitbook_on FALSE after a crash.

toggle_gitbook_on <- function(value) {
  txt <- readLines("index.Rmd")
  i <- grep("^gitbook_on <- (TRUE|FALSE)\\s*$", txt)
  if (length(i) == 0) stop("gitbook_on toggle line not found in index.Rmd")
  txt[i[1]] <- sprintf("gitbook_on <- %s", value)
  writeLines(txt, "index.Rmd")
}

build_pdf <- function() {
  on.exit(toggle_gitbook_on("TRUE"), add = TRUE)
  toggle_gitbook_on("FALSE")

staticimports::import()
source('scripts/staticimports.R')

# --- Filename derivation -------------------------------------------------
# pagedown writes <book_filename>.html into the repo root using book_filename
# from _bookdown.yml, while the PDF we want is named after the repo. Read both
# rather than hardcoding either.
yml             <- yaml::read_yaml("_bookdown.yml")
input_html_stem <- yml$book_filename

idx_yml         <- rmarkdown::yaml_front_matter("index.Rmd")
output_pdf_stem <- basename(idx_yml$params$repo_url)

# Preload PDF render-time globals so chunks that consume them via lazy defaults
# (e.g. `fpr_kable(font = font_set)`) resolve them through the function's
# closure chain. We pass `envir = globalenv()` to bookdown::render_book below,
# which makes globalenv the knit env so chunks see these too. We deliberately do
# NOT preload `params` — bookdown injects params from YAML into the knit env at
# render time and pre-binding here trips its "params object already exists in
# knit environment" guard.
font_set    <<- 9
photo_width <<- "80%"
gitbook_on  <<- FALSE

input_html  <- paste0(input_html_stem, ".html")
output_pdf  <- file.path("docs", paste0(output_pdf_stem, ".pdf"))

# --- Defensive move helpers (report each rename outcome) ----------------
move_to_hold <- function(path) {
  if (!file.exists(path)) {
    cat(sprintf("  WARN: %s missing, skipping move-to-hold\n", path))
    return(invisible(FALSE))
  }
  if (!dir.exists("hold")) dir.create("hold")
  hold_path <- file.path("hold", basename(path))
  if (file.exists(hold_path)) {
    cat(sprintf("  hold/ already has %s, removing first\n", basename(path)))
    file.remove(hold_path)
  }
  ok <- file.rename(path, hold_path)
  cat(sprintf("  %s -> %s : %s\n", path, hold_path, ok))
  invisible(ok)
}
move_back_from_hold <- function(path) {
  hold_path <- file.path("hold", basename(path))
  if (!file.exists(hold_path)) {
    cat(sprintf("  WARN: %s not in hold/, cannot restore\n", basename(path)))
    return(invisible(FALSE))
  }
  if (file.exists(path)) {
    cat(sprintf("  %s already exists, removing first\n", path))
    file.remove(path)
  }
  ok <- file.rename(hold_path, path)
  cat(sprintf("  %s -> %s : %s\n", hold_path, path, ok))
  invisible(ok)
}

# --- Swap Phase 1 appendix: inline (gitbook) -> link-stub (PDF) ----------
# Gitbook renders the full inline Phase 1 data+photos appendix, which is huge
# and would land mid-report in the PDF. For the PDF we swap it for the slim
# link-stub that points at the online gitbook page.
appendix_inline <- "0600-appendix.Rmd"
appendix_stub   <- "2300-Attachment_pdf_phase_1_dat.Rmd"

restore_appendix_layout <- function() {
  if (file.exists(appendix_stub)) move_to_hold(appendix_stub)
  if (file.exists(file.path("hold", appendix_inline)))
    move_back_from_hold(appendix_inline)
}

cat("\n=== Swapping Phase 1 appendix (inline -> link-stub) for PDF ===\n")
move_to_hold(appendix_inline)
move_back_from_hold(appendix_stub)

# Crash-safe restore to resting state
on.exit(restore_appendix_layout(), add = TRUE)

# --- Render pagedown HTML ------------------------------------------------
# bookdown::render_book with `envir = globalenv()`, NOT rmarkdown::render_site.
# render_site's knit env is a sibling of globalenv, so source()-d helpers can't
# resolve lazy-default args (font = font_set, caption_text = my_caption) that
# chunks assigned into globalenv — producing cascading "object not found".
bookdown::render_book(
  input         = "index.Rmd",
  output_format = "pagedown::html_paged",
  encoding      = "UTF-8",
  envir         = globalenv()
)

# --- Chrome print HTML -> PDF -------------------------------------------
cat(sprintf("\nPrinting %s -> %s ...\n", input_html, output_pdf))
pagedown::chrome_print(
  input_html,
  output  = output_pdf,
  timeout = 300
)

# --- Clean up the intermediate HTML (too big to commit) ------------------
if (file.exists(input_html)) file.remove(input_html)

# --- Auto-open the PDF ---------------------------------------------------
if (file.exists(output_pdf)) {
  cat(sprintf("PDF size: %.1f MB\n", file.size(output_pdf) / 1024^2))
  if (interactive()) system(paste("open", shQuote(output_pdf)))
} else {
  cat("WARN: expected PDF was not produced.\n")
}

# --- Restore resting appendix layout ------------------------------------
cat("\n=== Restoring Phase 1 appendix layout (inline at root) ===\n")
restore_appendix_layout()

}  # close build_pdf()
build_pdf()
