module Statistics
  class Workgroup
    # sources_workgroups are not indexed ar the moment
    def self.sources_by_month(from_date, to_date, workgroups)
      res = ActiveSupport::OrderedHash.new
      workgroups.each do |wg|
        #FIXME from_date etc are as UTC!
        s = Statistics::User.sources_by_month(from_date.localtime, to_date.localtime, wg.users)
        line = ActiveSupport::OrderedHash.new(0)
        s.values.each do |value|
          value.each do |k,v|
            if k=="2017-04"
            end
            line[k] += v
          end
          res[wg] = line
        end
      end
      return res
    end
  end
end
