# Safely drop a table from sqlite if it exists
# Allows scripts to run on fresh databases with no tables
# See https://github.com/NewGraphEnvironment/fish_passage_template_reporting/issues/159
lngr_drop_table_if_exists <- function(table_name, conn) {
  if (table_name %in% readwritesqlite::rws_list_tables(conn)) {
    readwritesqlite::rws_drop_table(table_name, conn = conn)
  }
}


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



lfpr_table_cv_detailed_print <- function(tab_sum,
                                         comments,
                                         photos,
                                         gitbook_switch = gitbook_on) {

  comment_label <- paste0("Comments: ", comments[[1]])

  photo_label <- paste0(
    "Photos: PSCIS ID ", photos[[1]],
    ". From top left clockwise: Road/Site Card, Barrel, Outlet, Downstream, Upstream, Inlet."
  )

  photo_insert <- photos[[2]]

  output <- tab_sum |>
    knitr::kable(booktabs = TRUE) |>
    kableExtra::kable_styling(c("condensed"), full_width = TRUE, font_size = 11) |>
    kableExtra::add_footnote(
      label = list(comment_label, photo_label, photo_insert),
      notation = "none"
    )

  # inlclude page breaks so the pdf builds properly and so tables have some seperation in the online report- easier to read
  paste0(output, "<br><br><br><br><br>")
}






#' Correct mislabelled 2025 eDNA sample site ids
#'
#' Two samples were recorded against the wrong crossing in the field form.
#' `196076_ds_ed1a` / `196076_ds_ed1b` were collected 8 m from PSCIS crossing
#' 203581 (CN railway, UTM10 E526469 N5985767) and 1.2 km from crossing 196076
#' (E527382 N5985006), i.e. upstream of 203581 rather than downstream of 196076.
#'
#' The field form is deliberately left untouched — those ids travelled to UNBC
#' with the samples and are the lab's linkage — so the correction is applied at
#' the display layer. Applying it here rather than inline keeps the sample
#' metadata table, the per-site results tables, the thematic appendix and the
#' interactive map from disagreeing about which crossing a sample belongs to.
#'
#' @param x character vector of eDNA `site_id` values
#' @return character vector, corrected
edna_site_id_fix <- function(x) {
  lookup <- c(
    "196076_ds_ed1a" = "203581_us_ed1a",
    "196076_ds_ed1b" = "203581_us_ed1b"
  )
  hit <- x %in% names(lookup)
  x[hit] <- unname(lookup[x[hit]])
  x
}
