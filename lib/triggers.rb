module Triggers
  def execute_triggers_from_params(params, object)
    return if params[:triggers].blank?

    begin
      triggers = JSON.parse(params[:triggers])
    rescue JSON::ParserError, TypeError
      return
    end
    return unless triggers.is_a?(Hash)

    configured = EditorConfiguration.get_default_layout(object)&.relation_triggers || {}
    triggers.each do |action, relations|
      job_class = { "save" => SaveItemsJob, "reindex" => ReindexItemsJob }[action]
      next unless job_class && relations.is_a?(Array)

      (relations & configured.fetch(action, [])).each do |relation|
        next unless object.class.reflect_on_association(relation)&.collection?

        Delayed::Job.enqueue(job_class.new(object.id, object.class, relation))
      end
    end
  end
  
  def execute_global_triggers(object)
    conf = EditorConfiguration.get_default_layout(object)
    if !conf
      puts "Could not read editor configurations for #{@item.class} for triggers"
      return
    end
    
    return if !conf.get_triggers
    
    if object.respond_to?(:last_updated_at)
      # Skip object if modified in the grace period, except new objs
      return if object.updated_at - object.last_updated_at < RISM::VERSION_TIMEOUT && object.updated_at != object.created_at
    end
    
    if !conf.get_triggers.is_a?(Array)
      puts "Invalid trigger configuration for #{@item.class}"
    end
    
    conf.get_triggers.each do |trigger|
      if trigger == "notify_changes"
        Delayed::Job.enqueue(TriggerNotifyJob.new(object))
      elsif trigger == "reindex_source"
        # This is for the Holding Records, every time one is saved reindex the source
        # so the eventual changes are pulled there too
        Delayed::Job.enqueue(ReindexForeignRelationsJob.new(object, [{class: Source, id: object.source_id}]))
      end
    end
    
  end
  
  def triggers_from_hash(triggers)
    [triggers].to_json.html_safe
  end
  
end
