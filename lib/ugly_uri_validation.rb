# frozen_string_literal: true

# Requires:
#   gem "execjs"
#
# Usage:
#   require "ugly_uri_validation"
#   class MyThing
#     include UglyUriValidation
#     def ok?(val) = parse_http_url_with_js(val)["ok"]
#   end

# Validate the URLS exacly as in the JS validation

require "execjs"

module UglyUriValidation
  JS_SOURCE = <<~'JS'
    function parseHttpUrl(value) {
      try {
        const u = new URL(String(value));
        return u.protocol === "http:" || u.protocol === "https:";
      } catch {
        return false;
      }
    }
  JS

  def parse_http_url_with_js?(val)
    self.class.__execjs_http_url_ctx.call("parseHttpUrl", val)
  end

  module ClassMethods
    def __execjs_http_url_ctx
      @__execjs_http_url_ctx ||= ExecJS.compile(JS_SOURCE)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
