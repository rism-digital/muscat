class DeleteComposerdFromSources < ActiveRecord::Migration[7.0]
  def change
    remove_column :sources, :composer_d
  end
end
