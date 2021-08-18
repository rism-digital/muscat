ActiveAdmin.register_page "Compare Versions" do
  controller do
  end

  menu priority: 3, label: proc { I18n.t("active_admin.compare_versions") }
  #menu false

  limit = 10

  content title: proc { I18n.t("active_admin.compare_versions") } do

    #user = current_user.has_any_role?(:editor, :admin) ? -1 : current_user.id
    user_id = (params[:dashboard_source_owner].to_s == "user") ? current_user.id : -1
    matches = diff_find_in_interval(Source, current_user)

    matches.each do |match_name, sources|

      paginated = Kaminari.paginate_array(sources)

      paginated_collection(paginated.page(params[:src_list_page]).per(20), param_name: "src_list_page", download_links: false) do
        items = collection

        panel "#{Source.model_name.human(count: 2)} #{match_name}" do

          table do

            tr do
              th { text_node "id" }
              th { text_node "composer" }
              th { text_node "title" }
              th { text_node "created at" }
              th { text_node "updated at" }
              th { text_node "similarity" }
              th { text_node "diff" }
            end

            items.each do |s|
              sim = 0

              if !s.versions.empty?
                version = s.versions.last
                #item = version.reify #item_type.singularize.classify.constantize.new
                s.marc.load_from_array(VersionChecker.get_diff_with_next(version.id))
                sim = VersionChecker.get_similarity_with_next(version.id)
              end

              classes = [helpers.cycle("odd", "even")]
              tr(class: classes.flatten.join(" ")) do
                td { s.id }
                td { s.composer rescue "" }
                td { s.std_title rescue "" }
                td { s.created_at }
                td { s.updated_at }

                td do
                  div(id: "marc_editor_history", class: "modification_bar") do
                    if sim == 0
                      status_tag(:published, label: "New record")
                    else                    
                      div(class: "modification_bar_content version_modification", style: "width: #{sim}%") do
                        "&nbsp".html_safe
                      end
                    end
                  end
                end

                td do
                  id = s.versions.last != nil ? s.versions.last.id.to_s : "1"
                  link_to("show", "#", class: "diff-button", name: "diff-#{s.id}")
                end
              end
              tr do
                td(colspan: 6, class: "diff", id: "diff-#{s.id}", style: "display: none") do
                  render(partial: "diff_record", locals: { :item => s })
                end
              end
            end
          end
        end
      end
    end
  end # content

  sidebar I18n.t "dashboard.selection", :class => "sidebar_tabs", :only => [:index] do
    # no idea why the I18n.locale is not set by set_locale in the ApplicationController
    I18n.locale = session[:locale]
    render("compare_sidebar") # Calls a partial
  end
end
