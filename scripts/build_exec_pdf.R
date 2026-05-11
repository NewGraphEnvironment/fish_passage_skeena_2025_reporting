#!/usr/bin/env Rscript
# Build the standalone executive summary PDF via pagedown.
#
# Renders _executive_summary_pdf.Rmd (child-includes 0050-executive-summary.Rmd)
# and writes docs/executive_summary.pdf.
#
# Usage: Rscript scripts/build_exec_pdf.R

if (!requireNamespace("pagedown", quietly = TRUE)) {
  stop("pagedown is required. Install with: pak::pak('pagedown')")
}

dir.create("docs", showWarnings = FALSE)

html_file <- rmarkdown::render(
  input         = "_executive_summary_pdf.Rmd",
  output_format = "pagedown::html_paged",
  output_dir    = "docs",
  output_file   = "executive_summary.html",
  quiet         = TRUE
)

pagedown::chrome_print(
  input  = html_file,
  output = "docs/executive_summary.pdf",
  wait   = 2
)

unlink("docs/executive_summary.html")

message("Wrote: docs/executive_summary.pdf")
