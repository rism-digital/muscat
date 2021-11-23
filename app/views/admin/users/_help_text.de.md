
      
      <h3>Wie benutze ich Benachrichtigungen?</h3>
      <p>Das Benachrichtigungsfeld ermöglicht das Einfügen einiger Suchmuster, die, wenn sie mit den gefundenen Daten übereinstimmen, eine Benachrichtigung an den Benutzer senden.<br>
        Beispielsweise kann ein Suchkriterium erstellt werden, so dass jedes Mal, wenn eine Quelle in CH-BEl gespeichert wird, der Benutzer eine Benachrichtigung erhält:</p>
        <pre>lib_siglum:CH-BEl</pre>
        <b>Beachten Sie, dass nach dem Doppelpunkt kein Leerzeichen vorhanden ist. </b>Eine Regel pro Zeile wird separat ausgewertet:
<pre>lib_siglum:CH-BEl
composer:Bach</pre>
          Bedeutet: Erstellen Sie eine Benachrichtigung für jede geänderte Quelle mit lib_siglum CH-BEl, erstellen Sie eine Benachrichtigung für jede geänderte Quelle mit dem Komponisten Bach.<br>
          Regeln können Platzhalter enthalten:
          <pre>lib_siglum:CH*</pre>
          Erstellen Sie eine Benachrichtigung für jede Quelle mit einem lib_siglum, das mit CH beginnt.<br>
          Derzeit ist das Benachrichtigungssystem nur für <b>Quellen</b> und für die folgenden Felder verfügbar:
          <p>
            <ul>
              <li><b>std_title</b> <i>Standardtitel</i></li>
              <li><b>composer</b> <i>Vollständiger Name des Komponisten</i></li>
              <li><b>title</b> <i>Diplomatischer Titel</i></li>
              <li><b>shelf_mark</b> <i>Bibliothekssigel</i></li>
            </ul>
          </p>
          
          Der Popup-Selektor unter dem Feld wählt die Häufigkeit, mit der die Benachrichtigungen erfolgen:
          <p>
            <ul>
              <li><b>each</b> Senden Sie jedes Mal eine Benachrichtigung, wenn eine Quelle gespeichert wird (mit einer Kulanzzeit von einer Stunde, um mehrere Sicherungsvorgänge herauszufiltern)</li>
              <li><b>daily</b> Eine Liste der geänderten Quellen wird jeden Tag gesendet</li>
              <li><b>title</b> Eine Liste der geänderten Quellen wird jede Woche gesendet</li>
              <li><b>keine Auswahl</b> Benachrichtigungen sind deaktiviert</li>
            </ul>
          </p>
