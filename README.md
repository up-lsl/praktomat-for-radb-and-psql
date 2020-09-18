# Praktomat für RADB und PSQL
Repository mit den Anpassungen der Anwendung "Praktomat" (https://github.com/KITPraktomatTeam/Praktomat) für die Datenbanklehre.



## Grundlegende Installation 

Entnehmen Sie das generelle Vorgehen zur Installation bitte dem Repository des KIT: https://github.com/KITPraktomatTeam/Praktomat#general-setup



## Vorgenommene Anpassungen

Für eine Überprüfung hochgeladener Dateien wird im Praktomat ein sogenannter Checker verwendet. Da für relationale Algebra und SQL ein derartiger Checker nicht zur Verfügung steht, wurde ein eigener, so genannter "Script Checker" hierfür implementiert. Diese wurden mit einfachen Bash-Skripten umgesetzt.



### Nachladen von Dateien

Um den Umfangreichen Skript Checker nicht jedes Mal im Webinterface hochladen zu müssen bzw. um dessen einfache Anpassung und Erweiterung zu gewährleisten, wurde eine Möglichkeit eingerichtet, um verschiedene Dateien nachzuladen. Prinzipiell sieht das Sicherheitskonzept des Praktomat vor, dass nicht direkt auf lokale Verzeichnisse des Servers zugegriffen werden kann. Daher wurde ein nur intern verfügbarer Apache Virtual Host erstellt, das nachzuladende Dateien enthält. Hierfür muss die Konfiguration der Apache available site angepasst bzw. folgendes hinzugefügt werden:

```
<VirtualHost *:[[INTERNER PORT]]>
    DocumentRoot [[PFAD ZU VERFÜGBAREN DATEIEN]]
    <Directory [[PFAD ZU VERFÜGBAREN DATEIEN]]>
        Order Deny,Allow
        Deny from all
        Allow from 127.0.0.1 ::1
        Allow from localhost
        Satisfy Any
    </Directory>
</VirtualHost>
```

Zusätzlich muss dieser Port intern freigegeben werden:

```bash
sudo nano /etc/apache2/ports.conf
```

Folgende Zeile hinzufügen:

```
Listen localhost:[[INTERNER PORT]]
```

Und Apache neu starten:

```bash
sudo service apache2 restart
```



Diese Anpassungen ermöglichen dann, ein möglichst schlankes Skript in die Weboberfläche zu laden, das lediglich das Nachladen der tatsächlich benötigten Dateien initiiert, wie folgendes Beispiel zeigt:

```
#!/bin/bash

#The taskid
taskid="test-radb1"

#Sideloading
curl -skO "https://localhost:[[INTERNER PORT]]/loader/loader.sh"
source ./loader.sh
```



### Die Checker Skripte

Die unter ``sideloads/`` zur Verfügung gestellten Dateien sind das Kernstück der Anpassungen. Hierin befindet sich folgendes:

- Loader: Enthält Funktionen zum Nachladen von Dateien
- Funktions: Enthält Funktionen zum Handling von Datenbankverbindungen, Ausführen von RADB-Kommandos und Überprüfung bzw. Abgleich der Programmoutputs
- Defaults:
  - Databases: Enthält sowohl SQLite als auch SQL Datenbanken, die für die Aufgaben verwendet werden
  - PSQL Queries: Enthält SQL Kommandos, die für das Handling der PSQL-Datenbank erforderlich sind
  - Procedures: Standardabläufe von Aufgaben (Eine PSQL- oder RADB-Aufgabe läuft in der Regel immer nach dem selben Schema ab. Diese sind hier definiert.)
  - Other: Weitere benötigte Dateien
- Tasks: Hierin sind die Aufgaben definiert.
  - Jeder Task hat eine ``taskid``, die dem Ordnernamen entspricht.
    - Checker.sh: Diese Datei wird geladen und aufgerufen. Sie ist für den vollständigen Überprüfungsvorgang verantwortlich. In der Regel werden hier alle benötigten Funktionen geladen und auf eine Standardprozedur (Defaults -> Procedures) verwiesen.
    - solution.output und solution.query: Enthält die Lösung der Aufgabe. Um den Prozess zu beschleunigen, kann bereits ein vollständiger Musterouput (solution.output) angegeben werden. Sollte dieser nicht vorhanden sein, wird das Kommando, das die korrekte Lösung erzeugt (solution.query) ausgeführt.



## Beispiel

Um die Anpassungen einfach zu integrieren, stellen wir für RADB sowie PSQL jeweils ein ausführlich kommentiertes Beispiel unter ``sideloads/tasks/`` bereit. Die jeweils dazu passende Datei, die in der Weboberfläche hochgeladen werden muss ist unter ``webupload/`` zu finden.

Die Beispiele stammen von *Jennifer Widom* und sind hier verfügbar: https://github.com/andylamp/stanford_dbclass