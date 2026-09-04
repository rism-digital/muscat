class SruController < ActionController::Base
  EXPORT_MAXIMUM_RECORDS = 2_000
  EXPORT_ACTIONS = %w[csv download].freeze
  MODEL_ALIASES = {
    "sources" => "sources",
    "people" => "people",
    "institutions" => "institutions",
    "publications" => "publications",
    "catalogues" => "publications",
    "works" => "works"
  }.freeze

  def service
    model_name = params[:sru_model].presence || "sources"
    @model = MODEL_ALIASES[model_name.to_s]
    return head :not_found unless @model

    request_params = request.query_parameters.deep_stringify_keys
    export_action = request_params.delete("x-action")
    return head :bad_request if export_action.present? && !EXPORT_ACTIONS.include?(export_action)
    return head :bad_request if export_action.present? && request_params["recordSchema"] != "html"

    maximum_records_limit = export_action ? EXPORT_MAXIMUM_RECORDS : nil
    request_params["maximumRecords"] = EXPORT_MAXIMUM_RECORDS if export_action

    @sru = Sru::Query.new(
      @model,
      request_params,
      maximum_records_limit: maximum_records_limit
    )
    @result = @sru.result

    if export_action && !@sru.error_code
      export_action == "csv" ? send_csv : send_xml
    else
      render_response
    end
  end

  private

  def send_csv
    csv = CSV.generate do |output|
      output << ["RISM-ID", "TITLE", "DATE", "SIGLUM", "SHELFMARK"]
      @result.hits.each do |hit|
        record = hit.result
        output << [record.id, record.name, record.try(:date_from), record.try(:lib_siglum), record.try(:shelf_mark)].map do |value|
          sanitize_csv_cell(value)
        end
      end
    end

    send_data csv,
      filename: "rism_sru_result.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  def send_xml
    xml = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |document|
      document["zs"].searchRetrieveResponse(
        "xmlns:zs" => "http://www.loc.gov/zing/srw/",
        "xmlns:marc" => "http://www.loc.gov/MARC21/slim"
      ) do
        document["zs"].version "1.1"
        document["zs"].numberOfRecords @result.total
        document["zs"].records do
          @result.hits.each_with_index do |hit, index|
            document["zs"].record do
              document["zs"].recordPacking "xml"
              document["zs"].recordData do
                document << marc_xml_for(hit.result) if hit.result
              end
              document["zs"].recordPosition index + 1
            end
          end
        end
        document["zs"].echoedSearchRetrieveRequest do
          document["zs"].version "1.1"
          document["zs"].query @sru.query
          document["zs"].maximumRecords @sru.maximumRecords
          document["zs"].recordPacking "xml"
        end
      end
    end

    send_data xml.to_xml,
      filename: "rism_sru_result.xml",
      type: "application/xml; charset=utf-8",
      disposition: "attachment"
  end

  def marc_xml_for(record)
    record.marc.to_xml(
      created_at: record.created_at,
      updated_at: record.updated_at,
      holdings: true,
      ns_name: "marc"
    )
  end

  def sanitize_csv_cell(value)
    string = value.to_s
    string.match?(/\A[=+\-@\t\r]/) ? "'#{string}" : string
  end

  def render_response
    if @sru.error_code
      render template: "sru/response", layout: false, formats: [:xml], content_type: "application/xml"
    elsif @sru.schema == "html"
      render template: "sru/response", layout: false, formats: [:html]
    else
      render template: "sru/response", layout: false, formats: [:xml], content_type: "application/xml"
    end
  end
end
