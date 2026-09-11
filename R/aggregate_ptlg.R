#' transformiert PTLG-Daten (4 verschiedene Optionen)
#'
#' @param path_input Pfad, wo die ursprünglichen Tabellen liegen.
#' @param target_tables Anzahl Tabellen, die ausgegeben werden sollen (1, 2, 3, oder 4). Standard: 3.
#' @param path_output Pfad für den Export der CSV-Dateien. Standard: gleich path_input.
#' @return Schreibt die aggregierten Tabellen als CSV-Dateien auf die Platte.
#'
#' @import dplyr
#' @import purrr
#' @import tidyr
#' @import stringr
#' @importFrom utils read.csv
#' @export
transform_data <- function(
  path_input,
  target_tables = 3,
  path_output = path_input
) {
  data_list <- .load_ptlg_data_raw(path_input)
  aggregated_tables <- .aggregate_ptlg_data(data_list, target_tables)
  .export_ptlg_to_csv(aggregated_tables, path_output)
}

# Interne helpter Funktionen

#' Lädt Rohdaten aus einem angegebenen Pfad
#'
#' @param path Pfad zum Ordner, in dem die CSV-Dateien liegen.
#' @return Eine Liste mit den eingelesenen Dataframes.
#' @keywords internal
.load_ptlg_data_raw <- function(path) {
  if (!exists(".ptlg_config")) {
    stop(
      "Die interne Konfigurationsliste '.ptlg_config' wurde im Package nicht gefunden."
    )
  }

  required_files <- .ptlg_config$required_tables
  if (is.null(required_files)) {
    stop(
      "Die interne Konfiguration '.ptlg_config' enthält keine Liste 'required_tables'."
    )
  }

  data_list <- list()
  for (file_name in required_files) {
    full_path <- file.path(path, paste0(file_name, ".csv"))
    if (!file.exists(full_path)) {
      stop(paste("Datei nicht gefunden:", full_path))
    }
    data_list[[file_name]] <- read.csv(full_path, stringsAsFactors = FALSE)
  }
  return(data_list)
}

#' Aggregiert Daten basierend auf der gewählten Variante
#'
#' @keywords internal
.aggregate_ptlg_data <- function(data_list, target_tables = 2) {
  if (!is.numeric(target_tables) || !(target_tables %in% 1:4)) {
    stop(
      "Fehler: `target_tables` muss ein ganzzahliger Wert zwischen 1 und 4 sein."
    )
  }

  missing <- setdiff(.ptlg_config$required_tables, names(data_list))
  if (length(missing) > 0) {
    stop(paste(
      "Fehler: Folgende Datensätze fehlen:",
      paste(missing, collapse = ", ")
    ))
  }

  h_data <- .harmonize_ptlg_data(data_list)

  result <- switch(
    as.character(target_tables),
    "1" = .process_variant_1(h_data),
    "2" = .process_variant_2(h_data),
    "3" = .process_variant_3(h_data),
    "4" = .process_variant_4(h_data)
  )
  return(result)
}

#' Interne Funktion zur Harmonisierung der Spaltennamen
#'
#' @keywords internal
.harmonize_ptlg_data <- function(data) {
  list(
    gesuche = data$ptlg_gesuche_nach_monat %>%
      dplyr::mutate(jahr = as.character(jahr)),
    bestand = data$ptlg_aktiver_bestand_monatlich %>%
      dplyr::mutate(jahr = as.character(jahr)) %>%
      dplyr::rename(anzahl = all_of(.ptlg_config$column_mapping$bestand)),
    alters = data$ptlg_altersverteilung_fahrer %>%
      dplyr::mutate(jahr = as.character(jahr)) %>%
      dplyr::rename(
        geburtskohorte = all_of(.ptlg_config$column_mapping$alters)
      ),
    kanton = data$ptlg_fahrzeuge_nach_kanton %>%
      dplyr::mutate(jahr = as.character(jahr)) %>%
      dplyr::rename(geo_name = all_of(.ptlg_config$column_mapping$kanton)),
    gemeinde = data$ptlg_kommunale_bewilligungen_stichtag %>%
      dplyr::mutate(
        jahr = stringr::str_extract(stichtag, "\\d{4}"),
        jahr = as.character(jahr)
      ) %>%
      dplyr::rename(geo_name = all_of(.ptlg_config$column_mapping$gemeinde))
  )
}

#' Verarbeitet Variante 1: Master-Tabelle
#'
#' @keywords internal
.process_variant_1 <- function(h_data) {
  master_list <- purrr::map(h_data, function(df) {
    df %>%
      dplyr::mutate(dplyr::across(everything(), as.character)) %>%
      tidyr::pivot_longer(
        cols = everything(),
        names_to = "dimension_name",
        values_to = "dimension_value"
      )
  })
  return(list(ptlg_master_table = dplyr::bind_rows(master_list)))
}

#' Variante 2: Zwei Tabellen als Output
#'
#' @keywords internal
.process_variant_2 <- function(h_data) {
  t1_gesuch <- h_data$gesuche %>%
    dplyr::mutate(metrik = "gesuch", geburtskohorte = NA_character_)
  t1_bestand <- h_data$bestand %>%
    dplyr::mutate(metrik = "bestand", geburtskohorte = NA_character_)
  t1_alters <- h_data$alters %>%
    dplyr::mutate(metrik = "altersverteilung", status = NA_character_)
  t_time_metrics <- dplyr::bind_rows(t1_gesuch, t1_bestand, t1_alters)
  t2_kanton <- h_data$kanton %>% dplyr::mutate(geo_ebene = "kanton")
  t2_gemeinde <- h_data$gemeinde %>% dplyr::mutate(geo_ebene = "gemeinde")
  t_geo_distribution <- dplyr::bind_rows(t2_kanton, t2_gemeinde)
  return(list(
    ptlg_time_metrics = t_time_metrics,
    ptlg_geo_distribution = t_geo_distribution
  ))
}

#' Variante 3: Drei Tabellen als Outputs
#'
#' @keywords internal
.process_variant_3 <- function(h_data) {
  t_time <- dplyr::bind_rows(
    h_data$gesuche %>% dplyr::mutate(metrik_typ = "Gesuch"),
    h_data$bestand %>% dplyr::mutate(metrik_typ = "Bestand")
  )
  t_demo <- h_data$alters
  t_geo <- dplyr::bind_rows(
    h_data$kanton %>% dplyr::mutate(geo_ebene = "Kanton"),
    h_data$gemeinde %>% dplyr::mutate(geo_ebene = "Gemeinde")
  )
  return(list(
    time_metrics = t_time,
    driver_profiles = t_demo,
    geo_distribution = t_geo
  ))
}

#' Variante 4: Vier Tabellen als Output
#'
#' @keywords internal
.process_variant_4 <- function(h_data) {
  t_gesuche <- h_data$gesuche
  t_bestand <- h_data$bestand
  t_demo <- h_data$alters
  t_geo <- dplyr::bind_rows(
    h_data$kanton %>% dplyr::mutate(geo_ebene = "Kanton"),
    h_data$gemeinde %>% dplyr::mutate(geo_ebene = "Gemeinde")
  )
  return(list(
    ptlg_gesuche = t_gesuche,
    ptlg_bestand = t_bestand,
    ptlg_demografie = t_demo,
    ptlg_geografie = t_geo
  ))
}

#' Speichert eine Liste von Dataframes als einzelne CSV-Dateien
#'
#' @keywords internal
.export_ptlg_to_csv <- function(data_list, path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
    message(paste("Ordner wurde erstellt:", path))
  }
  purrr::iwalk(data_list, function(df, name) {
    file_name <- paste0(name, ".csv")
    full_path <- file.path(path, file_name)
    readr::write_csv(df, full_path)
    message(paste("Datei gespeichert:", full_path))
  })
  message("Export erfolgreich abgeschlossen.")
}
