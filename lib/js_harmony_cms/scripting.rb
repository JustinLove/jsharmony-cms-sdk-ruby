=begin
Copyright 2021 apHarmony

This file is part of jsHarmony.

jsHarmony is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

jsHarmony is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this package.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'erb'

class JsHarmonyCms
  # Provides functions to generate HTML Strings for loading the CMS in-page editor scripts.
  # @example Rails helper
  #   require 'js_harmony_cms/scripting'
  #   
  #   module CmsTemplatesHelper
  #     def cms_integration_tag
  #       JsHarmonyCms::Scripting.remote_template_integration(
  #         Rails.configuration.x.jsHarmonyCMS.cms_clientjs_editor_launcher_path,
  #         Rails.configuration.x.jsHarmonyCMS.access_key
  #       ).html_safe
  #     end
  #   end
  module Scripting
    # Script tag for remote template integrations
    # @param cms_clientjs_editor_launcher_path [String] Path where router will serve the client-side JS script that launches CMS Editor
    # @param access_key [String] CMS accesss key
    #  * Access key serves a similar role to {JsHarmonyCms#cms_server_urls}
    # @return [String] HTML String
    def self.remote_template_integration(cms_clientjs_editor_launcher_path, access_key)
      %Q(<script type="text/javascript" class="removeOnPublish" src="#{cms_clientjs_editor_launcher_path}"></script>
      <script type="text/javascript" class="removeOnPublish">
      jsHarmonyCmsEditor({"access_keys":["#{access_key}"]});
      </script>)
    end

    # Script tag for JSON/Standalone integrations.
    #
    # Normally accessed indirectly via page object, see {JsHarmonyCms#get_page} and {Page#editor_script}
    # @param cms_server_url [String] CMS url; eg the jshcms_url query parameter
    # @return [String] HTML String
    def self.editor_script(cms_server_url)
      %Q(<script type="text/javascript" src="#{ERB::Util.html_escape(cms_server_url + 'js/jsHarmonyCMS.js')}"></script>)
    end
  end
end