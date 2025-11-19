
### Scripts to transfer photos and excel file to the PSCIS submission folder. This script does it for multiple projects at once.

# Params ------------------------------
year <- 2025

path_onedrive <- fs::path("~/Library/CloudStorage/OneDrive-Personal/Projects/")

# list projects
name_projects <- c(
  "sern_peace_fwcp_2023",
  "sern_fraser_2024",
  "sern_skeena_2023"
)

# list job names, must match order of name_projects
name_jobs <- c(
  "2025-077-sern-peace-fish-passage",
  "2025-076-sern-skeena-fraser-fish-passage",
  "2025-076-sern-skeena-fraser-fish-passage"
)

name_submissions <- c("pscis_phase1.xlsm",
                      "pscis_phase2.xlsm",
                      "pscis_reassessments.xlsm")


#define data dir in repo
dir_in <- fs::path(
  "data/spreadsheets", year, name_projects
)


# define submission dir on onedrive
dir_out <-   fs::path(
  path_onedrive, "submissions/PSCIS/", year, name_projects
)

#The mergin photos (renamed) are separate from the extra ondrive photos (extra).
photo_path_extension <- "renamed"


#### UNIQUE to 2025 fraser and skeena onedrive projects #####
# Fraser and Skeena share folder because they are part of the same job, so the data/photos folder is further separated into skeena and fraser.
##### END



# Functions -----------------------------------------------------------------
tfpr_filter_list <- function(idx){
  filestocopy_list[idx]
}

tfpr_photo_change_name <- function(filenames_to_change = filestocopy_list){
  gsub(filenames_to_change, pattern = path_photos, replacement = targetdir)
}




### Wrangle PSCIS forms ------------------------

# initialize a list to store the results
results <- list()

for (i in seq_along(name_projects)) {

  # extract the project region we are working on, so we can use it to build the target directory path
  project_region <- stringr::str_match(name_projects[i], "^sern_([^_]+)_")[, 2]
  # print(project_region)

  # path to photos for this project
  path_photos <- dplyr::case_when(
    project_region %in% c("skeena", "fraser") ~
      fs::path(path_onedrive, name_jobs[i], "data/photos", project_region, photo_path_extension),
    TRUE ~
      fs::path(path_onedrive, name_jobs[i], "data/photos", photo_path_extension))

  # print(path_photos)


  for(s in seq_along(name_submissions)){

    # check to see if this file exists. If so then continue on. Not all projects have

    # extract the submission type we are working on, so we can use it to build the target directory path
    submission_type <- stringr::str_match(name_submissions[s], "^(pscis_[^\\.]+)")[, 2]


    #Build target directory path
    targetdir = fs::path(dir_out[i],paste0(project_region,"_", year, "_", submission_type))

    # create the directory.
    # fs::dir_create(targetdir)


    # read in the pscis spreadsheet and use it to make the folders to copy the photos to.
    d <- fpr::fpr_import_pscis(workbook_name = name_submissions[s], dir_root = fs::path("data","spreadsheets", year, name_projects[i]))


    # If we are dealing with phase 1 crossings use `my_crossing_reference`, otherwise use `pscis_crossing_id` (phase 2 or reassessments)
    col_site_id <- dplyr::case_when(submission_type == "pscis_phase1.xlsm" ~ "my_crossing_reference",
                                    TRUE ~ "pscis_crossing_id")


    # Pull out the sites we need to make folders for
    folderstocopy <- dplyr::pull(d, !!rlang::sym(col_site_id)) |> as.character()

    # Define the path to where those photos are currenly stored.
    path_to_photos <- fs::path(path_photos, folderstocopy)


    # here we transfer just the photos with labels over into the PSCIS submission directory.

    folderstocreate<- fs::path(targetdir, folderstocopy)

    ##create the folders
    # fs::dir_create(folderstocreate)


    # Identify photos that should be copied over into file
    filestocopy_list <- path_to_photos |>
      purrr::map(fpr::fpr_photo_paths_to_copy) |>
      purrr::set_names(basename(folderstocreate))


    ##view which files do not have any photos to paste by reviewing the empty_files object
    empty_idx <- which(!lengths(filestocopy_list))
    empty_files <- empty_idx |> tfpr_filter_list()

    # ##rename long names if necessary
    # photo_sort_tracking <- path_to_photos |>
    #   purrr::map(fpr::fpr_photo_document_all) |>
    #   purrr::set_names(folderstocopy) |>
    #   bind_rows(.id = 'folder') |>
    #   mutate(photo_name = str_squish(str_extract(value, "[^/]*$")),
    #          photo_name_length = stringr::str_length(photo_name))
    #
    # ##here we back up a csv that gives us the new location and name of the original JPG photos.
    #
    # #burn to csv
    # fs::dir_create("data/photos")
    # photo_sort_tracking |>
    #   readr::write_csv(file = 'data/backup/photo_sort_tracking_phase1.csv')
    #
    # ## change path name so we can paste to folders
    # filestopaste_list <- filestocopy_list |>
    #   map(tfpr_photo_change_name)
    #
    # ##!!!!!!!!!!!!!!!copy over the photos!!!!!!!!!!!!!!!!!!!!!!!
    # mapply(fs::file_copy,
    #        path =  filestocopy_list,
    #        new_path = filestopaste_list)
    #
    #
    #
    #
    # # add cleaned pscis df to results so we can check to make sure everything looks good.
    # results[[name_projects[i]]] <- form_pscis_clean

  }
}

