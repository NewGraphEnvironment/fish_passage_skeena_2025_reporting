
### This scripts is used to export pscis data to a csv for cut and paste into PSCIS submission spreadsheet. This script does it for all 3 projects at once.

# Params ------------------------------
year <- 2025

path_gis <- "/Users/lucy/Projects/gis"

# list projects
name_projects <- c(
  "sern_peace_fwcp_2023",
  "sern_fraser_2024",
  "sern_skeena_2023"
)

# define data dir
dir_out <-   fs::path(
  path_gis, name_projects, "data_field", year
)

dir_in <- fs::path(
  path_gis, name_projects
)


# Prep for spreadsheet ------------------------------

# initialize a list to store the results
results <- list()

# initialize a list to track which sites have a culvert length (`length_or_width_meters`) over 99.9 or a fill depth (`fill_depth_meters`) over 9.9
max_cul_leng_fill_dpt <- list()


for (i in seq_along(name_projects)) {

  # Path to the pscis form to backup
  path_form_pscis <- fs::path(dir_out[i], paste0("form_pscis_", year, ".gpkg"))


  #read in cleaned form from Q after review and finalization
  pscis_export_raw <- fpr::fpr_sp_gpkg_backup(
    path_gpkg = path_form_pscis,
    update_utm = TRUE,
    update_site_id = TRUE, ## Turn this off after adding pscis ids
    write_back_to_path = FALSE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE)

  # check for sites that have a culvert length (`length_or_width_meters`) over 99.9 or a fill depth (`fill_depth_meters`) over 9.9
  max_cul_leng_fill_dpt[[name_projects[i]]] <- pscis_export_raw |>
    dplyr::filter(length_or_width_meters > 99.9 | fill_depth_meters > 9.9) |>
    dplyr::select(date_time_start:crew_members, length_or_width_meters,fill_depth_meters)

  # Now we will change them to 99.9 and 9.9, respectively, and will append a note to the assessment comments.
  pscis_export_prep1 <- pscis_export_raw |>
    dplyr::mutate(
      assessment_comment = dplyr::case_when(
        length_or_width_meters > 99.9 ~ paste0(assessment_comment, 'Culvert length ', length_or_width_meters, 'm but changed to 99.9m to meet submission requirements.'),
        TRUE ~ assessment_comment
      ),
      length_or_width_meters = dplyr::case_when(
        length_or_width_meters > 99.9 ~ 99.9,
        TRUE ~ length_or_width_meters
      ),
      assessment_comment = dplyr::case_when(
        fill_depth_meters > 9.9 ~ paste0(assessment_comment, 'Fill depth ', fill_depth_meters, 'm but changed to 9.9m to meet submission requirements.'),
        TRUE ~ assessment_comment
      ),
      fill_depth_meters = dplyr::case_when(
        fill_depth_meters > 9.9 ~ 9.9,
        TRUE ~ fill_depth_meters
      )
    )


  # Do some final cleaning and prepare the data for easy copy paste into the spreadsheets.
  # - append MoTi ids to the comments
  # - fix some vocabulary
  # - change crossing type to other if subtype is FORD
  # - fill in resemble channel to No if not Yes. This is required when in the spreadsheet.


  pscis_export <- pscis_export_prep1 |>
    dplyr::mutate(date_time_start = lubridate::ymd_hms(date_time_start, tz = "America/Vancouver"),
                  date = lubridate::date(date_time_start)) |>
    # append MoTi ids to comments, differentiate between highway major structure, and add time to end
    dplyr::mutate(assessment_comment = dplyr::case_when(
      moti_chris_culvert_id > 1000000 ~ paste0(assessment_comment, ' MoTi chris_culvert_id: ', moti_chris_culvert_id),
      moti_chris_culvert_id < 1000000 ~ paste0(assessment_comment, ' MoTi chris_hwy_structure_road_id: ', moti_chris_culvert_id),
      TRUE ~ assessment_comment)) |>
    dplyr::mutate(assessment_comment = dplyr::case_when(moti_chris_culvert_id2 > 1000000 ~ paste0(assessment_comment, ', ', moti_chris_culvert_id2), TRUE ~ assessment_comment)) |>
    dplyr::mutate(assessment_comment = dplyr::case_when(moti_chris_culvert_id3 > 1000000 ~ paste0(assessment_comment, ', ', moti_chris_culvert_id3), TRUE ~ assessment_comment)) |>

    # If the crossing subtype is a ford then change the crossing type to other to fit spreadsheet requirements
    dplyr::mutate(crossing_type = dplyr::case_when(crossing_subtype == "Ford" ~ "Other", TRUE ~ crossing_type)) |>

    # fill in resemble channel to No if not Yes. This is required when in the spreadsheet
    dplyr::mutate(resemble_channel_yes_no = dplyr::case_when(resemble_channel_yes_no == "Yes" ~ "Yes", TRUE ~ "No")) |>

    # only select columns from the template object, as well as site_id, pscis phase, and date_time_start
    dplyr::select(
      dplyr::any_of(names(fpr::fpr_xref_template_pscis())),
      site_id,
      date_time_start,
      assess_type_phase1,
      assess_type_phase2,
      assess_type_reassessment
    ) |>
    # remove scoring columns, as these can't be copied and pasted anyways because of macros
    dplyr::select(-stream_width_ratio:-barrier_result) |>
    sf::st_drop_geometry() |>
    # arrange by phase so easy to copy/paste into correct spreadsheet
    dplyr::arrange(assess_type_phase1,
                   assess_type_phase2,
                   assess_type_reassessment,
                   crossing_type,
                   continuous_embeddedment_yes_no,
                   backwatered_yes_no,
                   crew_members,
                   date_time_start)


  # Burn to csv for copy paste into submission spreadsheet.
  dir_csv <- fs::path("data/inputs_extracted", year, name_projects[i])
  fs::dir_create(dir_csv)

  pscis_export |>
    # use readr::write_excel_csv() because it includes a UTF-8 byte order mark (BOM),
    # which forces Excel to read the file in UTF-8. This prevents en dashes (–) from
    # being misinterpreted and turned into corrupted characters like ‚Äì.
    readr::write_excel_csv(paste0(dir_csv, "/pscis_export_submission.csv"), na = '')


  # add pscis export df to results so we can check to make sure everything looks good.
  results[[name_projects[i]]] <- pscis_export

  # Backup our changes
  source("scripts/01_prep_inputs/0100_backup_forms.R")

}


# Download spreadsheet --------------------------

# The spreadsheet can be downloaded here https://www2.gov.bc.ca/gov/content/environment/plants-animals-ecosystems/fish/aquatic-habitat-management/fish-passage/fish-passage-technical/assessment-projects. Duplicate 3 times and rename according to below.



# Create project specific directories and duplicate and rename spreadsheet within the data dir in the template. This is only needed for the template. Once the individual repos have been made the pscis files live in the data directory. ---------------------

# Name the pscis spreadsheet, make sure you have the latest version.
pscis_spdsh_raw <- "pscis_assessment_template_v24.xlsm"

pscis_spdsh_renamed <- c("pscis_phase1.xlsm",
                         "pscis_phase2.xlsm",
                         "pscis_reassessments.xlsm")


for (i in seq_along(name_projects)) {

  # Path to the data/backup dir
  dir_spdsh <- fs::path("data/spreadsheets", year, name_projects[i])
  fs::dir_create(dir_spdsh)

  for (s in seq_along(pscis_spdsh_renamed)) {
    fs::file_copy(fs::path("data/spreadsheets", pscis_spdsh_raw),
                  fs::path("data/spreadsheets", year, name_projects[i], pscis_spdsh_renamed[s]),
                  overwrite = T
    )
  }
}


# Copy paste data into spreadsheet --------------------------

# Now copy/paste the following data from `pscis_export_submission.csv` into the corresponding spreadsheets:
# - phase 1 data into `pscis_phase1.xlsm`
# - phase 2 data into `pscis_phase2.xlsm`
# - reassessment data in `pscis_reassessments.xlsm`

