# We need to customize the comments for two things:
# 1) use a different parameter for pagination
# 2) append a "comments_help" text after the input box
# Nr. 1 is the most tricky, as the inirialization function and the build comments function
# need to be overridden, so we can substitute the hard-coded :page parameter with a :comments_page parameter
# This is important as :page is persistent in the show page for the top navigation!
module ActiveAdmin
  module Comments
    module Views

      class Comments
        # Make a copy of the old build_comment_form" function
        alias_method :"old_build_comment_form", :"build_comment_form"
        
        def build(resource)
          @resource = resource
          ## This line originally uses :page, which conflicts with the saved :page paameter
          @comments = ActiveAdmin::Comment.find_for_resource_in_namespace(resource, active_admin_namespace.name).includes(:author).page(params[:comments_page])
          super(title, for: resource)
          build_comments
        end

        def build_comments
          if @comments.any?
            @comments.each(&method(:build_comment))
            div page_entries_info(@comments).html_safe, class: 'pagination_information'
          else
            build_empty_message
          end
          
          ## We need to tell kaminari to create pagination using the
          # :comments_page parameter instead of page
          text_node paginate @comments, param_name: :comments_page
          build_comment_form
        end
        
        # Override the function. We call the old one so the default stuff
        # gets generated, and then we append our small string of text
        def build_comment_form
          old_build_comment_form
          span I18n.t('active_admin.comments.comments_help'), class: 'empty'
        end
        
      end
      
    end
  end
end