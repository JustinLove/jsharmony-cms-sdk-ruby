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

require 'js_harmony_cms/page'
require 'js_harmony_cms/url_resolution'

class JsHarmonyCms
  # Loads JSON/Standalone data from a local filesystem, and returns a wrapping {Page} object.
  class PageLoader
    # @return [String] File path to published CMS content files
    attr_reader :content_path

    # @return [UrlResolution,#call] callable object which returns a list of file paths to attempt loading
    attr_reader :url_resolution

    # @param _content_path [String] File path to published CMS content files
    # @param _url_resolution [UrlResolution,#call] callable object which returns a list of file paths to attempt loading
    def initialize(_content_path, _url_resolution = UrlResolution.default_document('index.html'))
      @content_path = _content_path
      @url_resolution = _url_resolution
    end

    # Attempt to load page data for the given url.
    # @param url [String|nil] CMS Page URL.
    #      * Use Full URL or Root-relative URL
    # @return [Page] page data, or an an empty page object if not found
    def call(url)
      resolve(url).each do |path|
        if should_try_to_load?(path)
          return Page.new(load_file(path))
        end
      end

      return Page.new({})
    end

    # Attempt to resolve a url to candidate filesystem paths
    # @param url [String|nil] CMS Page URL.
    # @return [Array<String>] List of candiate paths
    def resolve(url)
      self.class.resolve(content_path, url, url_resolution)
    end

    # Tests for file existance
    # @param path [String] Filesystem path
    # @return [Boolean]
    def should_try_to_load?(path)
      File.file?(path) && File.readable?(path)
    rescue SystemCallError
      false
    end

    # Attempt to load and parse the json data
    # @param path [String] Filesystem path
    # @return [Hash] Parsed JSON data
    def load_file(path)
      JSON.parse(File.read(path)) || {}
    end

    # Attempt to resolve a url to candidate filesystem paths
    # @param content_path [String] File path to published CMS content files
    # @param url [String|nil] CMS Page URL.
    # @param url_resolution [UrlResolution,#call] callable object which returns a list of file paths to attempt loading
    # @return [Array<String>] List of candiate paths
    def self.resolve(content_path, url, url_resolution = UrlResolution.default_document('index.html'))
      uri = URI(url)
      path = Rack::Utils.unescape_path(uri.path)
      trailing_slash = uri.path.end_with?('/') # removed by clean_path_info
      path = Rack::Utils.clean_path_info(path)
      path = File.join(content_path, path)
      url_resolution.call(path, trailing_slash)
    end
  end
end