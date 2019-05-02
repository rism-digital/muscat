module UrlHelper
  include Blacklight::UrlHelperBehavior

  def url_for_document(doc, options = {})
    return "" if !doc
    "/" + params[:controller] + "/" + doc.to_param
  end
end
