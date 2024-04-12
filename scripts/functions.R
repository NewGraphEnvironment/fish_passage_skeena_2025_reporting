##funciton ot find a string in your directory from https://stackoverflow.com/questions/45502010/is-there-an-r-version-of-rstudios-find-in-files

fif <- function(what, where=".", in_files="\\.[Rr]$", recursive = TRUE,
                ignore.case = TRUE) {
  fils <- list.files(path = where, pattern = in_files, recursive = recursive)
  found <- FALSE
  file_cmd <- Sys.which("file")
  for (fil in fils) {

    if (nchar(file_cmd) > 0) {
      ftype <- system2(file_cmd, fil, TRUE)
      if (!grepl("text", ftype)[1]) next
    }
    contents <- readLines(fil)
    res <- grepl(what, contents, ignore.case = ignore.case)
    res <- which(res)
    if (length(res) > 0) {
      found <-  TRUE
      cat(sprintf("%s\n", fil), sep="")
      cat(sprintf(" % 4s: %s\n", res, contents[res]), sep="")
    }
  }
  if (!found) message("(No results found)")
}


# write the contents of the NEWS.md file to a RMD file that will be included as an appendix
news_to_appendix <- function(
    md_name = "NEWS.md",
    rmd_name = "2090-report-change-log.Rmd",
    appendix_title = "# Report Change Log") {

  # Read and modify the contents of the markdown file
  news_md <- readLines(md_name)
  news_md <- stringr::str_replace(news_md, "^#", "###") |>
    stringr::str_replace_all("(^(### .*?$))", "\\1 {-}")

  # Write the title, a blank line, and the modified contents to the Rmd file
  writeLines(
    c(paste0(appendix_title, " {-}"), "", news_md),
    rmd_name
  )
}

