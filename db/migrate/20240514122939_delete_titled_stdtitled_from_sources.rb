class DeleteTitledStdtitledFromSources < ActiveRecord::Migration[7.0]
  def change
    remove_column :sources, :title_d
    remove_column :sources, :std_title_d
  end
end
