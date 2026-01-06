ActiveAdmin.register PullRequest do
  
  show do

    tags, wf_stages = VersionChecker.diff_items(resource.item, resource)
    resource.marc.load_from_array(tags)
    # Sim is always set to 0-100 to indicate the difference
    #sim = 100 - VersionChecker.get_similarity_with_next(version.id)
    
    panel I18n.t("compare_versions.modified_records") do
      div class: "diff" do
        render(partial: "admin/compare_versions/diff_record", locals: { :item => resource })
      end
    end
    active_admin_comments
  end


  index do
    selectable_column

    column :id
    column :item_type
    column :item
    column :message
    column :created_at

    actions
  end

end