# These are workflows that only need to happen once really so they are separate from those in tables.R. They often need to be re-run when data is updated.

# Need form_pscis and form_fiss_site objects which must be read in from `0120-read-sqlite`
source("scripts/02_reporting/0120-read-sqlite.R")

# build priority spreadsheet ----------------------------------------------
# spreadsheet to build for input includes site lengths, surveyors initials, time, priority for remediation, updated fish species (if changed from my_fish_sp())


{
# Function to replace empty character and numeric values with NA
replace_empty_with_na <- function(x) {
  if(is.character(x) && length(x) == 0) return(NA_character_)
  if(is.numeric(x) && length(x) == 0) return(NA_real_)
  return(x)
}

# specify in index.Rmd YAML which species you want to use for the modelling
# For Skeena we use steelhead
# For Peace we use bull trout

# Convert the species-specific rearing column to a symbol upfront
model_species_rearing_km <- rlang::sym(paste0(params$model_species, "_rearing_km"))

hab_priority_prep <- form_fiss_site |>
  dplyr::select(
    stream_name = gazetted_names,
    local_name,
    date_time_start
  ) |>
  tidyr::separate(local_name, c("site", "location", "ef"), sep = "_", remove = FALSE) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    crew_members = list(fpr::fpr_my_bcfishpass(dat = form_fiss_site, site = local_name, col_filter = local_name, col_pull = crew_members)),
    length_surveyed = list(fpr::fpr_my_bcfishpass(dat = form_fiss_site, site = local_name, col_filter = local_name, col_pull = site_length)),
    hab_value = list(fpr::fpr_my_bcfishpass(dat = form_fiss_site, site = local_name, col_filter = local_name, col_pull = habitat_value_rating)),

    # Priority pulled from form_pscis
    priority = list(fpr::fpr_my_bcfishpass(dat = form_pscis, site = site, col_filter = site_id, col_pull = my_priority)),

    # Comments field
    comments = list(fpr::fpr_my_bcfishpass(dat = form_fiss_site, site = local_name, col_filter = local_name, col_pull = comments)),

    # Unquoting only for the dynamic species-specific column
    upstream_habitat_length_m = list(
      fpr::fpr_my_bcfishpass(site = site, col_pull = !!model_species_rearing_km, round_dig = 4)
    ),
    upstream_habitat_length_m = list(round((upstream_habitat_length_m * 1000), digits = 0)),

    # Static column, no unquoting needed
    species_codes = list(fpr::fpr_my_bcfishpass(site = site, col_pull = observedspp_upstr)),

    # Replace empty values with NA
    dplyr::across(everything(), ~replace_empty_with_na(.))
  ) |>
  dplyr::ungroup() |>
  dplyr::filter(is.na(ef)) |>
  dplyr::mutate(priority = dplyr::case_when(priority == "mod" ~ "moderate", TRUE ~ priority)) |>
  dplyr::mutate(priority = stringr::str_to_title(priority)) |>
  dplyr::mutate(hab_value = stringr::str_to_title(hab_value)) |>
  dplyr::arrange(local_name, crew_members, date_time_start) |>
  sf::st_drop_geometry()


# burn to csv
hab_priority_prep|>
  readr::write_csv("data/habitat_confirmations_priorities.csv", na = '')
}



# extract rd cost multiplier ----------------------------------------------

{
# extract the road surface and type from bcfishpass
rd_class_surface <- bcfishpass |>
  dplyr::select(stream_crossing_id, transport_line_structured_name_1:dam_operating_status) |>
  dplyr::filter(stream_crossing_id %in% form_pscis$pscis_crossing_id) |>
  dplyr::mutate(my_road_class = ften_file_type_description)|>
  dplyr::mutate(my_road_class = case_when(is.na(my_road_class) & !is.na(transport_line_type_description) ~
                                            transport_line_type_description,
                                          T ~ my_road_class))|>

  dplyr::mutate(my_road_class = case_when(is.na(my_road_class) & !is.na(rail_owner_name) ~
                                            'rail',
                                          T ~ my_road_class))|>
  dplyr::mutate(my_road_surface = case_when(is.na(transport_line_surface_description) & !is.na(ften_file_type_description) ~
                                              'loose',
                                            T ~ transport_line_surface_description))|>
  dplyr::mutate(my_road_surface = case_when(is.na(my_road_surface) & !is.na(rail_owner_name) ~
                                              'rail',
                                            T ~ my_road_surface))|>
  dplyr::mutate(my_road_class = stringr::str_replace_all(my_road_class, 'Forest Service Road', 'fsr'),
         my_road_class = stringr::str_replace_all(my_road_class, 'Road ', ''),
         my_road_class = stringr::str_replace_all(my_road_class, 'Special Use Permit, ', 'Permit-Special-'),
         my_road_class = dplyr::case_when(
           stringr::str_detect(my_road_class, '%driveway%') ~ 'driveway',
           T ~ my_road_class),
         my_road_class = stringr::word(my_road_class, 1),
         my_road_class = stringr::str_to_lower(my_road_class))


# Unique to fraser 2025, crossing 196085 is on a paved local road, but in bcfishpass it is under fsr, so change to local.
rd_class_surface <- rd_class_surface |>
  dplyr::mutate(my_road_class = case_when(stream_crossing_id == 196085 ~ "local",
                T ~ my_road_class))


conn <- readwritesqlite::rws_connect("data/bcfishpass.sqlite")
readwritesqlite::rws_list_tables(conn)
readwritesqlite::rws_drop_table("rd_class_surface", conn = conn)
readwritesqlite::rws_write(rd_class_surface, exists = F, delete = T,
          conn = conn, x_name = "rd_class_surface")
readwritesqlite::rws_disconnect(conn)

}
