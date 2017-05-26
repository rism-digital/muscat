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
  
  def triggers_from_hash(triggers)
    [triggers].to_json.html_safe
  end
  
end