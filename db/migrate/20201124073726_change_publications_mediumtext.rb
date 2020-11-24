class ChangePublicationsMediumtext < ActiveRecord::Migration[5.2]
  def change
    change_column(:publications, :marc_source, :mediumtext)
  end
end
