class AddNotificationRulesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :notification_rules, :json
  end
end
