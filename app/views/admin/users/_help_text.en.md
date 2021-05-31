## How to use Notifications

Email notifications can be set up so that you are alerted whenever records are created or edited that match your search rules.

Enter these rules in the notifications box.

The structure of a rule is the field, a colon, then the search term. Note that there is no space after the colon. In this example, a notification will be generated whenever a record with the library siglum CH-BEl is saved.

```
lib_siglum:CH-BEl
```

Enter separate rules on separate lines:

```
lib_siglum:CH-BEl
composer:Bach
```

This means that you will receive one notification for each saved source with library siglum CH-BEl and an additional notification for each saved source with composer Bach.

You can combine rules by putting them on the same line, separated by a space:

```
lib_siglum:CH* composer:Bach*
```

This will find changes to all sources with both library sigla beginning with CH and composer beginning with Bach.

Rules can be repeated with your notification list but they will be evaluated separately. For example:

```
lib_siglum:CH* composer:Bach*
lib_siglum:CH*
```

In this case, you will receive notifications for all CH sources containing Bach as the composer, plus notifications for all CH sources.

### Search categories

By default, rules apply to sources. You can also create alerts for authority files by specifying it at the beginning of the rule line followed by a space, such as:

```
work composer:Bach*
institution name:British*
```

Each rule can only search one category.

### Wildcards and spaces

Rules can include wildcards to allow for truncation:

```
lib_siglum:CH*
```

This creates a notification for each source with a library siglum beginning with CH.

Search terms containing spaces must be enclosed in quotation marks:

```
composer:"Bach, Johann Sebastian";
```

or

```
composer:"Bach, Johann*";
```

If the quotation marks are missing, only the first word will be searched, and the others ignored. Note that the field name must never be enclosed in quotes.

### Available categories and fields

#### Sources (default)

- **lib\_siglum** _Library siglum (852 $a)_
- **shelf\_mark** _Library shelf mark (852 $c)_
- **composer** _Composer/author (100 $a)_
- **std\_title** _Standardized title (240 $a)_
- **title** _Title on source (245 $a)_
- **record\_type** _template type_:
    - collection (parent records for manuscripts, libretti, or treatises)
    - source (manuscripts, excluding collection records)
    - edition (printed music editions, excluding individual entries)
    - edition\_content (individual entries within a printed edition)
    - libretto\_source (handwritten libretti, excluding collection records)
    - libretto\_edition (printed libretti, excluding individual entries)
    - libretto\_edition\_content (individual entries in a printed libretto)
    - theoretica\_source (handwritten treatises, excluding collection records)
    - theoretica\_edition (printed treatises, excluding individual entries) 
    - theoretica\_edition\_content (individual entries in a printed treatise)
    - composite\_volume

Example:

```
record_type:edition lib_siglum:CH* composer:Bach* std_title:"6 Fugues";
```

### Works

- **composer** _Composer name (100 $a)_
- **title** _Title of work (100 $t)_

Example:

```
work composer: "Bach, Albert*"
```

### Institutions

- **name** _Authorized form of__institution name (110 $a)_
- **place** _Institution city (110 $c)_
- **siglum** _Institution sigulm (110 $g)_
- **address** _Institution address (371 $a)_
- **alternates** _Alternate names (510 or 410)_
- **notes** _Anything in the notes field (680 $a)_

Example:

```
institution name:Universitätsbibliothek*
```

### Notification frequency

With the &quot;Notification type&quot; drop-down selector, you can choose the frequency with which the notifications are made:

- **every** Send a notification each time a source is saved (with a grace period of one hour to account for multiple saves)
- **daily** A list of the modified sources is sent once a day
- **title** A list of the modified sources is sent once a week
- **off** Notifications are disabled