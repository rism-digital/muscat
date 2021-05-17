
    class MuscatMaintenanceJob < ApplicationJob
    queue_as :default

    def initialize
        super
    end

    def perform(*args)
        saved_source_ids = []
        models = {}
        unsavable_sources = []
        begin_time = Time.now

        # Run the checkup function
        checkup = MuscatCheckup.new({jobs: 10, skip_validation: true, skip_dates: true, skip_unknown_tags: true})
        total_errors, total_validations, foreign_tag_errors, unknown_tags = checkup.run_parallel

        # Force a reconnect
        ActiveRecord::Base.connection.reconnect!

        foreign_tag_errors.each do |error|
            model_id = error.partition("from: #").last.split(":") #yeeeeeeeah

            model = model_id.first
            id = model_id.last

            if !models.keys.include?(model)
                models[model] = []
            end

            models[model] << id

            object = model.constantize.send("find", id)
            object.referring_sources.each do |s|
                begin
                    # Do not make a paper trail snapshot
                    PaperTrail.request(enabled: false) do
                        s.save
                    end
                    saved_source_ids << s.id
                rescue
                    unsavable_sources << s.id
                end
            end
        end

        end_time = Time.now
        message = "Source report started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
        
        MuscatMaintenanceReport.notify(message, saved_source_ids, models, unsavable_sources).deliver_now
    end

    end
