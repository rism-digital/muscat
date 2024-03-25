## Com funcionen les notificacions

Es poden crear notificacions per rebre alertes per correu quan es creïn o editin registres que corresponguin amb les vostres regles de cerca.

Entreu aquestes regles a la casella de les notificacions.

L'estructura de cada regla es: nom del camp, dos punts, i el terme de cerca. Fixeu-vos que no hi ha cap espai després dels dos punts. En aquest exemple, es generarà una notificació cada cop que es desi un registre amb la sigla de la biblioteca CH:BE1.

```
lib_siglum:CH-BEl
```

Entreu cada regla en una línia diferent:

```
lib_siglum:CH-BEl
composer:Bach
```

Aquesta vol dir que rebreu una notificació per a cada registre de font que tingui com a sigla de biblioteca CH-BE1, i una altra per a cada registre de font del compositor Bach.

Podeu combinar regles posant-les en una mateixa línia, separades per un espai:

```
lib_siglum:CH* composer:Bach*
```

Aquesta us trobarà canvis a tots els registres de font que tinguin una sigla de biblioteca que comenci per CH i un compositor que comenci per Bach.

Les regles es poden repetir a la llista de notificacions, però s'avaluaran per separat. Per exemple:

```
lib_siglum:CH* composer:Bach*
lib_siglum:CH*
```

En aquest cas, rebreu notificacions per a tots els registres de font de CH que tinguin com a compositor Bach, i a més a més, notificacions per a tots els registres de font de CH:

### Categories de cerca

Per defecte, les regles s'apliquen als registres de font. Però també en podeu crear per a registres d'autoritat, especificant-ho al començament de la regla i seguida d'un espai, com ara:

```
work composer:Bach*
institution name:British*
```

Cada regla només pot cercar una categoria.

### Asteriscs i espais

Les regles poden incloure asteriscs per permetre truncaments:

```
lib_siglum:CH*
```

Aquesta crea una notificació per a cada registre de font en què la sigla de la biblioteca comenci per CH.

Els termes de cerca que tinguin espais s'han de posar entre cometes:

```
composer:"Bach, Johann Sebastian";
```

o

```
composer:"Bach, Johann*";
```

Sense cometes, només es cercaria la primera paraula, i les altres s'ignorarien. Fixeu-vos que el nom del camp no les porta, les cometes.

### Catetories i camps disponibles:

#### Registres de font (valor per defecte)

* **lib\_siglum** _Sigla de biblioteca (852 $a)_
* **shelf\_mark** _Topogràfic (852 $c)_
* **composer** _Compositor/autor (100 $a)_
* **std\_title** _Títol uniforme (240 $a)_
* **title** _Títol propi (245 $a)_
* **record\_type** _tipus de plantilla_:
    * collection (registre mare per a manuscrits, llibrets o tractats)
    * source (manuscrits, llevat dels de col·leccions)
    * edition (edicions de música impresa, menys les entrades individuals)
    * edition\_content (entrades individuals d'una edició impresa)
    * libretto\_source (llibrets manuscrits, menys els registres de col·lecció)
    * libretto\_edition (llibrets impresos, llevat les entrades individuals)
    * libretto\_edition\_content (entrades individuals en llibrets impresos)
    * theoretica\_source (tractats manuscrits, llevat dels registres de col·lecció)
    * theoretica\_edition (tractats impresos, menys les entrades individuals) 
    * theoretica\_edition\_content (entrades individuals en un tractat imprès)
    * composite\_volume

Exemple:

```
record_type:edition lib_siglum:CH* composer:Bach* std_title:"6 Fugues";
```

### Obras

- **composer** _Nom del compositor (100 $a)_
- **title** _Títol de la obra (100 $t)_

Exemple:

```
work composer: "Bach, Albert*"
```

### Institucions

- **name** _Forma autoritzada del nom de la institució (110 $a)_
- **place** _Ciutat de la institució (110 $c)_
- **siglum** _Sigla de la institució (110 $g)_
- **address** _Adreça de la institució (371 $a)_
- **alternates** _Noms alternatius (510 or 410)_
- **notes** _Qualsevol paraula del camp de notes (680 $a)_

Exemple:

```
institution name:Universitätsbibliothek*
```

### Freqüència de les notificacions

En el desplegable _Freqüència de les notificacions_ podeu triar la freqüència de cada quan voleu que s'us notifiqui:

- **cada cop** Enviar una notificació cada cop que es desa un registre (amb un període de gràcia d'una hora quan un registre es desa més d'un cop per la mateixa persona).
- **cada dia** La llista dels registres modificats s'envia un cop al dia.
- **cada setmana** La llista dels registres modificats s'envia un cop a la setmana.
- **desactivades** Les notifications estan desactivades.
