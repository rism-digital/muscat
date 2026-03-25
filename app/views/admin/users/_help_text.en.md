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

Rules can be repeated in your notification list, but they will be evaluated separately. For example:

```
lib_siglum:CH* composer:Bach*
lib_siglum:CH*
```

In this case, you will receive notifications for all CH sources containing Bach as the composer, plus notifications for all CH sources.

---

## Search categories

By default, rules apply to **sources**. You can also create alerts for other record categories by specifying the category at the beginning of the rule line followed by a space, such as:

```
work composer:Bach*
institution full_name:British*
person full_name:"Bach, Johann Sebastian"
```

Each rule line can only search one category.

---

## Wildcards and spaces

Rules can include wildcards to allow for truncation:

```
lib_siglum:CH*
```

This creates a notification for each source with a library siglum beginning with CH.

Search terms containing spaces must be enclosed in quotation marks:

```
composer:"Bach, Johann Sebastian"
```

or

```
composer:"Bach, Johann*"
```

If the quotation marks are missing, only the first word will be searched and the others ignored. The field name must never be enclosed in quotes.

---

## Special fields

### follow

The `follow` field matches the user who most recently edited the record. If no version information is available, it falls back to the record owner/creator.

Examples:

```
follow:username
source follow:username
person follow:username
```

If no category is specified, `follow` applies to **all record categories**:

```
follow:"Some User"
```

If a category is specified, only that category is searched:

```
source follow:"Some Other User"
```

notice that only the _full user name_ can be used here.

---

### owner

The `owner` field matches the owner of a record:

- If the value is a number → matches owner ID  
- If the value contains `@` → matches owner email  
- Otherwise → matches owner name  

Examples:

```
owner:123
owner:editor@example.org
owner:Jane Smith
work owner:editor@example.org
```

---

## Available categories and fields

### Sources (default)

- lib_siglum  
- shelf_mark  
- composer  
- std_title  
- title  
- record_type  
- follow  
- owner  

### Works

- composer  
- title  
- form  
- notes  
- follow  
- owner  

### Institutions

- full_name  
- place  
- siglum  
- address  
- alternates  
- notes  
- comments  
- follow  
- owner  

### People

- full_name  
- display_name  
- life_dates  
- birth_place  
- alternate_names  
- alternate_dates  
- follow  
- owner  

### Holdings

- lib_siglum  
- shelf_mark  
- follow  
- owner  

### Inventory items

- source_id  
- title  
- composer  
- page_info  
- follow  
- owner  

### Liturgical feasts

- name  
- notes  
- alternate_terms  
- viaf  
- gnd  
- follow  
- owner  

### Places

- name  
- country  
- district  
- notes  
- alternate_terms  
- hierarchy  
- tgn_id  
- follow  
- owner  

### Publications

- short_name  
- author  
- title  
- journal  
- volume  
- place  
- date  
- pages  
- work_catalogue  
- follow  
- owner  

### Standard terms

- term  
- alternate_terms  
- notes  
- sub_topic  
- viaf  
- gnd  
- follow  
- owner  

### Standard titles

- title  
- notes  
- alternate_terms  
- sub_topic  
- viaf  
- gnd  
- latin  
- follow  
- owner  

### Work nodes

- person_id  
- title  
- form  
- notes  
- composer  
- ext_number  
- ext_code  
- follow  
- owner  

---

## Notification frequency

- every — notification on each save (with ~1 hour grouping)
- daily — daily summary
- weekly — weekly summary
- off — notifications disabled

---

## Notes

- Each rule line is evaluated separately  
- Multiple fields on one line are combined with AND  
- Separate lines behave as separate searches  
- Default category is source, except follow, which can apply to all categories
