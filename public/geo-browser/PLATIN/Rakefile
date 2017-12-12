# Rakefile - create single combined nd compressed javascript file

COMPRESS="java -jar lib/yuicompressor-2.4.2.jar"
COMPRESSED_OUTPUT_FILE='platin-min.js'
OUTPUT_FILE='platin.js'
CSS_FILE='css/platin.css'

task :default => :all

task :all => [COMPRESSED_OUTPUT_FILE, OUTPUT_FILE, CSS_FILE, :copyJqueryUIImageDirectory]

# javascript sources
Files = %w(js/Build/Minifier/basic.js
lib/excanvas/excanvas.js
lib/slider/js/range.js
lib/slider/js/slider.js
lib/slider/js/timer.js
lib/openlayers/OpenLayers.js
lib/jquery/jquery-deparam.min.js
lib/jquery/jquery.remember.js
lib/jquery/purl.min.js
lib/jquery-ui/jquery-ui-1.10.3.custom.js
lib/jszip/jszip.min.js
lib/sheetjs/shim.js
lib/sheetjs/xls.min.js
lib/sheetjs/xlsx.js
lib/momentjs/moment.js
lib/ucsv/ucsv-1.1.0-min.js
lib/flot/jquery.flot.js
lib/flot/jquery.flot.pie.js
lib/flot/jquery.flot.resize.js
lib/flot/jquery.flot.selection.js
lib/flot/jquery.flot.time.js
lib/flot/jquery.flot.tooltip.js
lib/SimileRemnants.js
js/Util/Tooltips.js
js/GeoTemConfig.js
js/Map/MapControl.js
js/Map/CircleObject.js
js/Util/FilterBar.js
js/Util/Selection.js
js/Map/PlacenameTags.js
js/Map/MapConfig.js
js/Map/MapGui.js
js/Map/MapWidget.js
js/Time/TimeConfig.js
js/Time/TimeGui.js
js/Time/TimeWidget.js
js/Table/TableConfig.js
js/Table/TableGui.js
js/Table/TableWidget.js
js/Table/Table.js
js/Dataloader/Dataloader.js
js/Dataloader/DataloaderConfig.js
js/Dataloader/DataloaderGui.js
js/Dataloader/DataloaderWidget.js
js/FuzzyTimeline/FuzzyTimelineConfig.js
js/FuzzyTimeline/FuzzyTimelineDensity.js
js/FuzzyTimeline/FuzzyTimelineGui.js
js/FuzzyTimeline/FuzzyTimelineRangeBars.js
js/FuzzyTimeline/FuzzyTimelineRangePiechart.js
js/FuzzyTimeline/FuzzyTimelineRangeSlider.js
js/FuzzyTimeline/FuzzyTimelineWidget.js
js/Overlayloader/Overlayloader.js
js/Overlayloader/OverlayloaderConfig.js
js/Overlayloader/OverlayloaderGui.js
js/Overlayloader/OverlayloaderWidget.js
js/PieChart/PieChart.js
js/PieChart/PieChartCategoryChooser.js
js/PieChart/PieChartConfig.js
js/PieChart/PieChartGui.js
js/PieChart/PieChartHashFunctions.js
js/PieChart/PieChartWidget.js
js/Storytelling/Storytelling.js
js/Storytelling/StorytellingConfig.js
js/Storytelling/StorytellingGui.js
js/Storytelling/StorytellingWidget.js
js/LineOverlay/LineOverlay.js
js/LineOverlay/LineOverlayConfig.js
js/LineOverlay/LineOverlayWidget.js
js/Util/DataObject.js
js/Util/Dataset.js
js/Time/TimeDataSource.js
js/Map/Binning.js
js/Map/MapDataSource.js
js/Map/Clustering.js
js/Util/Dropdown.js
js/Map/MapZoomSlider.js
js/Map/MapPopup.js
js/Map/PlacenamePopup.js
js/Util/Publisher.js
js/Util/WidgetWrapper.js
js/Build/Minifier/final.js)

# css sources
Cssfiles = %w(lib/openlayers/theme/default/style.css
lib/jquery-ui/jquery-ui-1.10.3.custom.css
css/style.css)

def cat_files(outputfile, basename)
  File.open(outputfile, 'a') do |x|
    Files.each do |f|
      x.puts(File.open(f).read.gsub('REPLACEME-REPLACEME', basename))
    end
  end
end

file CSS_FILE => Cssfiles do
  File.open(CSS_FILE, 'w') do |x|
    Cssfiles.each do |f|
      x.puts(File.open(f).read)
    end
  end
end

# Just one big JS file, no compression.
file OUTPUT_FILE => Files do
  basename = File.basename(OUTPUT_FILE, ".js")
  
  File.open(OUTPUT_FILE, 'w') do |x|
    x.puts("(function($){\n\nvar jQuery = $;");
  end
  
  cat_files(OUTPUT_FILE, basename)

  File.open(OUTPUT_FILE, 'a') do |x|
    x.puts("})(jQuery);");
  end
end

task :copyJqueryUIImageDirectory do
	@source = "./lib/jquery-ui/images"
	@target = "./css/images"
	@includePattern = "/**/*"
    FileUtils.rm_rf(@target)  #remove target directory (if exists)  
    FileUtils.mkdir_p(@target) #create the target directory  
    files = FileList.new().include("#{@source}#{@includePattern}");   
    files.each do |file|          
        #create target location file string (replace source with target in path)  
        targetLocation = file.sub(@source, @target)       
        #ensure directory exists  
        FileUtils.mkdir_p(File.dirname(targetLocation));  
        #copy the file  
        FileUtils.cp_r(file, targetLocation)  
    end   
end

# Compress it.
file COMPRESSED_OUTPUT_FILE => Files do
  basename = File.basename(COMPRESSED_OUTPUT_FILE, ".js")
  
  File.open(OUTPUT_FILE, 'w') do |x|
    x.puts("(function($){\n\nvar jQuery = $;");
  end
  
  cat_files(OUTPUT_FILE, basename)

  File.open(OUTPUT_FILE, 'a') do |x|
    x.puts("})(jQuery);");
  end
  
  system "#{COMPRESS} #{OUTPUT_FILE} >> #{COMPRESSED_OUTPUT_FILE}"
end

# Clean up the whole thing.
task :clean do
  rm OUTPUT_FILE
  rm COMPRESSED_OUTPUT_FILE
  rm CSS_FILE
end
