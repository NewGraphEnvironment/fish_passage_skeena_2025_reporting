# grab object and derive object we need. can put in a list if gets cluttery.  Considering moving
# away from sqlite due to issues with git and simplicity of flat files.
# all good aww. basically forgot about the sqlite.

# need to load the params

path <- "data/inputs_raw/xref_fwa_wsg.csv"
if(params$run_project){
  fpr::fpr_db_query(
    query= "SELECT watershed_group_code, watershed_group_name
  FROM whse_basemapping.fwa_watershed_groups_poly"
  ) |>
    dplyr::arrange(watershed_group_code) |>
    readr::write_csv(
      path
    )
}

xref_wsg <- readr::read_csv(
  path
)

wsg_names <- xref_wsg |>
  dplyr::filter(watershed_group_code %in% params$wsg_code) |>
  dplyr::pull(watershed_group_name)

path <- 'data/inputs_extracted/fiss_species_table.csv'
# you need static imports for this
if(params$run_project){
  fiss_species_table <- sfis_tab_sp(wsg_code = params$wsg_code) |>
    readr::write_csv(
      path
    )
}
