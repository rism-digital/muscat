class AddRichFieldsToActiveAdminComments < ActiveRecord::Migration[7.2]
  def change
    add_column :active_admin_comments, :body_json, :json
    add_column :active_admin_comments, :mentioned_user_ids, :json
  end
end
