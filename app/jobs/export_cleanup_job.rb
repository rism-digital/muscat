class ExportCleanupJob < ApplicationJob
queue_as :default

    EXPORT_PATH = Rails.public_path.join('export')

    def perform(*args)
        puts "Cleaning up directory #{EXPORT_PATH}"
        # Delete everything in this directory older than a week
        filenames = Dir.entries(EXPORT_PATH)
        
        filenames.each do |filename|
            next if !filename.start_with?("export")
            file = File::Stat.new(EXPORT_PATH.join(filename))
            if (Time.now - file.ctime > 7.days)
                puts "Removing file #{filename}, created: #{file.ctime}"
                File.unlink(EXPORT_PATH.join(filename))
            end
        end

    end

end
