#class SruController < ApplicationController  
class SruController < ActionController::Base  

  def service
    respond_to do |format|
      format.html do
        if params['recordSchema'] == 'html'
          if params['x-action'] == 'csv'
            filename = "#{Rails.root}/tmp/sru.csv"
            model = request.env["PATH_INFO"].split("/").last
            model = "sources" if (model == 'sru' || model == 'muscat')
            sru   = Sru::Query.new(model, params.merge(:maximumRecords => 2000)) 
            result   = sru.result
            res = [["RISM-ID", "TITLE", "DATE", "SIGLUM", "SHELFMARK"]]
            result.hits.each_with_index do |hit, idx|
              r = hit.result
              res << [r.id, r.name, r.date_from, r.lib_siglum, r.shelf_mark]
            end
            CSV.open(filename, "w") do |csv|
              res.each do |e|
                csv << e
              end
            end
            send_data File.open(filename).read, filename: "rism_sru_result.csv"
          elsif params['x-action'] == 'download'
            filename = "#{Rails.root}/tmp/sru.xml"
            model = request.env["PATH_INFO"].split("/").last
            model = "sources" if (model == 'sru' || model == 'muscat')
            sru   = Sru::Query.new(model, params.merge(:maximumRecords => 2000)) 
            result   = sru.result
            res = ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>
              <zs:searchRetrieveResponse xmlns:zs=\"http://www.loc.gov/zing/srw/\" xmlns:marc=\"http://www.loc.gov/MARC21/slim\" >
              <zs:version>1.1</zs:version>
              <zs:numberOfRecords>#{result.total}</zs:numberOfRecords>
              <zs:records>"]
            result.hits.each_with_index do |hit, idx|
              res << "<zs:recordPacking>xml</zs:recordPacking>
                <zs:recordData>
              #{Nokogiri::HTML.fragment(hit.result.marc.to_xml_record(hit.result.updated_at, nil, true).html_safe).to_s}
                </zs:recordData>
                <zs:recordPosition>#{idx + 1}</zs:recordPosition>
                </zs:record>"
            end
            res << "</zs:records>
              <zs:echoedSearchRetrieveRequest>
              <zs:version>1.1</zs:version>
              <zs:query>#{params["query"]}></zs:query>
              <zs:maximumRecords>2000</zs:maximumRecords>
              <zs:recordPacking>xml</zs:recordPacking>
              </zs:echoedSearchRetrieveRequest>
              </zs:searchRetrieveResponse>"
            IO.write(filename, res.join("\n"))
            send_data File.open(filename).read, filename: "rism_sru_result.xml"
          else
            render 'response.xml.erb', layout: false
          end
        else
          render 'response.xml.erb', layout: false, :content_type => "application/xml"
        end
      end
    end
  end

end

