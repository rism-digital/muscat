module Statistic
  class User
    # Returns hash of person => {:month => size}
    def self.sources_by_month(from_date, to_date, users)
      result = ActiveSupport::OrderedHash.new
      time_range = ApplicationHelper.month_distance(from_date, to_date)
      users.each do |user|
        s = Sunspot.search(Source) do
          with(:created_at, from_date..to_date)
          with(:wf_owner, user.id)
          facet(:created_at, :zeros => true) do
            time_range.each do |distance|
              start_time = from_date.localtime - distance.month
              end_time = start_time + 1.month
              row start_time.strftime("%Y-%m") do
                with :created_at, start_time..end_time
              end
            end
          end
        end
        line = ActiveSupport::OrderedHash.new
        s.facet(:created_at).rows.reverse.each do |r|
          line[r.value] = r.count
        end   
        result[user] = line
      end
      return result
    end
  end
end
