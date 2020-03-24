# frozen_string_literal: true
module Blacklight
    class Configuration
      # This mixin provides Blacklight::Configuration with generic
      # solr fields configuration
      module Fields
        extend ActiveSupport::Concern
  
        alias_method :"old_add_blacklight_field", :"add_blacklight_field"
  
        
        def add_blacklight_field config_key, *args, &block
            
            if args.count > 1
                if args[1].is_a? Hash
                    if args[1].include?(:override) && args[1][:override] == true
                        self[config_key.pluralize].delete(args[0])
                    end
                end
            end

            old_add_blacklight_field config_key, *args, &block
            return;
            
          self[config_key.pluralize][ field_config.key ] = field_config
        end
  
      end
    end
  end
  