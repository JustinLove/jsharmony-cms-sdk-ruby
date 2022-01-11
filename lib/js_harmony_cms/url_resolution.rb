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

class JsHarmonyCms
  # Methods of translating a url into candidate filesystem paths
  #
  # Any callable object (such as lambda) can be used instead for custom behavior.
  module UrlResolution
    # Strict resolution: try the given path and no others
    class Strict
      # @param path [String] Sanitized base path
      # @param unsanitized_path [String] Path before cleanup and adding content directory (notably includes trailing slash)
      # @return [Array<String>] Candidate filesystem paths
      def call(path, unsanitized_path)
        [path]
      end
    end

    # Try a default document (eg index.html) if the url ends with a trailing slash
    class DefaultDocument
      attr_reader :default_document

      # @param doc [String] Default filename eg index.html
      def initialize(doc)
        @default_document = doc
      end

      # @param path [String] Sanitized base path
      # @param unsanitized_path [String] Path before cleanup and adding content directory (notably includes trailing slash)
      # @return [Array<String>] Candidate filesystem paths
      def call(path, unsanitized_path)
        trailing_slash = unsanitized_path.end_with?('/') # Rack::Utils.clean_path_info
        if trailing_slash
          [File.join(path, default_document)]
        else
          url_ext = File.extname(path)
          default_ext = File.extname(default_document)
          if url_ext.empty? || default_ext.empty? || (url_ext != default_ext)
            [path, File.join(path, default_document)]
          else
            [path]
          end
        end
      end
    end

    # Strict resolution: try the given path and no others
    # @return [Strict]
    def self.strict; Strict.new; end

    # Try a default document (eg index.html) if the url ends with a trailing slash
    # @param doc [String] default filename
    # @return [DefaultDocument]
    def self.default_document(doc); DefaultDocument.new(doc); end
  end
end