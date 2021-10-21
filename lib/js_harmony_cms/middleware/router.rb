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

require 'rack/request'
require 'rack/mime'
require 'json'

class JsHarmonyCms
  module Middleware
    # Rack middleware to handle jsHarmonyCMS redirects.
    # @example Rails middleware stack
    #   config.middleware.insert_before ActionDispatch::Static, JsHarmonyCms::Middleware::Router,
    #     config.x.jsHarmonyCMS.content_path+'/jshcms_redirects.json'
    class Router
      # @param app [#call] Rack app
      # @param redirect_file_path [String] file path of published redirect data file
      def initialize(app, redirect_file_path)
        @app = app
        @redirect_file_path = redirect_file_path
      end

      # Process the request.
      # @param env [Hash] Rack environment
      # @return [Array(Integer,Hash,Array<String>)] Rack response
      def call(env)
        path = Rack::Request.new(env).path
        load_redirects.each do |redir|
          return exec(path, redir, env) if match?(path, redir)
        end

        @app.call(env)
      end

      # Attempt to load the redirect data file.
      # @return [Array<Hash>] list of redirect rules
      def load_redirects
        JSON.parse(File.read(@redirect_file_path))
      rescue => error
        report_error error
        return []
      end

      # Test if the url matches the given redirect rule.
      # @param path [String] url being processed
      # @param redir [Hash] Redirect rule
      # @return [Boolean]
      def match?(path, redir)
        case redir['redirect_url_type']
        when 'EXACT'
          path == redir['redirect_url']
        when 'EXACTICASE'
          path.downcase == redir['redirect_url'].downcase
        when 'BEGINS'
          path.start_with? redir['redirect_url']
        when 'BEGINSICASE'
          path.downcase.start_with? redir['redirect_url'].downcase
        when 'REGEX'
          path.match? Regexp.new(redir['redirect_url'])
        when 'REGEXICASE'
          path.match? Regexp.new(redir['redirect_url'], true)
        else
          false
        end
      end

      # Execute the redirect rule. The rule is assumed to be matching.
      # @param path [String] url being processed
      # @param redir [Hash] Redirect rule
      # @param env [Hash] Rack environment
      # @return [Array(Integer,Hash,Array<String>)] Rack response
      def exec(path, redir, env)
        case redir['redirect_http_code']
        when '301'
          redirect 301, dest_path(path, redir)
        when '302'
          redirect 302, dest_path(path, redir)
        when 'PASSTHRU'
          passthru env, dest_path(path, redir)
        else
          report_error 'redirect code unknown'
          @app.call(env)
        end
      end

      # Destination path for redirects.
      # @param path [String] url being processed
      # @param redir [Hash] Redirect rule
      # @return [String] Destination path
      def dest_path(path, redir)
        case redir['redirect_url_type']
        when 'REGEX'
          path.sub Regexp.new(redir['redirect_url']), redir['redirect_dest']
        when 'REGEXICASE'
          path.sub Regexp.new(redir['redirect_url'], true), redir['redirect_dest']
        else
          redir['redirect_dest']
        end
      end

      # Returns a rack response for a redirect response.
      # @param code [Integer] status code
      # @param url [String] url to redirect to
      # @return [Array(Integer,Hash,Array<String>)] Rack response
      def redirect(code, url)
        [code.to_i, {'Location' => url, 'Content-Type' => Rack::Mime.mime_type(::File.extname(url))}, [""]]
      end

      # Continue with standard routing.
      #
      # (Extended implementations could perhaps check for fully qualified urls and load a remote file.)
      # @param env [Hash] Rack environment
      # @param url [String] url to redirect to
      # @return [Array(Integer,Hash,Array<String>)] Rack response
      def passthru(env, url)
        uri = URI(url)
        @app.call(env.merge({'PATH_INFO' => uri.path, 'QUERY_STRING' => uri.query}))
      end

      private

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
  end
end