# Roadmap

## 07.06.2012
* T.1 - statische Seite wo ACE eingebunden ist
* T.1.1 - Analyse der Sprache und der Konfigurationsmöglichkeiten von ACE
* T.1.2
* Komponentendiagramm
* Sequenzdiagramm

## 14.06.2012
* Featurediagramm
* Klassendiagramm
* Entscheidung OO2 Server vs. AOLServer/NaviServer
* T.1.1 - Syntaxauswahl auf der Editorseite
* T.2 - Scripts können ausgewählt werden
* T.4 - UI für die Funktionalität ist gemockt(keine Interaktion mit dem Server)

## 21.06.2012
* T.3 - einfacher Server läuft
* T.4 - es erfolgt eine Interaktion mit dem Server

#Tasks
## T.1 Textfeld mit Syntaxhighlighting (ACE konfigurieren)
## T.1.1 Syntaxauswahl: Tcl, Tcl+XOTcl, Tcl+NX; Wahl der Beschreibungsmittel (keywords, ...) anhand der ACE-Konfigurationsmöglichkeiten
## T.1.2 Automatisch Generierung der ACE-Konfiguration aus Tcl heraus (sh. auch T3)
* ein Script schreiben, welches mit Hilfe von Reflection die Konfiguration für ACE generiert

## T.2 Eine Sammlung von Sample Scripts zusammentragen und einbauen
* Input von SSo

## T.2.1 Auswahl
## T.2.2 Verwaltung (serversseitig)
## T.2.3 Menü-Integration in der ACE-Umgebung

## T.3 eine einfachen Server aufsetzen, der den Code ausführt
## T.3.1 Anpassen des OO2-Webservers (Alternativ: AOLServer/NaviServer)
## T.3.2 Tcl Backend: "Gesicherte" Laufzeitumgebung für die Web-Skripte (sh. "Safe interpreters" in Tcl)
## (T.3.3 Unterstützung versch. Tcl-Versionen bzw. XOTcl/Nx-Versionen)

## T.4 den Input im Textfeld an den Server schicken und das Resultat anzeigen
## T.4.1 HTTP-Interaktionen (POSTs) auf Klientenseite sowie Callbacks für Antworten
## T.4.2 Einbinden der Ergebnisse im/um das Textfeld
* bei Fehler wenn möglich Zeile im Editor anzeigen(Zeileninfo parsen) ansonsten Output anzeigen

# References
* https://github.com/ajaxorg/ace/wiki/Embedding---API