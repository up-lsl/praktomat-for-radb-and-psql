#!/bin/bash


#+----------+
#|  KONFIG  |
#+----------+

# Welche Datenbank(vorlage)
dbFile="rating.sql"

# Welche Berechtigungen werden benötigt?
# read: Nur lesen | write: Datensätze schreiben/ändern | manage: View etc. erstellen | admin: Tabellen erstellen/editieren
executePermission="read"

# Berücksichtigung der Reihenfolge der Einträge (0: Nein | 1: Ja)
considerEntryOrder=0

# Berücksichtigung der Attribut-Reihenfolge (0: Nein | 1: Ja)
considerAttributeOrder=0

# Das Debug Level (wie viel wird beim Ausführen des Skriptes ausgegeben; Bereich von 1-7)
debugLevel=-1



#+----------+
#|  SKRIPT  |
#+----------+


# Funktionen nachladen
sideloadFunction "functions-simple-checks.sh" 0 1
sideloadFunction "functions-radb-psql.sh" 0 1


# Standardprozedur für PSQL ausführen
sideloadDefault "procedures/default-procedure-psql.sh" 0 1
