# Solr 10 configuration

`muscat/` is a standalone Solr 10 core directory. Copy it into the Solr home as
the `muscat` core. It keeps the Sunspot field naming contract and Muscat's
analysis, autocomplete, sort, and geospatial schema, with a small `solrconfig.xml`
that uses the standard `/select` and update behavior. No Blacklight handlers or
components are included.

Solr 10 requires Java 21. The schema uses ICU analyzers and ICU collation, so
enable Solr's `analysis-extras` module at the node level (for example with
`SOLR_MODULES=analysis-extras`). The module is not included in Solr's slim
distribution. This replaces the old per-core `<lib>` jar loading.

The schema uses version 1.7, so supported field types use DocValues by default.
Sunspot's `tint`, `tlong`, `tfloat`, `tdouble`, and `tdate` type names remain as
compatibility aliases, backed by Solr's point field implementations. A fresh
index and full reindex are required when switching from the old configuration.
