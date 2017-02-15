class SruController < ApplicationController  

  def version
    respond_to do |format|
      format.html do 
        render 'version.xml.erb', layout: false, :content_type => "application/xml"
      end
    end
  end

  def index
    puts params
    respond_to do |format|
      format.html do 
        render 'response.xml.erb', layout: false, :content_type => "application/xml"
      end
    end
  end


end

