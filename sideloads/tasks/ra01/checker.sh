#!/bin/bash


#+----------+
#|  KONFIG  |
#+----------+

# Welches SQLite Files
dbFile="pizza.db"

# Das Debug Level (wie viel wird beim Ausführen des Skriptes ausgegeben; Bereich von 1-7)
debugLevel=-1



#+----------+
#|  SKRIPT  |
#+----------+

# Datenbank-Datei nachladen
sideloadDefault "databases/$dbFile" 0 0


# Funktionen nachladen
sideloadFunction "functions-simple-checks.sh" 0 1
sideloadFunction "functions-radb-psql.sh" 0 1


# Standardprozedur für RADB ausführen
sideloadDefault "procedures/default-procedure-radb.sh" 0 1
