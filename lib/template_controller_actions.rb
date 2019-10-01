# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

module TemplateControllerActions
  
  def self.included(dsl)
    dsl.batch_action :change_template, if: proc{ current_user.has_any_role?(:editor, :admin) }, form: {
      target_template: MarcSource::RECORD_TYPES.to_a.select{|k,v| k if v!=0}.map{|k,v| ["#{I18n.t('record_types.' + k.to_s)}",v]}.sort,
    } do |ids, inputs|
        sources = Source.where(id: ids)
        target_template = inputs[:target_template].to_i
        sources.each do |source|
          source.change_template_to(target_template)
        end

        redirect_to collection_path#, :notice => I18n.t(:success, scope: :folders, name: inputs[:name], count: results.count)
    end
     
  end
  
  
end
