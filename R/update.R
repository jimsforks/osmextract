#' Update all the `.osm.pbf` files saved in a directory
#'
#' This function is used to re-download all `.osm.pbf` files stored in
#' `download_directory` that were firstly downloaded through `oe_get()`. See
#' details.
#'
#' @param download_directory Character string of the path of the directory
#'   where the `.osm.pbf` files are saved.
#' @param quiet Boolean. If `FALSE` the function prints informative
#'   messages. Default to `FALSE`. See Details.
#' @param delete_gpkg Boolean. if `TRUE` the function deletes the old `.gpkg`
#'   files. We added this parameter to minimize the probability of accidentally
#'   reading-in old and not-synchronized `.gpkg` files. See details. Defaults to
#'   `TRUE`.
#' @param ... Additional parameter that will be passed to `oe_get()`.
#'
#' @details This function is used to re-download `.osm.pbf` files that are
#'   stored in a directory (specified by `download_directory` param) and that
#'   were firstly downloaded through `oe_get()`. The name of the files must
#'   begin with the name of one of the supported providers (see
#'   `oe_available_providers()`) and it must end with `".osm.pbf"`. All other
#'   files in the directory that do not match this format are ignored.
#'
#'   The process for re-downloading the `.osm.pbf` files is performed using the
#'   function `oe_get()`. The appropriate provider is determined by looking at
#'   the first word in the path of the `.osm.pbf` file. The place is determined
#'   by looking at the second word in the file path and the matching is
#'   performed through the `id` column in the provider's database. So, for
#'   example, the path `geofabrik_italy-latest-update.osm.pbf` will be matched
#'   with the provider `"geofabrik"` and the geographical zone `italy` through
#'   the column `id` in `geofabrik_zones`.
#'
#'   The parameter `delete_gpkg` is used to delete all `.gpkg` files in
#'   `download_directory`. We decided to set its default value to `TRUE` to
#'   minimize the possibility of reading-in old and non-synchonized `.gpkg`
#'   files. If you set `delete_gpkg = TRUE`, then you need to manually reconvert
#'   all files using `oe_get()` or `oe_vectortranslate()`. See examples.
#'
#'   If you set the parameter `quiet` to `FALSE`, then the function will print
#'   some useful messages regarding the characteristics of the files before and
#'   after updating them. More precisely, it will print the output of the
#'   columns `size`, `mtime` and `ctime` from `file.info()`. Please note that
#'   the meaning of `mtime` and `ctime` depends on the OS and the file system.
#'   Check `?file.info`. See examples.
#'
#' @return The path(s) of the .osm.pbf file(s) that were updated invisibly.
#' @export
#' @examples
#' 1 + 1
oe_update = function(
  download_directory = oe_download_directory(),
  quiet = FALSE,
  delete_gpkg = TRUE,
  ...
) {
  # Extract all files in download_directory
  all_files = list.files(download_directory)

  # Save all providers but test
  all_providers = setdiff(oe_available_providers(), "test")

  # The following is used to check if the directory is empty since list.files
  # returns character(0) in case of empty dir
  if (identical(list.files(download_directory), character(0))) {
    stop(
      "The download directory, ",
      download_directory,
      ", is empty.",
      call. = FALSE
    )
  }

  # A summary of the files in download_directory
  if (isFALSE(quiet)) {
    old_files_info = file.info(file.path(download_directory, all_files))
    cat(
      "This is a short description of some characteristics of the files",
      "stored in the download_directory: \n"
    )
    print(old_files_info[, c(1, 4, 5)])
    cat("\n The .osm.pbf files are going to be updated.\n")
  }

  # Check if the .gpkg files should be deleted
  if (isTRUE(delete_gpkg)) {
    file.remove(grep("\\.gpkg", all_files, value = TRUE))
    if (isFALSE(quiet)) {
      message("The .gpkg files in download_directory were removed.")
    }
  }



  # Find all files with the following pattern: provider_whatever.osm.pbf
  providers_regex = paste0(all_providers, collapse = "|")
  oe_regex = paste(
    "(", providers_regex, ")", # match with geofabrik or bbbike or ...
    "_(.+)", # match with everything
    "\\.osm\\.pbf", # match with ".osm.pbf" (i.e. exclude .gpkg)
    collapse = "",
    sep = ""
  )
  osmpbf_files = grep(oe_regex, all_files, perl = TRUE, value = TRUE)

  # For all the files matched with the previous regex
  for (file in osmpbf_files) {
    # Match it's provider
    matching_providers = vapply(all_providers, grepl, FUN.VALUE = logical(1), x = file, fixed = TRUE)
    provider = all_providers[matching_providers]
    # Match the id of the place (the id is the alphabetic string right  after
    # the provider, for example if file is equal to
    # geofabrik_italy-latest-update.osm.pbf then provider = geofabrik and id =
    # italy)
    id = regmatches(
      file,
      regexpr(paste0("(?<=", provider, "_)[a-zA-Z]+"), file, perl = TRUE)
    )

    # Update the .osm.pbf files, skipping the vectortranslate step
    oe_get(
      place = id,
      provider = provider,
      match_by = "id",
      force_download = TRUE,
      download_only = TRUE,
      skip_vectortranslate = TRUE,
      ...
    )
  }

  # A summary of the files in download_directory
  if (isFALSE(quiet)) {
    new_files_info = file.info(file.path(download_directory, osmpbf_files))
    cat(
      "This is a short description of some characteristics of the updated",
      " files stored in the download_directory: \n"
    )
    print(new_files_info[, c(1, 4, 5)])
  }

  invisible(osmpbf_files)
}


