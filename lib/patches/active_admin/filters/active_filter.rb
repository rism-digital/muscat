# Monkey patch to execute Procs 
# In the sidebar status
module ActiveAdmin
  module Filters

    class ActiveFilter

      def make_muscat_filter(part, value)
        if part == "record_type"
          code = I18n.t("record_types_codes." + value,  locale: :en)
          "#{code} (#{value})"          
        elsif part == "folder_id"
          begin
            f = Folder.find(value)
            "#{f.name} (#{value})"
          rescue ActiveRecord::RecordNotFound
            "Folder not found #{value}"
          end
        else
          "#{part}:#{value}"
        end
      end

      # Patch the values so we can show the template type
      def values
        condition_values = condition.values.map(&:value)
        if related_class
          related_class.where(related_primary_key => condition_values)
        else
          # "Clever" Rod-style patch
          condition_values.collect do |cv|

            if cv.include?(":")
              part, value = cv.split(":")
              make_muscat_filter(part, value)
            else
              cv
            end

          end
        end
      end

      def filter_label
        return unless filter

        if filter[:label].is_a? Proc
          filter[:label].call
        else
          filter[:label] || I18n.t(name, scope: ["formtastic", "labels"], default: nil)
        end
      end
    end
  end
		
end
