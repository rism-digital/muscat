module Triggers
  def execute_triggers_from_params(params, object)
    if params[:triggers]
      triggers = JSON.parse(params[:triggers])
      
      triggers.each do |k, relations|
        if k == "save"
          relations.each {|model| Delayed::Job.enqueue(SaveItemsJob.new(object, model)) }
        elsif k == "reindex"
          relations.each {|model| Delayed::Job.enqueue(ReindexItemsJob.new(object, model)) }
        else
          puts "Unknown trigger #{k}"
        end
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
    
    if !conf.get_triggers.is_a?(Array)
      puts "Invalid trigger configuration for #{@item.class}"
    end
    
    conf.get_triggers.each do |trigger|
      if trigger == "notify_changes"
        Delayed::Job.enqueue(TriggerNotifyJob.new(object))
      end
    end
    
  end
  
  def triggers_from_hash(triggers)
    [triggers].to_json.html_safe
  end
  
end