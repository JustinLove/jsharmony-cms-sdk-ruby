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
  # Page object.
  # Provides convenient access and defaults to the properties defined in a JSON page data file.
  class Page
    # @param json [Hash] data loaded from a published CMS page JSON file with the Standalone template
    def initialize(json)
      @data = json || {}
      @seo = Seo.new(@data['seo'])
      @content = Content.new(@data['content'])
      @properties = Properties.new(@data['properties'])
    end

    # @return [Seo] SEO properties, eg page.seo.title
    attr_reader :seo

    # @return [Content] content sections, eg page.content.body
    attr_reader :content

    # @return [Properties] page specific properties, eg page.properties.homepageBodyClass
    attr_reader :properties

    # @return [String] custom css tag
    # @example Rails ERB Template
    #   <% if page.css.present? %><style type="text/css"><%= page.css.html_safe %></style><% end %>
    def css
      data['css'] || ''
    end

    # @return [String] custom script tag
    # @example Rails ERB Template
    #   <% if page.js.present? %><script type="text/javascript"><%= page.js.html_safe %></script><% end %>
    def js
      data['js'] || ''
    end

    # @return [String] custom code for the <head> tag
    # @example Rails ERB Template
    #   <%= page.header.html_safe %>
    def header
      data['header'] || ''
    end

    # @return [String] custom code for the page footer
    # @example Rails ERB Template
    #   <% content_for :footer do %>
    #     <%= page.footer.html_safe %>
    #   <% end %>
    def footer
      data['footer'] || ''
    end

    # @return [String] page title, eg h1 (see page.seo.title for the <head><title> value)
    # @example Rails ERB Template
    #   <h1 cms-title><%= page.title || 'Default Page Title' %></h1>
    def title
      data['title'] || ''
    end

    # Script tag to load the jsHarmonyCMS in-page editor. Always blank in the base Page class.
    # @example ERB template
    #   <%= page.editor_script.html_safe %>
    # @return [String] script tag text
    def editor_script
      ''
    end

    # Page instance in CMS edit mode. Provides no content, but does require/provide the clientside javascript tag to load in the in page editor.
    class EditorPage < Page
      # @param script [String] script tag to load the CMS in page editor
      def initialize(script = '')
        @editor_script = script
        super({})
      end

      # Script tag to load the jsHarmonyCMS in-page editor.
      # @return [String] script tag text
      def editor_script
        @editor_script
      end
    end

    private

    attr_reader :data

    # Standard SEO related properties.
    class Seo
      # @param json [Hash] seo subtree of the page JSON data object
      def initialize(json)
        @data = json || {}
      end

      # @return [String] <head><title> value
      # @example Rails ERB Template
      #  <% if page.seo.title.present? then content_for :title, page.seo.title end %>
      def title
        data['title'] || ''
      end

      # @return [String] <head><meta name="keywords"> value
      # @example Rails ERB Template
      #  <% if page.seo.keywords.present? %><meta name="keywords" content="<%= page.seo.keywords %>" /><% end %>
      def keywords
        data['keywords'] || ''
      end

      # @return [String] <head><meta name="description"> value
      # @example Rails ERB Template
      #  <% if page.seo.metadesc.present? %><meta name="description" content="<%= page.seo.metadesc %>" /><% end %>
      def metadesc
        data['metadesc'] || ''
      end

      # @return [String] <head><link rel="canonical"> value
      # @example Rails ERB Template
      #   <% if page.seo.canonical_url.present? %><link rel="canonical" href="<%= page.seo.canonical_url %>" /><% end %>
      def canonical_url
        data['canonical_url'] || ''
      end

      private

      attr_reader :data
    end

    # Provies normal member syntax for page specific content areas, eg page.content.body.
    #
    # Undefined areas will return empty string.
    # @example Rails ERB Template
    #   <div cms-content-editor="page.content.body" ><%= page.content.body.html_safe %></div>
    class Content
      # @param json [Hash] content subtree of the page JSON object
      def initialize(json)
        @data = json || {}
      end

      # Standard ruby meta method, specialized to reflect available content areas.
      def respond_to_missing?(key)
        data && data.member?(key.to_s) || super
      end

      # Standard ruby meta method, specialized to reflect available content areas.
      # @return [String] will return empty string for unknown properties
      def method_missing(key)
        data && data[key.to_s]&.to_s || ''
      end

      private

      attr_reader :data
    end

    # Provies normal member syntax for page specific properties, eg page.properties.containerClass.
    #
    # Undefined properties will return empty string.
    # @example Rails ERB Template
    #   <div
    #     cms-content-editor="page.content.body"
    #     cms-onRender="addClass(page.properties.containerClass); addStyle(page.properties.containerStyle);"
    #     class="<%= page.properties.containerClass.html_safe %>"
    #     style="<%= page.properties.containerStyle.html_safe %>"
    #   >
    #     <%= page.content.body.html_safe %>
    #   </div>
    class Properties < Content; end
  end
end