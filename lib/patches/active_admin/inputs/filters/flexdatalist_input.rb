# frozen_string_literal: true
module ActiveAdmin
    module Inputs
      module Filters
        class FlexdatalistInput
          include Base

          def input_name
            if column_for(method)
              return method.to_s + "_eq"
            end
            return method
          end

          def to_html
            @name = input_html_options[:id].gsub(/_id$/, "")

            input_wrapping do
              label_html <<
              builder.text_field(input_name, input_html_options)
            end
          end
  
          def value_property
            column_for(method) ? "shortid" : "id"
          end

          def input_html_options
            if options[:data_path].is_a?(Proc)
              data_path = template.instance_exec(&options[:data_path])
            else
              data_path = options[:data_path]
            end

            super.merge(:class => "flexdatalist", 
              :placeholder => options.include?(:placeholder) ? options[:placeholder] : "Name", 
              :"data-data" => data_path,
              :"data-search-in" => 'name',
              :"data-value-property" => value_property,
              :"data-selection-required" => "true",
              :"data-search-by-word" => "true",
              :"data-min-length" => "0"
            )
          end
        
        end
      end
    end
  end
  