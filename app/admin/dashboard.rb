ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }, url: ->{ dashboard_path(locale: I18n.locale) }
  
  limit = 10;

  content title: proc{ I18n.t("active_admin.dashboard") } do
    
    if Source.find_recent_updated(limit).size > 0
      columns do
        column do
          panel I18n.t(:recent_sources) do
            table_for Source.find_recent_updated(limit).map do
              column(I18n.t :filter_id) {|source| link_to(source.id, source_path(source)) }
              column(I18n.t :filter_wf_stage) {|source| status_tag(source.wf_stage) } 
              column(I18n.t :filter_composer) {|source| source.composer }
              column(I18n.t :filter_title) {|source| source.title } 
            end
          end
        end
      end
    end

    if Catalogue.find_recent_updated(limit).size > 0
      columns do
        column do
          panel I18n.t(:recent_catalogues) do
            table_for Catalogue.find_recent_updated(limit).map do
              column(I18n.t :filter_id) {|catalogue| link_to(catalogue.id, catalogue_path(catalogue)) }
              column(I18n.t :filter_wf_stage) {|catalogue| status_tag(catalogue.wf_stage) } 
              column (I18n.t :filter_name) {|catalogue| catalogue.name }
              column (I18n.t :filter_author) {|catalogue| catalogue.author }
              column (I18n.t :filter_sources) {|person| person.src_count }
            end
          end
        end
      end
    end
    
    if Person.find_recent_updated(limit).size > 0
      columns do
        column do
          panel I18n.t(:recent_people) do
            table_for Person.find_recent_updated(limit).map do
              column(I18n.t :filter_id) {|person| link_to(person.id, person_path(person)) }
              column(I18n.t :filter_wf_stage) {|person| status_tag(person.wf_stage) } 
              column (I18n.t :filter_full_name) {|person| person.full_name }
              column (I18n.t :filter_sources) {|person| person.src_count }
            end
          end
        end
      end
    end

  end # content
end
