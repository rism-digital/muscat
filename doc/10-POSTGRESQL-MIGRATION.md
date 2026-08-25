# PostgreSQL migration

This is the controlled MariaDB-to-PostgreSQL migration procedure for Muscat.
It is designed for a staging rehearsal first and a final planned outage. The
importer does not use Rails, does not delete databases or tables, and refuses
to load a non-empty target table.

## Prerequisites

Install the `pg` and `mysql2` gems with the application's supported Ruby and
Bundler. Create an empty PostgreSQL database and a migration role with `CREATE`
and DML rights. Give the MariaDB migration role `SELECT` only.

Set credentials outside the repository. [`config/postgresql_migration.yml.example`](../config/postgresql_migration.yml.example)
lists the required variables. The essential values are:

```sh
export MUSCAT_MYSQL_DATABASE=muscat_prod_db
export MUSCAT_MYSQL_USER=muscat_reader
export MUSCAT_MYSQL_SOCKET=/tmp/mysql.sock
export MUSCAT_POSTGRES_URL='postgresql://muscat_migrator:password@127.0.0.1:5432/muscat_staging'
```

Do not point `MUSCAT_POSTGRES_URL` at an existing Muscat database. The schema
command requires an empty `public` schema.

## Rehearsal

Run these commands in separate steps, retaining both command output and the
JSON report as cutover evidence:

```sh
ruby script/migrate_mysql_to_postgres preflight
ruby script/migrate_mysql_to_postgres schema
ruby script/migrate_mysql_to_postgres import
MUSCAT_MIGRATION_REPORT=tmp/postgresql-migration-report.json \
  ruby script/migrate_mysql_to_postgres validate
```

`preflight` rejects unsupported source types and invalid JSON in the columns
that will become `jsonb`. `schema` maps MariaDB data types and indexes to a
PostgreSQL schema. `import` reads every table in primary-key batches and writes
each batch using PostgreSQL text `COPY`; existing IDs are retained. It resets
identity sequences only after all tables have loaded. `validate` compares table
counts, single-column primary-key ranges, and per-column NULL counts between the
two databases.

Use `--dry-run schema` to review generated DDL without changing PostgreSQL.
`--dry-run import` reads source batches but does not write target rows.

## Cutover

1. Complete and accept a full staging rehearsal, including application smoke
   tests with `MUSCAT_DB_ADAPTER=postgresql`.
2. Take and verify a final MariaDB backup. Stop web processes, delayed-job
   workers, cron jobs, and Solr indexing so MariaDB is write-quiescent.
3. Repeat the four rehearsal commands against a new, empty production target.
   Do not run the combined `all` command during production cutover; explicit
   stages make failures and timings visible.
4. Reindex Solr, run authentication/editor/autocomplete/comment and background
   job smoke tests, then set `MUSCAT_DB_ADAPTER=postgresql` and PostgreSQL
   connection variables for the application processes.
5. Keep MariaDB read-only and the verified backup intact until acceptance is
   complete. Rollback is a configuration switch back to MariaDB.

## PostgreSQL-specific application changes

The importer changes `people.identifiers` and the two structured
`active_admin_comments` fields to `jsonb`; all other long text stays `text`.
The application query changes use PostgreSQL JSON and regular-expression
operators. PostgreSQL's `\m`/`\M` word boundaries replace MySQL's `\b`.

The original historical Rails migrations are not used to construct a new
PostgreSQL database: many contain MySQL-only `ALTER TABLE`, `AUTO_INCREMENT`,
and charset/collation statements. The importer derives the target schema from
the current source database instead.
