Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 1.day
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

Delayed::Backend::ActiveRecord.configure do |config|
    config.reserve_sql_strategy = :default_sql # Use the conservative locking
end