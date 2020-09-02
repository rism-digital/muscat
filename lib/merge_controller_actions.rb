# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module MergeControllerActions
  
  def self.included(dsl)
    dsl.collection_action :merge, :method => :get do
      model = self.resource_class
      duplicate = model.find(params["duplicate"])
      target = model.find(params["target"])

      associations = model.reflect_on_all_associations.map{|e| e.name}.select{|e| e.to_s =~ /source|holding/}
      duplicate.migrate_to_id(target.id)

      associations.each do |association|
        Delayed::Job.enqueue(ReindexItemsJob.new(target.id, target.class, association.to_s))
        Delayed::Job.enqueue(ReindexItemsJob.new(duplicate.id, duplicate.class, association.to_s))
      end

      target_size = (associations.map{|method| target.send(method).size}).inject(0){|sum,x| sum + x }
      duplicate.reload
      duplicate_size = (associations.map{|method| duplicate.send(method).size}).inject(0){|sum,x| sum + x }
      render json: { target_size: target_size, duplicate_size: duplicate_size, message: "Successfully merged #{model} #{params['duplicate']} into #{params['target']}!"  }

    end
  end
  
  
end
