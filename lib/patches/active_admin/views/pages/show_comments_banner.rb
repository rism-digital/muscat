module ActiveAdmin
  module Views
    module Pages
      module ShowCommentsBanner
        def main_content
          helpers.active_admin_muscat_comments_banner(self, resource)
          super
        end
      end
    end
  end
end

ActiveAdmin::Views::Pages::Show.prepend(ActiveAdmin::Views::Pages::ShowCommentsBanner)
