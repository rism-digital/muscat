module UrlHelper
  include Blacklight::UrlHelperBehavior

  def url_for_document(doc, options = {})
    #'/special/path'
    "/" + params[:controller] + "/" + doc.to_param
  end
end
