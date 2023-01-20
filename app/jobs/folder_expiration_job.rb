
class FolderExpirationJob < ApplicationJob

    def initialize()
        super
    end

    def humanize_folder(folder)
        ["#{folder.name} (#{folder.folder_items.count}): #{folder.delete_date}", folder.id]
    end

    def perform()
        
        User.all.each do |user|
            folder_grouping = {
                delete_now: [],
                tomorrow: [],
                one_week: [],
                two_weeks: [],
                one_month: []
            }
                
            delete_items = []

            user.folders.each do |folder|
                #puts "Folder: #{folder.id} expires in #{folder.delete_date.to_date - Date.today}"

                if folder.delete_date.to_date - Date.today <= 0/1
                    #puts "#{user.name} #{folder.id} #{folder.delete_date} delete NOW!"
                    delete_items << folder.id
                    folder_grouping[:delete_now] << humanize_folder(folder)
                elsif folder.delete_date.to_date - Date.today == 1/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete tomorrow!"
                    folder_grouping[:tomorrow] << humanize_folder(folder)
                elsif folder.delete_date.to_date - Date.today == 7/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete in one week"
                    folder_grouping[:one_week] << humanize_folder(folder)
                elsif folder.delete_date.to_date - Date.today == 14/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete in two weeks"
                    folder_grouping[:two_weeks] << humanize_folder(folder)
                elsif folder.delete_date.to_date - Date.today == 30/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete in one month"
                    folder_grouping[:one_month] << humanize_folder(folder)
                end
            end

            if !delete_items.empty?
                puts "Deleting folders #{delete_items.to_s}"
                Folder.destroy(delete_items)
            end
            
            if !folder_grouping.map {|k,v| v}.flatten.empty?
                FolderCleanupMailer.notify(folder_grouping).deliver_now
            end

        end
      
    end

end