module Statistics
  class Source
    def self.sources_per_wf_stage(from_date, to_date)
      result = ActiveSupport::OrderedHash.new
      time_range = ApplicationHelper.month_distance(from_date, to_date)
      s = Sunspot.search(::Source) do
        with(:created_at, from_date..to_date)
        facet(:wf_stage, :zeros => true) do
          time_range.each do |distance|
            start_time = Time.now.beginning_of_month + distance.month
            row "PUB@" + start_time.localtime.strftime("%Y-%m") do
              with :created_at, start_time..start_time.end_of_month
              with :wf_stage, "published"
            end
            row "UNP@" + start_time.localtime.strftime("%Y-%m") do
              with :created_at, start_time..start_time.end_of_month
              with :wf_stage, "inprogress"
            end
          end
        end
      end
      s.facet(:wf_stage).rows.each do |r|
        status, date = r.value.split("@")
        if result[date]
          result[date].merge!({status => r.count})
        else
          result[date] = {status => r.count}
        end
      end
      return result
    end

    
  end
end
