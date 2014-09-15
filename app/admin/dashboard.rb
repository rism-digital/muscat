ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do

    columns do
      column do
        panel "Recently modified Sources" do
          table_for Source.find_recent_updated(5).map do
            column("ID") {|source| link_to(source.id, source_path(source)) }
            column("Composer") {|source| source.composer }
            column("Title") {|source| source.title } 
          end
        end
      end

      column do
        panel "Recently created Sources" do
          table_for Source.find_recent_created(5).map do
            column("ID") {|source| link_to(source.id, source_path(source)) }
            column("Composer") {|source| source.composer }
            column("Title") {|source| source.title } 
          end
        end
      end
    
    end
    
    columns do
      column do
        panel "Recently modified People" do
          table_for Person.find_recent_updated(5).map do
            column("ID") {|person| link_to(person.id, person_path(person)) }
            column("Name") {|person| person.full_name }
            column("Src Count") {|person| person.src_count }
          end
        end
      end
    end

  end # content
end
