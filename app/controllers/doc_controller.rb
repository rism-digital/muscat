class DocController < ApplicationController

  def index
    @model_name = "source"
    @model = Source.new
  end

end