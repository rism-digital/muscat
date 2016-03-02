class DigitalObjectController < ApplicationController  

  private

  def digital_object_params
    params.require(:digital_object).permit(:attachment, :description)
  end

end 
