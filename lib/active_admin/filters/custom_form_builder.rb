# lib/active_admin/filters/custom_form_builder.rb
module ActiveAdmin
  module Filters
    class CustomFormBuilder < ::ActiveAdmin::Filters::FormBuilder
      def input(method, options = {})
        options = options.dup # Allow options to be shared without being tainted by Formtastic
        options[:as] ||= default_input_type(method, options)
 
        klass = input_class(options[:as])
 
        obj = klass.new(self, template, @object, @object_name, method, options)
 
        class << obj
          include ActiveAdmin::Inputs::FilterBase
        end
 
        obj.to_html
      end
 
      def custom_input_class_name(as)
        "#{as.to_s.camelize}Input"
      end
 
      def active_admin_input_class_name(as)
        "ActiveAdmin::Inputs::#{custom_input_class_name(as)}"
      end
    end
  end
end