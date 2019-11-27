class ApiController < ActionController::API
  def show
    model, id = params[:model], params[:id]
    record = model.constantize.find(id)
    marc = record.marc.to_json
    if record.wf_stage == 0 
      render json: {status: "Access denied"} 
    else
      render json: { model: model, marc: marc, id: id, record_type: record.record_type, record_status: record.wf_stage, record_owner: record.wf_owner }
    end
  end
end
