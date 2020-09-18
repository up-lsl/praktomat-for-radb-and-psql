#!/bin/bash

#Die taskid
#==> Name des Ordners der alle Dateien der Aufgabe enthält
taskid="ra01"

#Nachladen
#==> Lädt zunächst die Funktionsdatei loader.sh, die anschließend (primär) die Datei checker.sh aus dem Aufgabenordner lädt und ausführt.
curl -skO "https://localhost:[[INTERER PORT]]/loader/loader.sh"
source ./loader.sh