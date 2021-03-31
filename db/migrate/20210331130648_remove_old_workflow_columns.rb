class RemoveOldWorkflowColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :digital_objects, :wf_notes, :string
    remove_column :holdings, :wf_notes, :string
    remove_column :institutions, :wf_notes, :string
    remove_column :liturgical_feasts, :wf_notes, :string
    remove_column :people, :wf_notes, :string
    remove_column :places, :wf_notes, :string
    remove_column :publications, :wf_notes, :string
    remove_column :sources, :wf_notes, :string
    remove_column :standard_terms, :wf_notes, :string
    remove_column :standard_titles, :wf_notes, :string
    remove_column :work_incipits, :wf_notes, :string
    remove_column :works, :wf_notes, :string

    remove_column :digital_objects, :wf_version, :integer
    remove_column :holdings, :wf_version, :integer
    remove_column :institutions, :wf_version, :integer
    remove_column :liturgical_feasts, :wf_version, :integer
    remove_column :people, :wf_version, :integer
    remove_column :places, :wf_version, :integer
    remove_column :publications, :wf_version, :integer
    remove_column :sources, :wf_version, :integer
    remove_column :standard_terms, :wf_version, :integer
    remove_column :standard_titles, :wf_version, :integer
    remove_column :work_incipits, :wf_version, :integer
    remove_column :works, :wf_version, :integer

  end
end
