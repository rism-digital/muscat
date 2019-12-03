class RecordController < ActionController::API
  
  before_action :authenticate_user!
  def show
    puts current_user.email
    model, id = params[:model], params[:id]
    record = Record.new(model, id)
    if record.record_status == "inprogress"
      render json: {"status": "Access denied", model: model, id: id}
    else
      render json: record
    end
  end

  def update
    model, id = params[:model], params[:id]
    marc = params[:marc]
    record = Record.new(model, id)
    record.update(marc)
    render json: {"status": "Sucess"}
  end

  def search
    records = Record.search(params[:model], params)
    render json: records
  end
end
