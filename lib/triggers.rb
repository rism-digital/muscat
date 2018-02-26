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
  
  def trigger_validation(hash={})
    item = hash[:item]
    user = hash[:user]
    return unless user || item
    level = hash[:level] == :warning ? :validation_warning : :validation_error
    if level == :validation_error
      message = item.errors.messages[:base].join(";")
    else
      message = item.warnings.full_messages.join("<br/>")
    end
    url = request.env['HTTP_REFERER']
    par = Rack::Utils.parse_query(URI(url).query)
    filename = "#{Rails.root}/tmp/#{user}"
    File.write("#{filename}", item.to_yaml)
    par[level] = "#{message}"
    new_url_with_params = "#{request.base_url}#{URI(url).path}?#{par.to_query}"
    respond_to do |format|
      format.json {  render :json => {:redirect => new_url_with_params}}
    end
  end


end
