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
    params_hash = {}
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
    sep = par.any? ? "&" : "?"
    filename = "#{Rails.root}/tmp/#{user}"
    File.open(filename, 'w') {|f| f.write(item.marc.to_s) }
    par[level] = "#{message}"
    par.each do |k,v|
      params_hash[k] = v.is_a?(Array) ? v.first : v
    end
    url_with_params = "#{url}#{sep}#{params_hash.to_query}"
    unless par["validation_warning"]
      respond_to do |format|
        format.json {  render :json => {:redirect => url_with_params}}
      end
    end
  end


end
