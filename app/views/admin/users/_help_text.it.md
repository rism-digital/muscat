## Come usare le notifiche

Le notifiche e-mail possono essere impostate in modo da essere avvisati ogni volta che vengono creati o modificati dei record che corrispondono alle tue regole di ricerca.

Inserisci queste regole nella casella delle notifiche.

La struttura di una regola è il campo, due punti, poi il termine di ricerca. Nota che non c'è spazio dopo i due punti. In questo esempio, una notifica sarà generata ogni volta che un record con il siglum di libreria CH-BEl viene salvato.

```
lib_siglum:CH-BEl
```

Inserisci regole separate su linee separate:

```
lib_siglum:CH-BEl
composer:Bach
```

Questo significa che riceverai una notifica per ogni sorgente salvata con libreria siglum CH-BEl e un'ulteriore notifica per ogni sorgente salvata con compositore Bach.

Puoi combinare le regole mettendole sulla stessa linea, separate da uno spazio:

```
lib_siglum:CH* composer:Bach*
```

Questo troverà le modifiche a tutte le fonti con entrambe le librerie sigla che iniziano con CH e compositore che inizia con Bach.

Le regole possono essere ripetute con la tua lista di notifica, ma saranno valutate separatamente. Per esempio:

```
lib_siglum:CH* composer:Bach*
lib_siglum:CH*
```

In questo caso, riceverai le notifiche per tutte le fonti CH che contengono Bach come compositore, più le notifiche per tutte le fonti CH.

### Categorie di ricerca

Per impostazione predefinita, le regole si applicano alle fonti. Puoi anche creare avvisi per i file di autorità specificandolo all'inizio della linea della regola seguito da uno spazio, come ad esempio:

```
work composer:Bach*
institution name:British*
```

Ogni regola può cercare solo una categoria.

### Caratteri jolly e spazi

Le regole possono includere caratteri jolly per consentire il troncamento:

```
lib_siglum:CH*
```

Questo crea una notifica per ogni sorgente con una libreria siglum che inizia con CH.

I termini di ricerca che contengono spazi devono essere racchiusi tra virgolette:

```
composer:"Bach, Johann Sebastian";
```

oppure

```
composer:"Bach, Johann*";
```

Se mancano le virgolette, verrà cercata solo la prima parola e le altre verranno ignorate. Nota che il nome del campo non deve mai essere racchiuso tra virgolette.

### Categorie e campi disponibili

#### Fonti (predefinito)

- **lib\_siglum** _Library siglum (852 $a)_
- **shelf_mark** _Marcatura dello scaffale della biblioteca (852 $c)_
- **composer** _Compositore/autore (100 $a)_
- **std_title** _Titolo standardizzato (240 $a)_
- **title** _Titolo alla fonte (245 $a)_
- **record_type** _Tipo di modello_:
  - collection (scheda madre per manoscritti, libretti o trattati)
  - source (manoscritti, esclusi i registri delle collezioni)
  - edition (edizioni di musica stampata, escluse le voci individuali)
  - edition_content (voci individuali all'interno di un'edizione stampata)
  - libretto_source (libretti scritti a mano, esclusi i record di collezione)
  - libretto_edition (libretti stampati, escluse le singole voci)
  - libretto\_edition\_content (singole voci in un libretto stampato)
  - theoretica_source (trattati scritti a mano, esclusi i record di collezione)
  - theoretica_edition (trattati stampati, escluse le singole voci) 
  - theoretica\_edition\_content (singole voci in un trattato stampato)
  - composite_volume

Esempio:

```
record_type:edition lib_siglum:CH* composer:Bach* std_title:"6 Fugues";
```

### Works

- **composer** _Nome del compositore (100 $a)_
- **title** _Titolo dell'opera (100 $t)_

Esempio:

```
work composer: "Bach, Albert*"
```

### Istituzioni

- **name** _forma autorizzata del nome dell'istituzione (110 $a)_
- **place** _Città dell'istituzione (110 $c)_
- **siglum** _Sigla dell'istituzione (110 $g)_
- **address** _Indirizzo dell'istituzione (371 $a)_
- **alternates** _Nomi alternativi (510 o 410)_.
- **notes** _Qualsiasi cosa nel campo note (680 $a)_

Esempio:

```
institution name:Universitätsbibliothek*
```

### Frequenza delle notifiche

Con il selettore a tendina &quot;Tipo di notifica&quot; puoi scegliere la frequenza con cui vengono fatte le notifiche:

- **ogni** Invia una notifica ogni volta che una fonte viene salvata (con un periodo di grazia di un'ora per tenere conto dei salvataggi multipli)
- **giornalmente** Una lista delle fonti modificate viene inviata una volta al giorno
- **titolo** Una lista delle fonti modificate viene inviata una volta alla settimana
- **off** Le notifiche sono disabilitate
