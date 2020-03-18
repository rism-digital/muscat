module AutoUpdateVersion
    LATEST = `cat #{Rails.root}/tmp/muscat_update.txt`
end