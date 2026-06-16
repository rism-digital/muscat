class AddCompositeIndexToSourcesToInstitutions < ActiveRecord::Migration[7.2]
  def change
    add_index :sources_to_institutions,
              [:source_id, :marc_tag, :institution_id],
              name: "index_sti_on_source_marc_institution"
  end
end
