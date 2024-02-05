
    class MuscatMaintenanceJob < ApplicationJob
    queue_as :default

    def initialize(mdl = Source, silent = "")
        @base_model = mdl != nil && mdl.is_a?(Class) ? mdl : Source
        @silent = silent == :silent ? true : false
        super
    end

    def perform(*args)
        saved_source_count = 0
        models = {}
        unsavable_sources = []
        begin_time = Time.now

        # Run the checkup function
        checkup = MuscatCheckup.new({model: @base_model, jobs: 10, skip_validation: true, skip_dates: true, skip_unknown_tags: true, skip_dead_774: true})
        total_errors, total_validations, foreign_tag_errors, unknown_tags = checkup.run_parallel

        # Force a reconnect
        ActiveRecord::Base.connection.reconnect!

        foreign_tag_errors.each do |error|
            # Model is the linked to item
            # i.e. a StdTitle in a source,
            # and Model = standard_title
            model_id = error.partition("from: #").last.split(":") #yeeeeeeeah

            model = model_id.first
            id = model_id.last

            if !models.keys.include?(model)
                models[model] = {}
            end

            if !models[model].keys.include?(error)
                models[model][error] = []
            end

            # Fint the actual instance of the item
            object = model.constantize.send("find", id)
            # Get back all the referring @base_models for this item
            # in the case above it would be referring_sources
            referring_models = object.send("referring_#{@base_model.to_s.pluralize.underscore.downcase}")
            # Since the marc tags can be duplicated, this may contain dups
            # remove them
            single_referring_ids = referring_models.each.map {|p| p.id}.sort.uniq
            single_referring_ids.each do |sid|
                
                # Probably not the most efficent way
                s = @base_model.find(sid)

                puts "Save referring #{@base_model.to_s} #{s.id} from #{model} #{id}"
                begin
                    # Do not make a paper trail snapshot
                    PaperTrail.request(enabled: false) do
                        s.save
                    end
                    models[model][error] << s.id
                    saved_source_count += 1
                rescue
                    unsavable_sources << s.id
                end
                s = nil
            end
        end

        end_time = Time.now
        message = "#{@base_model.to_s} report started at #{begin_time.to_s}, (#{end_time - begin_time} seconds run time)"
        
        MuscatMaintenanceReport.notify(message, @base_model, saved_source_count, models, unsavable_sources).deliver_now if !silent
    end

end
