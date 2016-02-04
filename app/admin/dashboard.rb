ActiveAdmin.register_page "Dashboard" do

  #menu priority: 3, label: proc{ I18n.t("active_admin.dashboard") }
  menu false
  
  limit = 10;

  content title: proc{ I18n.t("active_admin.dashboard") } do
    
    user = current_user.has_any_role?(:editor, :admin) ? -1 : current_user.id
    
    if Source.find_recent_updated(limit, user).size > 0
      columns do
        column do
          panel "#{Source.model_name.human(count: 2)}  -  #{I18n.t(:recent_changes)}" do
            table_for Source.find_recent_updated(limit, user).map do
              column(I18n.t :filter_id) {|source| link_to(source.id, admin_source_path(source)) }
              column(I18n.t :filter_wf_stage) {|source| status_tag(source.wf_stage) } 
              column(I18n.t :filter_composer) {|source| source.composer }
              column(I18n.t :filter_title) {|source| source.title } 
            end
          end
        end
      end
    end

    if Catalogue.find_recent_updated(limit, user).size > 0
      columns do
        column do
          panel "#{Catalogue.model_name.human(count: 2)}  -  #{I18n.t(:recent_changes)}" do
            table_for Catalogue.find_recent_updated(limit, user).map do
              column(I18n.t :filter_id) {|catalogue| link_to(catalogue.id, admin_catalogue_path(catalogue)) }
              column(I18n.t :filter_wf_stage) {|catalogue| status_tag(catalogue.wf_stage) } 
              column (I18n.t :filter_name) {|catalogue| catalogue.name }
              column (I18n.t :filter_author) {|catalogue| catalogue.author }
              column (I18n.t :filter_sources) {|person| person.src_count }
            end
          end
        end
      end
    end
    
    if Person.find_recent_updated(limit, user).size > 0
      columns do
        column do
          panel "#{Person.model_name.human(count: 2)}   -  #{I18n.t(:recent_changes)}" do
            table_for Person.find_recent_updated(limit, user).map do
              column(I18n.t :filter_id) {|person| link_to(person.id, admin_person_path(person)) }
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
