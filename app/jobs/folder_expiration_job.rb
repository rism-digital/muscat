
class FolderExpirationJob < ApplicationJob

    def initialize()
        super
    end

    def perform()
        
        User.all.each do |user|
            delete_now = []

            user.folders.each do |folder|
                #puts "Folder: #{folder.id} expires in #{folder.delete_date.to_date - Date.today}"

                if folder.delete_date.to_date - Date.today <= 0/1
                    #puts "#{user.name} #{folder.id} #{folder.delete_date} delete NOW!"
                    delete_now << folder.id
                elsif folder.delete_date.to_date - Date.today == 1/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete tomorroy!"

                elsif folder.delete_date.to_date - Date.today == 7/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete in one week"
                elsif folder.delete_date.to_date - Date.today == 14/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete in two weeks"
                elsif folder.delete_date.to_date - Date.today == 30/1
                    puts "#{user.name} #{folder.id} #{folder.delete_date} delete in one month"
                end
            end

            if !delete_now.empty?
                puts "Deleting folders #{delete_now.to_s}"
                Folder.destroy(delete_now)
            end

        end
      
    end

end