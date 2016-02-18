# -*- encoding : utf-8 -*-
#
class DoItem < ApplicationController  
  
  def create
    @do_item = DoItem.create( do_item_params )
  end

  private

  # Use strong_parameters for attribute whitelisting
  # Be sure to update your create() and update() controller methods.

  def do_item_params
    params.require(:do_item).permit(:image)
  end

end 
