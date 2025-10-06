# frozen_string_literal: true
require "active_admin/filters/active"

module ActiveAdmin
  module Views

    class ActiveFiltersSidebarContent < ActiveAdmin::Component
      def build
        active_filters = ActiveAdmin::Filters::Active.new(active_admin_config, assigns[:search])
        active_scopes = assigns[:search].instance_variable_get("@scope_args")

        scope_block(current_scope)
        filters_list(active_filters, active_scopes)
        remove_active_filter_button
      end

      def remove_active_filter_button
        a(I18n.t("active_admin.filters.buttons.clear"), href: "#", class: "clear_filters_btn")
      end
    end

  end
end
