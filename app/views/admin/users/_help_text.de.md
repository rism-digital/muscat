## Verwendung von Benachrichtigungen

Per E-Mail-Benachrichtigungen können Sie sich benachrichtigen lassen, wenn Datensätze erstellt oder bearbeitet werden, die Ihren Suchregeln entsprechen.

Geben Sie diese Regeln in das Benachrichtigungsfeld ein.

Der Aufbau einer Regel besteht aus dem Feldnamen, gefolgt von einem Doppelpunkt und dann dem Suchbegriff. Beachten Sie, dass nach dem Doppelpunkt kein Leerzeichen steht. In diesem Beispiel wird eine Benachrichtigung generiert, wann immer ein Datensatz mit dem Bibliothekssigel CH-BEl gespeichert wird.

```
lib_siglum:CH-BEl
```

Geben Sie jede Regel in einer eigenen Zeile ein:

```
lib_siglum:CH-BEl
composer:Bach
```

Das bedeutet, dass Sie für jede gespeicherte Quelle mit dem Bibliothekssigel CH-BEl eine Benachrichtigung erhalten und eine weitere Benachrichtigung für jede gespeicherte Quelle mit dem Komponisten Bach.

Sie können Regeln kombinieren, indem Sie sie in derselben Zeile und durch ein Leerzeichen getrennt eingeben:

```
lib_siglum:CH* composer:Bach*
```

Dies findet Änderungen an allen Quellen, bei denen das Bibliothekssigel mit CH beginnt und der Komponist mit Bach beginnt.

Regeln können in Ihrer Benachrichtigungsliste wiederholt werden, werden jedoch jeweils separat ausgewertet. Zum Beispiel:

```
lib_siglum:CH* composer:Bach*
lib_siglum:CH*
```

In diesem Fall erhalten Sie Benachrichtigungen für alle CH-Quellen, die Bach als Komponisten enthalten, und zusätzlich Benachrichtigungen für alle CH-Quellen.

### Suchkategorien

Standardmäßig gelten die Regeln für Quellen. Sie können jedoch auch Benachrichtigungen für Normdateien erstellen, indem Sie dies am Anfang der Regelzeile angeben, gefolgt von einem Leerzeichen, zum Beispiel:

```
work composer:Bach*
institution name:British*
```

Jede Regel kann nur eine Kategorie durchsuchen.

### Platzhalter und Leerzeichen

Regeln können Platzhalter enthalten, um Trunkierung zu ermöglichen:

```
lib_siglum:CH*
```

Dies erstellt eine Benachrichtigung für jede Quelle, bei der das Bibliothekssigel mit CH beginnt.

Suchbegriffe, die Leerzeichen enthalten, müssen in Anführungszeichen gesetzt werden:

```
composer:"Bach, Johann Sebastian";
```

oder

```
composer:"Bach, Johann*";
```

Wenn die Anführungszeichen fehlen, wird nur nach dem ersten Wort gesucht, während die anderen ignoriert werden. Beachten Sie, dass der Feldname niemals in Anführungszeichen gesetzt werden darf.

### Verfügbare Kategorien und Felder

#### Quellen (Standard)

- **lib\_siglum** _Bibliothekssigel (852 \$a)_
- **shelf\_mark** _Bibliothekssignatur (852 \$c)_
- **composer** _Komponist/Autor (100 \$a)_
- **std\_title** _Standardisierter Titel (240 \$a)_
- **title** _Titel der Quelle (245 \$a)_
- **record\_type** _Vorlagentyp_:
  - collection (übergeordnete Datensätze für Manuskripte, Libretti oder Traktate)
  - source (Manuskripte, ohne Sammlungsdatensätze)
  - edition (gedruckte Musikausgaben, ohne einzelne Einträge)
  - edition\_content (einzelne Einträge in einer gedruckten Ausgabe)
  - libretto\_source (handgeschriebene Libretti, ohne Sammlungsdatensätze)
  - libretto\_edition (gedruckte Libretti, ohne einzelne Einträge)
  - libretto\_edition\_content (einzelne Einträge in einem gedruckten Libretto)
  - theoretica\_source (handgeschriebene Traktate, ohne Sammlungsdatensätze)
  - theoretica\_edition (gedruckte Traktate, ohne einzelne Einträge)
  - theoretica\_edition\_content (einzelne Einträge in einem gedruckten Traktat)
  - composite\_volume

Beispiel:

```
record_type:edition lib_siglum:CH* composer:Bach* std_title:"6 Fugues";
```

### Werke

- **composer** _Name des Komponisten (100 \$a)_
- **title** _Titel des Werks (100 \$t)_

Beispiel:

```
work composer:"Bach, Albert*"
```

### Institutionen

- **name** _Bevorzugte Form des Institutionsnamens (110 \$a)_
- **place** _Stadt der Institution (110 \$c)_
- **siglum** _Institutionssigel (110 \$g)_
- **address** _Institutionsadresse (371 \$a)_
- **alternates** _Alternative Namen (510 oder 410)_
- **notes** _Beliebiger Inhalt im Notizenfeld (680 \$a)_

Beispiel:

```
institution name:Universitätsbibliothek*
```

### Benachrichtigungshäufigkeit

Über das Dropdown-Menü „Kadenz der Benachrichtigung“ können Sie auswählen, wie häufig die Benachrichtigungen versendet werden:

- **Jedes Mal, wenn ein passender Datensatz gespeichert wird**  
  Sendet bei jedem Speichern einer Quelle eine Benachrichtigung (mit einer Karenzzeit von einer Stunde, um Mehrfachspeicherungen zusammenzufassen)

- **Jeden Tag**  
  Eine Liste der geänderten Quellen wird einmal täglich versendet

- **Jede Woche**  
  Eine Liste der geänderten Quellen wird einmal wöchentlich versendet

- **Benachrichtigungen sind deaktiviert**  
  Benachrichtigungen sind deaktiviert
