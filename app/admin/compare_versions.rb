ActiveAdmin.register_page "Compare Versions" do
  controller do
    def index
      params[:compare_version_quantity] = params.include?(:compare_version_quantity) ? params[:compare_version_quantity] : 20
    end
  end
  menu :parent => "admin_menu", :label => proc { I18n.t("active_admin.compare_versions") }

  limit = 20

  content title: proc { I18n.t("active_admin.compare_versions") } do

    matches, model = diff_find_in_interval(Source, current_user, params[:time_frame], params[:rule])

    if matches.empty?
      h3 {text_node I18n.t("compare_versions.no_records")}
      next
    end

    # Note: we only display one match at a time, as it is always
    # limited to one rule. So the first one is the only result
    match_name, sources = matches.first
    paginated = Kaminari.paginate_array(sources)
    per_page = params.include?(:compare_version_quantity) ? params[:compare_version_quantity] : 20

    paginated_collection(paginated.page(params[:src_list_page]).per(per_page), param_name: "src_list_page", download_links: false) do
      items = collection

      panel I18n.t("compare_versions.modified_records") do
        # class: "index_table index"
        table do

          tr do
            th { text_node I18n.t(:filter_id) }
            if model == Source
              th { text_node I18n.t(:filter_composer) }
              th { text_node I18n.t(:filter_title) }
            elsif model == Institution
              th { text_node I18n.t(:filter_name) }
              th { text_node I18n.t(:filter_siglum) }
            elsif model == Work
              th { text_node I18n.t(:filter_composer) }
              th { text_node I18n.t(:filter_title) }
            end
            th { text_node I18n.t(:created_at) }
            th { text_node I18n.t(:updated_at) }
            th { text_node I18n.t("compare_versions.similarity")}
            th { text_node I18n.t("compare_versions.diff") }
          end

          items.each do |s|
            sim = 0

            if !s.versions.empty?
              version = s.versions.last
              s.marc.load_from_array(VersionChecker.get_diff_with_next(version.id))
              sim = VersionChecker.get_similarity_with_next(version.id)
            end

            classes = [helpers.cycle("odd", "even")]
            tr(class: classes.flatten.join(" ")) do
              
              if model == Source
                td { link_to(s.id, admin_source_path(s)) }
                td { s.composer rescue "" }
                td { s.std_title rescue "" }
              elsif model == Institution
                td { link_to(s.id, admin_institution_path(s)) }
                td { s.name rescue "" }
                td { s.siglum rescue "" }
              elsif model == Work
                td { link_to(s.id, admin_work_path(s)) }
                td { s.person.name rescue "" }
                td { s.title rescue "" }
              end
              td { s.created_at }
              td { s.updated_at }

              td do
                div(id: "marc_editor_history", style: "text-align: center") do
                  if sim == 0
                    status_tag(:published, label: I18n.t("compare_versions.new_record"))
                  else
                    div(class: "modification_bar") do
                      div(class: "modification_bar_content version_modification", style: "width: #{sim}%") do
                        "&nbsp".html_safe
                      end
                    end
                  end
                end
              end

              td do
                id = s.versions.last != nil ? s.versions.last.id.to_s : "1"
                link_to(I18n.t("compare_versions.show"), "#", class: "diff-button", name: "diff-#{s.id}")
              end
            end
            tr do
              td(colspan: 7, class: "diff", id: "diff-#{s.id}", style: "display: none") do
                render(partial: "diff_record", locals: { :item => s })
              end
            end
          end
        end
      end
    end

  end # content

  sidebar I18n.t "compare_versions.options", :class => "sidebar_tabs", :only => [:index] do
    # no idea why the I18n.locale is not set by set_locale in the ApplicationController
    I18n.locale = session[:locale]
    render("compare_sidebar") # Calls a partial
  end
end
