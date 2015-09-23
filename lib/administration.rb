# This helper class provides some methods to make muscat admin life easier.

class Administration
  require 'gruff'
  # Render image of statistic in year
  # TODO Binding to real data
  def self.build_statistic
    #=Source.where('updated_at > ?', 5.days.ago).select("date(created_at) as created, id")
    #return s
    g = Gruff::Bar.new('600x350')
    g.title = 'Last Year'
    g.title_font_size = 18
    g.legend_font_size = 12
    g.marker_font_size = 12
    g.spacing_factor = 0.6
    g.labels = {
      0 => '1',
      1 => '2',
      2 => '3',
      3 => '4',
      4 => '5',
      5 => '6',
      6 => '7',
      7 => '8',
      8 => '9',
      9 => '10',
      10 => '11',
      11 => '12',
    }
    no=[50, 110, 52, 53, 61, 75, 116, 120, 110, 48, 44, 52]
    g.data('Sum of Records from 2014: '+(no.inject(:+)).to_s, no , '#12a702')
    #:colors => ['#aedaa9', '#12a702'],
    g.write('public/images/statistic.png')
  end

  # Alternative chart builder
  # TODO Real data
  def self.build_chart
    #=Source.where('updated_at > ?', 5.days.ago).select("date(created_at) as created, id")
    #return s
    g = Gruff::Bar.new('600x350')
    g.title = '2015'
    g.title_font_size = 18
    g.legend_font_size = 12
    g.marker_font_size = 12
    g.spacing_factor = 0.6
    g.labels = {
      0 => '1',
      1 => '2',
      2 => '3',
      3 => '4',
      4 => '5',
      5 => '6',
      6 => '7',
      7 => '8',
      8 => '9',
      9 => '10',
      10 => '11',
      11 => '12',
    }
    no=[150, 210, 1252, 353, 2261, 715, 1116, 1220, 1210, 438, 2244, 1252]
    g.data('Sum of Records from 2014: '+(no.inject(:+)).to_s, no , '#12a702')
    #:colors => ['#aedaa9', '#12a702'],
    g.write('public/images/chart.png')
  end
end
