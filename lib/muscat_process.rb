module MuscatProcess
    def exist?(pid)
        Process.kill(0, pid)
        true
    rescue Errno::ESRCH
        false
    rescue Errno::EPERM #Operation not permitted, it is running
        true
    end

    def get_reindex_pid
        begin
            File.read(REINDEX_PIDFILE).to_i
        rescue Errno::ENOENT
            nil
        end
    end

    def is_reindexing?
        pid = get_reindex_pid
        return false if !pid

        exist?(pid)
    end

    module_function :exist?
    module_function :get_reindex_pid
    module_function :is_reindexing?
end
