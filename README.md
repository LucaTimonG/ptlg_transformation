# 🚕 ptlg_transformation

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-Package](https://img.shields.io/badge/R-Package-blue.svg)](https://cran.r-project.org/)
<!-- badges: end -->

**`ptlg_transformation`** ist ein spezialisiertes R-Paket zur automatisierten Konsolidierung und Transformation von Taxidaten (PTLG). Es überführt heterogene Rohdatentabellen in harmonisierte, strukturierte Formate, die ideal für moderne Analysen, BI-Tools (z. B. Power BI, Tableau) oder die Publikation als Open Data geeignet sind.

---

##  Projektziel & Vision

Das Ziel dieses Projekts ist es, die Analyse von Taxidaten durch eine standardisierte Datenpipeline zu professionalisieren. Die Tabellen sollen ggf. reduziert werde. Mit diesem Tool ist dies möglich.

##  Installation

Das Paket ist in einem öffentlichen GitHub-Repository verfügbar und kann über `remotes` installiert werden.

### 1. Voraussetzungen
Falls noch nicht installiert, installieren Sie zuerst das Paket `remotes`:
```r
install.packages("remotes")
```

### 2. Installation vom GitHub-Repository
```r
remotes::install_github("LucaTimonG/ptlg_transformation")
```

---

##  Verwendung

Die zentrale Funktion des Pakets ist `transform_data()`. Sie steuert den gesamten Prozess vom Einlesen der Rohdaten bis zum Export der CSV-Dateien.

### Basis-Beispiel
```r
library(ptlg_transformation)

# Transformation mit den Standardeinstellungen (Variante 3)
transform_data(
  path_input = "pfad/zu/den/rohdaten", 
  path_output = "pfad/zum/export"
)
```

### Parameter-Details
| Parameter | Beschreibung | Standard |
| :--- | :--- | :--- |
| `path_input` | Pfad zum Ordner mit den ursprünglichen PTLG-CSV-Tabellen. | *Erforderlich* |
| `target_tables` | Anzahl der gewünschten Output-Tabellen (1, 2, 3 oder 4). | `3` |
| `path_output` | Pfad für den Export der CSV-Dateien. | `path_input` |

---

##  Die 4 Transformations-Varianten

Je nach gewähltem `target_tables`-Wert wird eine andere Aggregationslogik angewendet, um unterschiedliche Analysebedürfnisse zu bedienen:

*   **🔹 Variante 1: Master-Tabelle (`target_tables = 1`)**
    Erstellt eine einzige, stark normierte Master-Tabelle im Long-Format. Alle Dimensionen werden untereinander geschrieben. Ideal für komplexe Datenbank-Importe.
*   **🔹 Variante 2: Metriken & Geografie (`target_tables = 2`)**
    Teilt die Daten in zwei logische Cluster:
    *   *Zeit-Metriken:* Fusion von Gesuchen, Bestand und Altersverteilung.
    *   *Geografische Verteilung:* Fusion von Kantons- und Gemeindedaten.
*   **🔹 Variante 3: Thematische Cluster (`target_tables = 3`) — Empfohlen**
    Die optimierte Aufteilung für Storytelling und detaillierte Analysen:
    *   *Marktdynamik (`time_metrics`):* Gesuche und aktiver Bestand als Zeitreihen.
    *   *Marktprofil (`driver_profiles`):* Demografische Daten der Fahrerschaft.
    *   *Räumliche Struktur (`geo_distribution`):* Verteilung nach Kanton und Gemeinde.
*   **🔹 Variante 4: Einzel-Tabellen (`target_tables = 4`)**
    Exportiert vier separate Tabellen (Gesuche, Bestand, Demografie, Geografie). Hier werden lediglich die geografischen Ebenen (Kanton/Gemeinde) konsolidiert.

---

##  Technische Dokumentation

### Daten-Mapping
Das Paket verarbeitet die folgenden Rohdatenquellen und harmonisiert sie:

| Rohdatei | Fokus | Transformation |
| :--- | :--- | :--- |
| `gesuche_nach_monat` | Prozess-Dynamik | Zeitreihen-Harmonisierung |
| `aktiver_bestand_monatlich` | Marktvolumen | Spalten-Mapping auf `anzahl` |
| `altersverteilung_fahrer` | Demografie | Mapping auf `geburtskohorte` |
| `fahrzeuge_nach_kanton` | Grobräumig | Mapping auf `geo_name` $\rightarrow$ Ebene "Kanton" |
| `kommunale_bewilligungen` | Detailräumig | Mapping auf `geo_name` $\rightarrow$ Ebene "Gemeinde" |

### Workflow-Pipeline
1.  ** Load:** Automatisches Einlesen der definierten Pflichttabellen.
2.  ** Harmonize:** Vereinheitlichung der Spaltennamen und Korrektur der Datentypen (z. B. Jahre als `character`, um BI-Tool-Fehler zu vermeiden).
3.  ** Aggregate:** Anwendung der gewählten Variante (1–4) zur strukturellen Umformung.
4.  ** Export:** Bereitstellung der resultierenden Tabellen als saubere CSV-Dateien.
