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

require "js_harmony_cms/version"
require 'js_harmony_cms/scripting'
require 'js_harmony_cms/page'
require 'js_harmony_cms/page_loader'

# Top level configuration holder providing convenience methods for most common use cases, as well as allowed cms server url checking.
# @example Rails configuration
#   config.x.jsHarmonyCMS.access_key = "....."
#   config.x.jsHarmonyCMS.content_path = 'public/cms'
#   config.x.jsHarmonyCMS.cms_server_urls = ['https://exmaple.com:8081/']
#   config.x.jsHarmonyCMS.cms_clientjs_editor_launcher_path = '/.jsHarmonyCms/jsHarmonyCmsEditor.js'
#
# @example Rails controller method
#   def cms
#     @cms ||= JsHarmonyCms.new(Rails.configuration.x.jsHarmonyCMS)
#   end
class JsHarmonyCms
  attr_reader :config

  # @see #initialize
  DefaultConfig = {
    :content_path => '.',
    :page_loader => nil,
    :cms_clientjs_editor_launcher_path => '/.jsHarmonyCms/jsHarmonyCmsEditor.js',
    :cms_server_urls => [],
  }

  # @param config [Hash] properties to override {DefaultConfig}
  # @option config [String] :content_path ('.') File path to published CMS content files
  # @option config [PageLoader] :page_loader Object which finds and reads JSON page objects; default instance will be provided if blank
  # @option config [String] :cms_clientjs_editor_launcher_path ('/.jsHarmonyCms/jsHarmonyCmsEditor.js') Path where router will serve the client-side JS script that launches CMS Editor
  # @option config [Array<String>] :cms_server_urls ([]) The CMS Server URLs that will be enabled for Page Editing (set to '*' to enable any remote CMS)
  #  * Used by {Page#editor_script}, and the {#get_editor_script} function
  #  * NOT used by jsHarmonyCmsEditor.js - the launcher instead uses access_keys for validating the remote CMS
  def initialize(config = {})
    @config = DefaultConfig.merge config
  end

  # @return [String] File path to published CMS content files
  def content_path
    config[:content_path]
  end

  # @return [PageLoader] Object which finds and reads JSON page objects
  def page_loader
    @page_loader ||= config[:page_loader] || PageLoader.new(content_path)
  end

  # @return [String] Path where router will serve the client-side JS script that launches CMS Editor
  def cms_clientjs_editor_launcher_path
    config[:cms_clientjs_editor_launcher_path]
  end

  # @return [Array<String>] The CMS Server URLs that will be enabled for Page Editing
  def cms_server_urls
    config[:cms_server_urls]
  end

  # Check whether page is currently in CMS Editing Mode
  # @param req [Rack::Request] Request to pull url parameters from
  # @return [Boolean] True if page is opened from CMS Editor
  def is_in_editor?(req)
    params = (req && req.params) || {}
    !!params['jshcms_token']
  end

  # Generate script for CMS Editor.
  #
  # * If the page was not launched from the CMS Editor, an empty string will be returned.
  # * The querystring jshcms_url parameter is validated against {#cms_server_urls}.
  # * If the CMS Server is not found in {#cms_server_urls}, an empty string will be returned.
  # @param req [Rack::Request] Request to pull query parameters from
  # @return [String] HTML Code to launch the CMS Editor
  def get_editor_script(req)
    params = (req && req.params) || {}
    cms_server_url = params['jshcms_url']

    if is_in_editor?(req) && url_allowed?(cms_server_url)
      Scripting.editor_script(cms_server_url)
    else
      ''
    end
  end

  # Get CMS Page Data for JSON/Standalone Integration
  #
  # @param url [String|nil] CMS Page URL.
  #      * Use Full URL or Root-relative URL
  # @param req [Rack::Request] Request to pull query parameters from
  # @return [Page, Page::EditorPage] Page Content
  #
  # @example
  #   @page = cms.get_page("/homepage/index.html", request)
  def get_page(url, req)
    if is_in_editor?(req)
      Page::EditorPage.new(get_editor_script(req))
    else
      load_display_page(url)
    end
  end

  # Get CMS Page Data without regard for editor state; use {#get_page} instead
  # @param url [String|nil] CMS Page URL.
  #      * Use Full URL or Root-relative URL
  # @return [Page] Page Content
  def load_display_page(url)
    page_loader.call(url)
  end

  # Checks whether the url is in the list of {#cms_server_urls}
  # @param cms_server_url [String|nil] CMS Page URL.
  #      * Use Full URL or Root-relative URL
  # @return [Boolean]
  def url_allowed?(cms_server_url)
    self.class.url_allowed?(cms_server_url, cms_server_urls)
  end

  # Checks whether the url is in the list of urls
  # @param cms_server_url [String|nil] CMS Page URL.
  #      * Use Full URL or Root-relative URL
  # @param cms_server_urls [Array<String>] allowed urls
  # @return [Boolean]
  def self.url_allowed?(cms_server_url, cms_server_urls)
    cur_uri = URI(cms_server_url)
    return false unless cur_uri
    cms_server_urls.map do |rule_url|
      next unless rule_url && rule_url != ''
      return true if rule_url == '*'
      rule_uri = URI(rule_url)
      next unless rule_uri
      if rule_uri.scheme
        next unless same_string?(cur_uri.scheme, rule_uri.scheme)
      end
      next unless same_string?(cur_uri.host, rule_uri.host)
      next unless same_string?(cur_uri.port, rule_uri.port)
      return true if same_path?(cur_uri, rule_uri)
    end
    return false
  end

  private

  def self.same_string?(a, b)
    a.to_s.casecmp?(b.to_s)
  end

  def self.same_path?(a, b)
    pathA = a.path.empty? ? '/' : a.path
    pathB = b.path.empty? ? '/' : b.path
    pathA.start_with?(pathB)
  end

  def report_error(error)
    if Object.const_defined?('Rails') && Rails.method_defined?('env')
      if Rails.env.test?
        p error
      else
        Rails.logger.error error
      end
    else
      p error
    end
  end
end