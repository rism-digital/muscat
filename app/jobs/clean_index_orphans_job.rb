
class CleanIndexOrphansJob < ApplicationJob
    queue_as :default

    def initialize
        super
    end

    def perform(*args)
        Rails.application.eager_load!
        ApplicationRecord.descendants.collect(&:name).each do |model_name|
            klass = model_name.constantize
            next if !klass.respond_to?(:solr_clean_index_orphans)
            
            begin_time = Time.now
            klass.solr_clean_index_orphans(batch_size: 50000)
            Sunspot.commit
            end_time = Time.now

            puts "Purged orphans for: #{model_name} (#{end_time - begin_time} seconds run time)"
        end
        
    end

end
