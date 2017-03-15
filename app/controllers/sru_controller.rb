#class SruController < ApplicationController  
class SruController < ActionController::Base  

  def service
    respond_to do |format|
      format.html do
        if params['recordSchema'] == 'html'
          render 'response.xml.erb', layout: false
        else
          render 'response.xml.erb', layout: false, :content_type => "application/xml"
        end
      end
    end
  end

end

