module ActiveAdmin

  class ResourceDSL
    def collection_action(name, options = {}, &block)
      action config.collection_actions, name, options, &block
    end
  end

end