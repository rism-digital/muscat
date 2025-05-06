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
        elsif part == "work_catalogue"
          I18n.t("work_catalogue_labels." + value)
        else
          "#{value}"
          # [#{part}] we used to print the filter name, do we need it?
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

    end
  end
		
end
