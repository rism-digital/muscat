# cronotab.rb — Crono configuration file
#
# Here you can specify periodic jobs and schedule.
# You can use ActiveJob's jobs from `app/jobs/`
# You can use any class. The only requirement is that
# class should have a method `perform` without arguments.
#
# class TestJob
#   def perform
#     puts 'Test!'
#   end
# end
#
# Crono.perform(TestJob).every 2.days, at: '15:30'
#

Crono.perform(PurgeSearchesJob).every 1.day, at: {hour: 1, min: 00}
Crono.perform(PurgeFolderItemsJob).every 1.day, at: {hour: 3, min: 0}
Crono.perform(LogModelErrorsJob).every 1.week, on: :sunday, at: "07:00"