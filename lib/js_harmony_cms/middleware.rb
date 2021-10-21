require 'js_harmony_cms/middleware/clientjs_server'
require 'js_harmony_cms/middleware/router'

class JsHarmonyCms
  # Namespace module for CMS Rack middleware
  #
  # requiring this module will require all submodules.
  #
  # In additon to the supplied middleware, some static file serving may be required if not supplied by CDN etc.
  # @example Rails static file middleware
  #  config.middleware.insert_after ActionDispatch::Static, ActionDispatch::Static,
  #     config.x.jsHarmonyCMS.content_path
  module Middleware
  end
end