# Validation observability

Telemetry is disabled by default. Existing scheduled checkups continue to
produce only their validation logs and HTML/email reports. Enable streaming
Loki events and the final Prometheus snapshot explicitly with:

```text
bin/muscat_execute_job MuscatCheckupReportJob production --telemetry
bin/muscat_execute_job MuscatCheckupReportJob production Holding --telemetry
```

When enabled, the scheduled job streams record-level Loki events while it
validates a model, then writes the Prometheus snapshot after completion. Folder
and interactive editor validation are not included.

## Configuration

When using `--telemetry`, set both paths in the environment of the cron/job
process:

```text
MUSCAT_VALIDATION_PROMETHEUS_TEXTFILE=/var/lib/node_exporter/textfile_collector/muscat_validation.prom
MUSCAT_VALIDATION_LOKI_LOG=/var/log/muscat/validation_observability.jsonl
```

If unset, the paths default to `log/validation_metrics.prom` and
`log/validation_observability.jsonl` below the Rails root. The destination
directories must already exist and be writable by the Muscat job user. A write
failure raises from the scheduled job so Delayed Job retries and reports it as
a failure.

The configured Prometheus path is a base name. Muscat appends the checked model
name before `.prom`, for example `muscat_validation_source.prom` and
`muscat_validation_work.prom`. Each file is written to a temporary file in its
final directory and renamed into place, so one model's weekly run cannot remove
another model's latest snapshot. Configure Alloy's local Unix exporter textfile
collector to read that directory, then retain the normal Alloy scrape and
remote-write path. `config/muscat-validation.alloy.example` is a parameterized
collector template; merge it into the site's existing Alloy configuration.

Configure Alloy `loki.source.file` to tail the JSONL path. The example uses a
static `job="muscat_validation"` label; host labels should continue to be
added by the site's normal Alloy pipeline.

## Prometheus metrics

Every metric has a `model` label (`Source`, `Holding`, `Work`, or `Person` for
the default cron schedule):

| Metric | Meaning |
| --- | --- |
| `muscat_validation_last_run_completed_timestamp_seconds` | Completion time of the latest exported run. |
| `muscat_validation_last_run_successful_timestamp_seconds` | Completion time of the latest successfully exported run. |
| `muscat_validation_last_run_duration_seconds` | Elapsed validation time. |
| `muscat_validation_last_run_records_scanned` | Records checked. |
| `muscat_validation_last_run_records_with_findings` | Records with at least one finding. |
| `muscat_validation_last_run_findings` | Findings, additionally labelled with `record_type` and stable `category`. |

`category` is the validator's existing log/error type, for example
`validation_error`, `link_error`, `unknown_tag_error`, `date_error`,
`holding_error`, or a `record_exception_*` processing error. Metrics never use
record IDs, MARC tags/subtags, or messages as labels, avoiding high cardinality.

## Loki JSON events

Each line is JSON with an ISO-8601 `timestamp`, UUID `run_id`, `workflow`, and
`model`. A run produces `validation_run_started`, then one
`validation_message` event as each record produces validation or processing
findings, and
finally `validation_run_completed` (or `validation_run_failed`). The record event contains `record_id`,
`record_type`, and a `findings` array. Each finding retains `category`, `tag`,
`subtag`, and raw `message` for diagnosis.

Record IDs and messages are fields rather than Loki stream labels. Query them
after JSON parsing, for example by `run_id`, `record_id`, `category`, or MARC
tag. Rotate the JSONL file with the additional stanza in
`config/muscat.logrotate.sample`; `copytruncate` keeps an open tailing reader
on the same file. Parallel workers take a short exclusive lock for each JSON
line and flush it immediately, so Alloy can tail failures during a long run.
The stream does not `fsync` each event; an abrupt host crash can lose entries
that have not reached disk yet.
