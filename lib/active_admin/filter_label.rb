# Monkey patch to execute Procs 
# In the sidebar status
module ActiveAdmin
  module Filters

    class ActiveFilter
      def filter_label
        return unless filter

        if filter[:label].is_a? Proc
          filter[:label].call
        else
          filter[:label]
        end
      end
    end
  end
		
end
