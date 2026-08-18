# Notification matching rules

Muscat uses `NotificationMatcher` (`lib/notification_matcher.rb`) to decide
whether a created or modified record should be included in a user's
notification email.

The visual notification editor reads and writes the legacy text stored in
`users.notifications`. It parses supported lines into visual cards in the
browser and preserves lines it cannot safely convert in the advanced section.
`NotificationMatcher` is the only Ruby parser and evaluates the stored text
when notifications are generated.

This document describes the behavior of the matcher itself. It intentionally
documents implementation quirks as well as the intended syntax.

## Canonical rule configuration

The canonical model names, allowed fields, special fields, exact-match fields,
and Rails model-name normalization are defined in:

```text
lib/notification_matcher.rb
```

The visual editor receives this configuration from `NotificationMatcher` when
Rails renders the form. Changes to supported models or fields should therefore
be made in the matcher rather than copied into a separate backend service.

## Rule syntax

The general form of one rule is:

```text
[model] field:pattern [field:pattern ...] [exclude:mine]
```

For example:

```text
composer:Bach*
work composer:"Bach, Johann*" title:*Mass*
institution full_name:"British Library"
```

Model and field names should be lowercase. There must not be a space between a
field name, its colon, and its value.

### OR and AND

Each line is an independent rule. Separate lines are alternatives and
therefore behave as OR:

```text
composer:Bach*
title:*Motet*
```

The example matches a source whose composer starts with `Bach` OR whose title
contains `Motet`.

Conditions on the same line must all match and therefore behave as AND:

```text
lib_siglum:CH* composer:Bach*
```

The example matches a source only when both conditions match.

A record matching more than one independent line can produce more than one
match in the generated notification.

### Values containing spaces

Values containing spaces must use double quotes:

```text
composer:"Bach, Johann Sebastian"
```

Without quotes, words after the first space are treated as standalone tokens
and normally ignored.

Field names must not be quoted.

Single quotes do not group a value. Only double quotes are recognized.

### Colons in values

Values cannot contain a colon. The parser splits a condition on `:` and accepts
it only when the result has exactly two parts.

This does not parse successfully:

```text
composer:"Bach: Johann"
```

## Models and fields

Rules without an explicit model default to `source`, except for the special
unqualified `follow` behavior described below.

Model names use Rails' singular, underscored model name
(`model.model_name.element`). The canonical names are:

```text
source
work
institution
holding
person
inventory_item
liturgical_feast
place
publication
standard_term
standard_title
work_node
```

### Source

The `source` model is optional:

```text
composer:Bach*
source composer:Bach*
```

Both forms are equivalent.

Allowed fields:

- `record_type`
- `std_title`
- `composer`
- `title`
- `shelf_mark`
- `lib_siglum`
- `follow`
- `owner`

### Work

```text
work composer:Bach* title:*Mass*
```

Allowed fields:

- `title`
- `form`
- `notes`
- `composer`
- `follow`
- `owner`

### Institution

```text
institution full_name:"British Library"
```

Allowed fields:

- `siglum`
- `full_name`
- `address`
- `place`
- `comments`
- `alternates`
- `notes`
- `follow`
- `owner`

The field is `full_name`, not `name`. Some older help text incorrectly uses
`institution name:...`; that rule is parsed but cannot match.

### Person

```text
person full_name:"Clara Schumann"
```

Allowed fields:

- `full_name`
- `life_dates`
- `birth_place`
- `alternate_names`
- `alternate_dates`
- `display_name`
- `follow`
- `owner`

### Holding

```text
holding lib_siglum:CH-BEl shelf_mark:*123*
```

Allowed fields:

- `lib_siglum`
- `shelf_mark`
- `follow`
- `owner`

### Place

```text
place name:Basel country:Switzerland
```

Allowed fields:

- `name`
- `country`
- `district`
- `notes`
- `alternate_terms`
- `hierarchy`
- `tgn_id`
- `follow`
- `owner`

### Publication

```text
publication title:*Motets* date:19*
```

Allowed fields:

- `short_name`
- `author`
- `title`
- `journal`
- `volume`
- `place`
- `date`
- `pages`
- `work_catalogue`
- `follow`
- `owner`

### Inventory item

```text
inventory_item title:*Mass*
```

Allowed fields:

- `source_id`
- `title`
- `composer`
- `page_info`
- `follow`
- `owner`

### Liturgical feast

```text
liturgical_feast name:Easter
```

Allowed fields:

- `name`
- `notes`
- `alternate_terms`
- `viaf`
- `gnd`
- `follow`
- `owner`

### Standard term

The model name is singular:

```text
standard_term term:Motet
```

Allowed fields:

- `term`
- `alternate_terms`
- `notes`
- `sub_topic`
- `viaf`
- `gnd`
- `follow`
- `owner`

### Standard title

The model name is singular:

```text
standard_title title:Mass
```

Allowed fields:

- `title`
- `notes`
- `alternate_terms`
- `sub_topic`
- `viaf`
- `gnd`
- `latin`
- `follow`
- `owner`

### Work node

```text
work_node composer:Bach*
```

Allowed fields:

- `person_id`
- `title`
- `form`
- `notes`
- `composer`
- `ext_number`
- `ext_code`
- `follow`
- `owner`

The old plural spellings `standard_terms` and `standard_titles` are not model
aliases. They are not recognized as model names. Because unknown models default
to `source`, using either old spelling can accidentally create a source rule.
Existing rules should therefore be rewritten with `standard_term` and
`standard_title` before using this matcher version.

## Normal wildcard matching

Most fields use anchored, case-insensitive wildcard matching. Without a
wildcard, the complete field value must match.

| Pattern | Meaning |
| --- | --- |
| `Bach` | Exactly `Bach` |
| `Bach*` | Starts with `Bach` |
| `*Bach` | Ends with `Bach` |
| `*Bach*` | Contains `Bach` |
| `B*ch` | Starts with `B`, followed later by `ch` |

The `*` wildcard can occur more than once. Internally, each wildcard becomes a
non-greedy `.*?` regular-expression fragment, and the complete expression is
anchored at its beginning and end.

The special fields below do not all follow these wildcard rules.

## Special fields

### `follow`

```text
follow:"Rodolfo Zitellini"
```

`follow` matches the name of the record's last modifier. When the record
responds to `last_version_author`, the matcher uses that value. Otherwise, it
uses the last PaperTrail version's `whodunnit`. If that result is blank, it
falls back to `current_user_name`, when supplied by the digest query, and then
to the associated user's name when available.

The comparison is exact and case-insensitive. Wildcards do not work for
`follow`.

An unqualified rule containing only one or more `follow` conditions is expanded
to every configured model:

```text
follow:"Rodolfo Zitellini"
```

An explicit model restricts it:

```text
source follow:"Rodolfo Zitellini"
person follow:"Rodolfo Zitellini"
```

`all` is not an explicit model keyword. The all-model behavior exists only for
an unqualified rule containing exclusively `follow` conditions.

### `owner`

`owner` matches the user associated with the record:

```text
owner:702
owner:person@example.org
owner:"Rodolfo Zitellini"
```

The pattern is interpreted as follows:

- digits only: exact user ID;
- contains `@`: exact email address, case-insensitive;
- otherwise: exact user name, case-insensitive.

The object must respond to `user` and have an associated user. Wildcards do not
work for `owner`.

### `record_type`

`record_type` applies to sources and performs an exact lookup in
`MarcSource::RECORD_TYPES`.

Recognized values are:

- `unspecified`
- `collection`
- `source`
- `edition_content`
- `libretto_source`
- `libretto_edition`
- `theoretica_source`
- `theoretica_edition`
- `edition`
- `libretto_edition_content`
- `theoretica_edition_content`
- `composite_volume`
- `inventory`
- `inventory_edition`

Example:

```text
record_type:edition
```

Wildcards do not work for `record_type`.

### Source `lib_siglum`

For source rules, `lib_siglum` calls `Source#siglum_matches?`. Before doing so,
the matcher removes every `*` from the pattern. `siglum_matches?` then performs
a case-insensitive `start_with?` comparison.

Consequently, all these patterns have effectively the same starts-with
behavior:

```text
lib_siglum:CH
lib_siglum:CH*
lib_siglum:*CH
lib_siglum:*CH*
```

For editions, the matcher searches the edition's holdings. For edition-content
records, it searches the parent edition's holdings. Other source types use the
source's `lib_siglum`.

The generic `holding lib_siglum:...` field does not use this source-specific
special case; it uses normal wildcard matching.

### Source `shelf_mark`

For collections, manuscript sources, libretti, treatises, and composite
volumes, `shelf_mark` uses normal wildcard matching against the source shelf
mark.

For editions, it searches the shelf marks of the edition's holdings. For
edition-content records, it searches the parent edition's holdings.

### Work `composer`

For works, `composer` is matched against `work.person.name`, using normal
case-insensitive wildcard matching. A work without an associated person does
not match a composer rule.

For sources and other models, `composer` is treated as a normal property when
that model allows and exposes it.

## Excluding a user's own changes

The only implemented exclusion is:

```text
exclude:mine
```

Example:

```text
composer:Bach* exclude:mine
```

The matcher compares the last PaperTrail version's `whodunnit` with the
receiving user's name, case-insensitively. If they match, the notification is
skipped.

### Exclusion quirks

The exclusion is collected across all rule lines for one model. If any rule
for that model contains `exclude:mine`, an own modification can skip every rule
for that model, not only the line containing the exclusion.

Also, adding an exclusion prevents an unqualified `follow` rule from being
recognized as an all-model rule:

```text
follow:"Rodolfo Zitellini" exclude:mine
```

Because this line contains both `follow` and `exclude`, it defaults to `source`.
It is not expanded to every model.

Other exclusion values are parsed and removed from the conditions, but have no
implemented effect.

## Parser and matching quirks

### Unknown model names default to sources

Only an exact lowercase model name at the beginning of the line is recognized.
An unknown or incorrectly capitalized model is not rejected; the rule silently
defaults to `source`.

```text
Institution full_name:Library
unknown title:Mass
```

Both are treated as source rules.

### Unknown fields prevent a rule group from matching

The parser accepts any `field:value` token. Field validation happens later
during matching. An unsupported field remains part of the AND group but can
never contribute a successful match, so the complete line does not match.

For example, this is syntactically parsed but cannot match an institution:

```text
institution name:British*
```

The supported field is `full_name`.

### Standalone words are mostly ignored

Standalone tokens are collected while parsing. Only the first recognized
lowercase model token is meaningful. Other standalone words are ignored.

This is why an unquoted multiword value does not behave as intended:

```text
composer:Bach Johann Sebastian
```

Only `composer:Bach` becomes a condition.

### Empty and malformed lines are not reported clearly

Malformed tokens may be skipped, leaving a rule with no conditions. Such a
rule does not match, but the parser generally does not produce a user-facing
error.

### Field names are effectively lowercase

The allowed-field check lowercases field names, but later special-field
comparisons and method lookup use the originally parsed string. Uppercase or
mixed-case field names can therefore pass one check and fail another. Use
lowercase field names consistently.

### Only `exclude:mine` provides negation

There is no general NOT operator, no field inequality, and no way to negate a
wildcard pattern. `exclude:mine` is the only implemented negative condition.

### One line can target only one model

A line has at most one model. Conditions cannot combine fields from different
models.

## Notification cadence

Cadence is stored separately from the matching rules:

- `every`: run matching when a record is saved and send immediately;
- `daily`: inspect records modified during the last day and send a digest;
- `weekly`: inspect records modified during the last seven days and send a
  digest;
- no cadence: notifications are disabled.

The immediate and digest jobs use the same `NotificationMatcher`, so the rule
grammar and quirks apply to every cadence.

## Recommended safe syntax

For rules written by hand, use:

```text
[lowercase_model] lowercase_field:"value with spaces" another_field:value*
```

Recommended practices:

- use one model per line;
- use separate lines for OR;
- use the same line for AND;
- quote every value containing spaces;
- do not put colons inside values;
- use lowercase model and field names;
- use exact values for `follow`, `owner`, and `record_type`;
- treat source `lib_siglum` as a starts-with search;
- use singular underscored model names, including `standard_term` and
  `standard_title`;
- remember that `exclude:mine` currently affects all rules for the same model.
