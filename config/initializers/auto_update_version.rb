module AutoUpdateVersion
    begin
        LATEST = File.read("#{Rails.root}/tmp/muscat_update.txt")
    rescue Errno::ENOENT
        LATEST = nil
    end
end