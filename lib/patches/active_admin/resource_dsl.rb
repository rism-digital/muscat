module ActiveAdmin

  class ResourceDSL < DSL
    
    def rod_collection_action(name, options = {}, &block)
      action config.collection_actions, name, options, &block
    end
    
    def member_action(name, options = {}, &block)
      action config.member_actions, name, options, &block
    end
  end

end