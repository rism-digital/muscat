
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
            
            # This is the sunspot internal purge
            begin_time = Time.now
            klass.solr_clean_index_orphans(batch_size: 50000)
            Sunspot.commit
            end_time = Time.now

            puts "#{model_name}: solr_clean_index_orphans (#{end_time - begin_time} seconds run time)"

            # This is the slow Muscat one
            remove_orphans_from(klass)
        end
        Sunspot.commit
    end
    
    private

    def find_orphans_from(model, hits)
        to_purge = []
    
        hits.each do |hit|
            begin
                model.find(hit.primary_key)
            rescue ActiveRecord::RecordNotFound
                to_purge << hit.primary_key
            end
        end
    
        return to_purge
    end
    
    def delete_all_from(model, ids)
        ids.each_slice(500) do |slice|
            Sunspot.remove(model) {with(:id, slice)}
        end
    end
    
    def remove_orphans_from(model)
        params = {"order"=>"id_desc"}
        params[:per_page] = 20000

        total_ids = []
        
        begin_time = Time.now
        
        results, hits = model.search_as_ransack(params)
        total_ids += find_orphans_from(model, hits)
        
        # insert the next ones
        for page in 2..results.total_pages
            params[:page] = page
            r, h = model.search_as_ransack(params)
            total_ids += find_orphans_from(model, h)
        end
        
        delete_all_from(model, total_ids)
        Sunspot.commit
        
        end_time = Time.now
        
        puts "#{model}: removed #{total_ids.count} stale SOLR index items (#{end_time - begin_time} seconds run time)"
    end

end
