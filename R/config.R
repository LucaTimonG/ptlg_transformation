.ptlg_config <- list(
  required_tables = c(
    "ptlg_gesuche_nach_monat",
    "ptlg_aktiver_bestand_monatlich",
    "ptlg_altersverteilung_fahrer",
    "ptlg_fahrzeuge_nach_kanton",
    "ptlg_kommunale_bewilligungen_stichtag"
  ),
  column_mapping = list(
    bestand = "anzahl_aktiv",
    alters = "geburtsjahrgang_kohorte",
    kanton = "kanton_kennzeichen",
    gemeinde = "gemeinde_name"
  )
)
