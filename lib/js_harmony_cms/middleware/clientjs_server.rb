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

class JsHarmonyCms
  module Middleware
    # Rack middleware which directly serves the CMS in-page editor javascript file for remote template integrations.
    # @example Rails middleware stack
    #   config.middleware.insert_before ActionDispatch::Static, JsHarmonyCms::Middleware::ClientjsServer,
    #     config.x.jsHarmonyCMS.cms_clientjs_editor_launcher_path
    class ClientjsServer
      # @param app [#call] Rack app
      # @param clientjs_url [String] virtual url which the middleware should respond to
      def initialize(app, clientjs_url)
        @app = app
        @clientjs_url = clientjs_url
      end

      # Process the request.
      # @param env [Hash] Rack environment
      # @return [Array(Integer,Hash,Array<String>)] Rack response
      def call(env)
        path = Rack::Request.new(env).path
        return [200, {'Content-Type' => 'application/javascript'}, [load_file]] if path == @clientjs_url

        @app.call(env)
      end

      # Attempt to load the file from within the gem
      # @return [String] Script source text
      def load_file
        File.read(File.dirname(__FILE__)+'/../../../clientjs/jsHarmonyCmsEditor.min.js')
      rescue => error
        report_error error
        return ""
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